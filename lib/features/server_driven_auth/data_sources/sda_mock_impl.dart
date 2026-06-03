import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/debug_flags.dart';
import 'package:escola/features/server_driven_auth/data_sources/server_driven_auth_repository.dart';
import 'package:escola/features/server_driven_auth/models/auth_action.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';
import 'package:escola/features/server_driven_auth/models/check_identifier_request.dart';
import 'package:escola/features/server_driven_auth/models/forgot_password_request.dart';
import 'package:escola/features/server_driven_auth/models/otp_verify_request.dart';
import 'package:escola/features/server_driven_auth/models/sda_login_request.dart';
import 'package:escola/features/server_driven_auth/models/self_register_request.dart';
import 'package:escola/features/server_driven_auth/models/set_password_request.dart';
import 'package:flutter/foundation.dart';

/// Local-only mock for the server-driven-auth backend so the 9 screens can
/// be exercised end-to-end without the Laravel + Botble backend (which lives
/// in a separate repo and isn't live yet). Wired in by
/// `ServerDrivenAuthInjection` when [DebugFlags.kSdaDevTest] is `true`.
///
/// **Test phone numbers** (always with country code `+55`):
///
/// | Phone        | check-identifier returns          | Try this to land on… |
/// |--------------|-----------------------------------|----------------------|
/// | 11111110001  | CREATE_NEW_PASSWORD               | SetInitialPasswordScreen |
/// | 11111110002  | REQUIRE_PASSWORD                  | inline password reveal (password = `Senha123`) |
/// | 11111110003  | VERIFY_EMAIL_OTP                  | EmailOtpScreen |
/// | 11111110004  | GO_TO_PENDING_APPROVAL            | PendingApprovalScreen |
/// | 11111110005  | ACCOUNT_SUSPENDED                 | inline suspended error |
/// | anything else| NOT_FOUND                         | inline "create one?" prompt |
///
/// **Test OTPs**: `123456` is always valid (registration OR reset). Any other
/// 6-digit string returns `OTP_INVALID`.
///
/// **Test password** on phone `11111110002`: `Senha123`. Anything else returns
/// `INVALID_CREDENTIALS`.
///
/// **Self-register / forgot-password**: any input succeeds (returns
/// `VERIFY_EMAIL_OTP` / `VERIFY_RESET_OTP`).
class SdaMockImpl extends ServerDrivenAuthRepository {
  static const Duration _fakeLatency = Duration(milliseconds: 350);

  // Test phone → action mapping. Centralized so tests + the comment table
  // above stay in sync.
  static const String phoneCreate = '11111110001';
  static const String phoneRequirePw = '11111110002';
  static const String phoneVerifyOtp = '11111110003';
  static const String phonePending = '11111110004';
  static const String phoneSuspended = '11111110005';

  // The single "valid" password for phoneRequirePw.
  static const String validLoginPassword = 'Senha123';

  // The OTP code accepted on both registration + reset verify paths.
  static const String validOtp = '123456';

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Build a fake UserModel JSON — enough fields for `UserBloc.loggedIn` +
  /// the approval gate (Principle VIII) to route correctly.
  Map<String, dynamic> _fakeUserJson({
    required String phone,
    required String role,
    bool isApproval = true,
    String? email,
  }) {
    return {
      'id': 1,
      'name': 'Test User',
      'phone': phone,
      'email': email ?? 't***@example.com',
      'access_token': 'mock-jwt-${DateTime.now().millisecondsSinceEpoch}',
      'is_approval': isApproval,
      'role': role,
    };
  }

  Future<T> _delayed<T>(T value) async {
    await Future<void>.delayed(_fakeLatency);
    if (kDebugMode) debugPrint('[SDA MOCK] $value');
    return value;
  }

