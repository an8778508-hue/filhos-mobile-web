import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';
import 'package:escola/features/server_driven_auth/models/check_identifier_request.dart';
import 'package:escola/features/server_driven_auth/models/forgot_password_request.dart';
import 'package:escola/features/server_driven_auth/models/otp_verify_request.dart';
import 'package:escola/features/server_driven_auth/models/sda_login_request.dart';
import 'package:escola/features/server_driven_auth/models/self_register_request.dart';
import 'package:escola/features/server_driven_auth/models/set_password_request.dart';

/// The eight server-driven-auth endpoints. Implemented in
/// `server_driven_auth_impl.dart` via `NetworkClient.handleRequest`
/// (Constitution Principle III). Contract: see
/// [specs/server_driven_auth/contracts/rest-endpoints.md].
abstract class ServerDrivenAuthRepository {
  // Endpoint constants — single source of truth shared with the redaction
  // allowlist in `network_client.dart`. Keep in sync.
  static const String checkIdentifierEndpoint = 'auth/check-identifier';
  static const String setInitialPasswordEndpoint = 'auth/set-initial-password';
  static const String selfRegisterEndpoint = 'auth/self-register';
  static const String verifyEmailOtpEndpoint = 'auth/verify-email-otp';
  static const String loginEndpoint = 'auth/login';
  static const String forgotPasswordEndpoint = 'auth/forgot-password';
  static const String verifyResetOtpEndpoint = 'auth/verify-reset-otp';
  static const String resetPasswordEndpoint = 'auth/reset-password';

  /// Entry: phone → `action` envelope.
  Future<Either<Failure, AuthActionResponse>> checkIdentifier(
      CheckIdentifierRequest request);

  /// Scenario 1 terminal: consumes a `set-password`-scoped temp_token,
  /// returns the final UserModel + JWT.
  Future<Either<Failure, UserModel>> setInitialPassword(
      SetPasswordRequest request);

  /// Scenario 2 entry: creates a `pending` user; server branches on
  /// `EMAIL_OTP_ENABLED` and returns `VERIFY_EMAIL_OTP` or
  /// `GO_TO_PENDING_APPROVAL`.
  Future<Either<Failure, AuthActionResponse>> selfRegister(
      SelfRegisterRequest request);

  /// Scenario 2 step 2: verifies registration OTP; flips `email_verified`.
  Future<Either<Failure, AuthActionResponse>> verifyEmailOtp(
      OtpVerifyRequest request);

  /// Scenarios 3 + 4 terminal: phone + password → JWT.
  Future<Either<Failure, UserModel>> login(SdaLoginRequest request);

  /// Scenario 5 entry: email → `VERIFY_RESET_OTP` envelope (or
  /// `PASSWORD_RESET_UNAVAILABLE` when `EMAIL_OTP_ENABLED=false`).
  Future<Either<Failure, AuthActionResponse>> forgotPassword(
      ForgotPasswordRequest request);

  /// Scenario 5 step 2: verifies reset OTP; returns `SET_NEW_PASSWORD` +
  /// `reset-password`-scoped temp_token.
  Future<Either<Failure, AuthActionResponse>> verifyResetOtp(
      OtpVerifyRequest request);

  /// Scenario 5 terminal: consumes `reset-password` temp_token; server
  /// invalidates all existing sessions.
  Future<Either<Failure, Unit>> resetPassword(SetPasswordRequest request);
}