  // ─── 1. check-identifier ─────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthActionResponse>> checkIdentifier(
      CheckIdentifierRequest request) async {
    AuthAction action;
    String? tempToken;
    switch (request.phone) {
      case phoneCreate:
        action = AuthAction.createNewPassword;
        tempToken = 'mock-set-password-token';
        break;
      case phoneRequirePw:
        action = AuthAction.requirePassword;
        break;
      case phoneVerifyOtp:
        // EMAIL_OTP_ENABLED=false equivalent: a `pending` user whose email
        // would normally need OTP verification is treated as already
        // verified and routes straight to PendingApprovalScreen.
        if (DebugFlags.kSdaSkipOtp) {
          action = AuthAction.goToPendingApproval;
        } else {
          action = AuthAction.verifyEmailOtp;
          tempToken = 'mock-verify-email-token';
        }
        break;
      case phonePending:
        action = AuthAction.goToPendingApproval;
        break;
      case phoneSuspended:
        action = AuthAction.accountSuspended;
        break;
      default:
        action = AuthAction.notFound;
    }
    return _delayed(Right(AuthActionResponse(
      action: action,
      tempToken: tempToken,
      expiresIn: tempToken == null ? null : 600,
    )));
  }

  // ─── 2. set-initial-password ─────────────────────────────────────────

  @override
  Future<Either<Failure, UserModel>> setInitialPassword(
      SetPasswordRequest request) async {
    if (request.tempToken != 'mock-set-password-token') {
      return _delayed(const Left(ServerFailure(message: 'TOKEN_INVALID')));
    }
    return _delayed(Right(UserModel.fromJson(_fakeUserJson(
      phone: phoneCreate,
      role: 'parent',
    ))));
  }

  // ─── 3. self-register ───────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthActionResponse>> selfRegister(
      SelfRegisterRequest request) async {
    // EMAIL_OTP_ENABLED=false equivalent: skip the OTP screen entirely;
    // the account is treated as email-verified the moment it's created
    // and routes straight to PendingApprovalScreen.
    if (DebugFlags.kSdaSkipOtp) {
      return _delayed(const Right(AuthActionResponse(
        action: AuthAction.goToPendingApproval,
      )));
    }
    return _delayed(Right(AuthActionResponse(
      action: AuthAction.verifyEmailOtp,
      tempToken: 'mock-self-register-otp-token',
      expiresIn: 600,
    )));
  }

  // ─── 4. verify-email-otp (registration) ─────────────────────────────

  @override
  Future<Either<Failure, AuthActionResponse>> verifyEmailOtp(
      OtpVerifyRequest request) async {
    // Defense in depth: if the OTP step is hidden but mobile somehow reached
    // this endpoint anyway, surface the canonical `OTP_BYPASSED` error
    // (matches the backend contract — see contracts/email-otp.md §3).
    if (DebugFlags.kSdaSkipOtp) {
      return _delayed(const Left(ServerFailure(message: 'OTP_BYPASSED')));
    }
    if (request.code != validOtp) {
      return _delayed(const Left(ServerFailure(message: 'OTP_INVALID')));
    }
    return _delayed(const Right(AuthActionResponse(
      action: AuthAction.goToPendingApproval,
    )));
  }

  // ─── 5. login ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserModel>> login(SdaLoginRequest request) async {
    if (request.password != validLoginPassword) {
      return _delayed(const Left(ServerFailure(message: 'INVALID_CREDENTIALS')));
    }
    return _delayed(Right(UserModel.fromJson(_fakeUserJson(
      phone: request.phone,
      role: request.role,
    ))));
  }

  // ─── 6. forgot-password ─────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthActionResponse>> forgotPassword(
      ForgotPasswordRequest request) async {
    // Password reset is BLOCKED (not bypassed) when OTP is hidden — letting
    // it through would mean anyone who knows an email could reset that
    // account's password. Matches the backend contract — see
    // contracts/email-otp.md §3 + security.md §8.
    if (DebugFlags.kSdaSkipOtp) {
      return _delayed(const Left(
        ServerFailure(message: 'PASSWORD_RESET_UNAVAILABLE'),
      ));
    }
    return _delayed(Right(AuthActionResponse(
      action: AuthAction.verifyResetOtp,
      tempToken: 'mock-forgot-password-token',
      expiresIn: 600,
    )));
  }

  // ─── 7. verify-reset-otp ────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthActionResponse>> verifyResetOtp(
      OtpVerifyRequest request) async {
    // Same defense-in-depth as verifyEmailOtp.
    if (DebugFlags.kSdaSkipOtp) {
      return _delayed(const Left(ServerFailure(message: 'OTP_BYPASSED')));
    }
    if (request.code != validOtp) {
      return _delayed(const Left(ServerFailure(message: 'OTP_INVALID')));
    }
    return _delayed(Right(AuthActionResponse(
      action: AuthAction.setNewPassword,
      tempToken: 'mock-reset-password-token',
      expiresIn: 600,
    )));
  }

  // ─── 8. reset-password ──────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> resetPassword(SetPasswordRequest request) async {
    if (request.tempToken != 'mock-reset-password-token') {
      return _delayed(const Left(ServerFailure(message: 'TOKEN_INVALID')));
    }
    return _delayed(const Right(unit));
  }
}
