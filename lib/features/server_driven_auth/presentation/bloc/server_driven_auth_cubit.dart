import 'package:bloc/bloc.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/server_driven_auth/data_sources/server_driven_auth_repository.dart';
import 'package:escola/features/server_driven_auth/models/auth_action.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';
import 'package:escola/features/server_driven_auth/models/auth_error_codes.dart';
import 'package:escola/features/server_driven_auth/models/check_identifier_request.dart';
import 'package:escola/features/server_driven_auth/models/forgot_password_request.dart';
import 'package:escola/features/server_driven_auth/models/otp_verify_request.dart';
import 'package:escola/features/server_driven_auth/models/sda_login_request.dart';
import 'package:escola/features/server_driven_auth/models/self_register_request.dart';
import 'package:escola/features/server_driven_auth/models/set_password_request.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:flutter/foundation.dart';

/// Orchestrates the 8 server-driven-auth endpoints; emits state for the
/// `AuthActionDispatcher` / screen `BlocListener` to react to.
///
/// **One method per endpoint.** No widget anywhere should branch on
/// `action` strings; that's the dispatcher's job. The cubit's job is to
/// translate `Either<Failure, T>` into the right sealed state.
class ServerDrivenAuthCubit extends Cubit<ServerDrivenAuthState> {
  final ServerDrivenAuthRepository repo;

  ServerDrivenAuthCubit(this.repo) : super(const SdaInitial());

  /// Caller wants to restart the flow (e.g., tap Back on the inline-password
  /// state). Returns to the phone-entry state.
  void reset() => emit(const SdaInitial());

  // ───────────── 1. check-identifier ─────────────

  Future<void> checkIdentifier({
    required String phone,
    required String countryCode,
    required String role,
  }) async {
    emit(const SdaLoading());
    final result = await repo.checkIdentifier(CheckIdentifierRequest(
      phone: phone,
      countryCode: countryCode,
      role: role,
    ));
    result.fold(
      (failure) => _emitFailure(failure),
      (response) => _emitForEntryAction(response, phone, countryCode),
    );
  }

  /// Per FR-SDA-04: `REQUIRE_PASSWORD` is an inline state (no nav),
  /// `NOT_FOUND` / `ACCOUNT_SUSPENDED` are inline messages, the rest are
  /// dispatcher-driven navigations.
  void _emitForEntryAction(
      AuthActionResponse r, String phone, String countryCode) {
    switch (r.action) {
      case AuthAction.requirePassword:
        emit(SdaLoginPasswordRequired(
          phone: phone,
          countryCode: countryCode,
        ));
        return;
      case AuthAction.notFound:
        emit(const SdaPhoneNotFound());
        return;
      case AuthAction.accountSuspended:
        emit(const SdaAccountSuspended());
        return;
      case AuthAction.unknown:
        emit(_unknownActionFailure());
        return;
      // All remaining → navigation dispatched by AuthActionDispatcher.
      case AuthAction.createNewPassword:
      case AuthAction.verifyEmailOtp:
      case AuthAction.goToPendingApproval:
      case AuthAction.verifyResetOtp:
      case AuthAction.setNewPassword:
        emit(SdaActionReady(r));
        return;
    }
  }

  // ───────────── 2. set-initial-password ─────────────

  Future<void> setInitialPassword({
    required String tempToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (!_clientValidatePassword(password, passwordConfirmation)) return;
    emit(const SdaLoading());
    final result = await repo.setInitialPassword(SetPasswordRequest(
      tempToken: tempToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ));
    await result.fold(
      (failure) async => _emitFailure(failure),
      (user) async => _loginUser(user),
    );
  }

  // ───────────── 3. self-register ─────────────

  Future<void> selfRegister({
    required String name,
    required String phone,
    required String countryCode,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    if (!_clientValidatePassword(password, passwordConfirmation)) return;
    emit(const SdaLoading());
    final result = await repo.selfRegister(SelfRegisterRequest(
      name: name,
      phone: phone,
      countryCode: countryCode,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
    ));
    result.fold(
      (failure) => _emitFailure(failure),
      // self-register returns either VERIFY_EMAIL_OTP (flag on) or
      // GO_TO_PENDING_APPROVAL (flag off). Both are dispatcher actions.
      (response) => _emitForFollowOnAction(response),
    );
  }

  // ───────────── 4. verify-email-otp (registration) ─────────────

  Future<void> verifyEmailOtp({
    required String tempToken,
    required String code,
  }) async {
    emit(const SdaLoading());
    final result = await repo.verifyEmailOtp(OtpVerifyRequest(
      tempToken: tempToken,
      code: code,
    ));
    result.fold(
      (failure) => _emitFailure(failure),
      // v1: always GO_TO_PENDING_APPROVAL — the dispatcher routes it.
      (response) => _emitForFollowOnAction(response),
    );
  }

  // ───────────── 5. login (phone + password) ─────────────

  Future<void> login({
    required String phone,
    required String countryCode,
    required String password,
    required String role,
    String? deviceToken,
  }) async {
    if (password.isEmpty) {
      emit(SdaFailure(LocalizationKeys.sda_error_invalid_credentials));
      return;
    }
    emit(const SdaLoading());
    final result = await repo.login(SdaLoginRequest(
      phone: phone,
      countryCode: countryCode,
      password: password,
      role: role,
      deviceToken: deviceToken,
    ));
    await result.fold(
      (failure) async => _emitFailure(failure),
      (user) async => _loginUser(user),
    );
  }

  // ───────────── 6. forgot-password ─────────────

  Future<void> forgotPassword(String email) async {
    emit(const SdaLoading());
    final result = await repo.forgotPassword(ForgotPasswordRequest(email: email));
    result.fold(
      (failure) => _emitFailure(failure),
      // Returns VERIFY_RESET_OTP (flag on) or — when the flag is off — the
      // server returns PASSWORD_RESET_UNAVAILABLE as a 403, handled in the
      // failure branch above. Success path is always a dispatcher action.
      (response) => _emitForFollowOnAction(response),
    );
  }

  // ───────────── 7. verify-reset-otp ─────────────

  Future<void> verifyResetOtp({
    required String tempToken,
    required String code,
  }) async {
    emit(const SdaLoading());
    final result = await repo.verifyResetOtp(OtpVerifyRequest(
      tempToken: tempToken,
      code: code,
    ));
    result.fold(
      (failure) => _emitFailure(failure),
      (response) => _emitForFollowOnAction(response),
    );
  }

  // ───────────── 8. reset-password ─────────────

  Future<void> resetPassword({
    required String tempToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (!_clientValidatePassword(password, passwordConfirmation)) return;
    emit(const SdaLoading());
    final result = await repo.resetPassword(SetPasswordRequest(
      tempToken: tempToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    ));
    result.fold(
      (failure) => _emitFailure(failure),
      (_) => emit(const SdaResetSuccess()),
    );
  }

  // ───────────── helpers ─────────────

  /// For follow-on (non-entry) actions, NOT_FOUND/REQUIRE_PASSWORD/ACCOUNT_SUSPENDED
  /// cannot appear — the backend won't return them mid-flow. We still defend
  /// against `unknown` for version skew.
  void _emitForFollowOnAction(AuthActionResponse r) {
    if (r.action == AuthAction.unknown) {
      emit(_unknownActionFailure());
      return;
    }
    emit(SdaActionReady(r));
  }

  Future<void> _loginUser(UserModel user) async {
    await UserBloc.get.loggedIn(user);
    emit(SdaLoggedIn(user));
  }

  /// Client-side password rules — matches FR-SDA-06/07 and the documented
  /// `sda_error_password_weak` / `sda_error_password_mismatch` keys. Server
  /// re-validates (security.md §6).
  bool _clientValidatePassword(String password, String confirmation) {
    if (password.length < 8) {
      emit(SdaFailure(LocalizationKeys.sda_error_password_weak));
      return false;
    }
    if (password != confirmation) {
      emit(SdaFailure(LocalizationKeys.sda_error_password_mismatch));
      return false;
    }
    return true;
  }

  void _emitFailure(Failure failure) {
    // `network_client.dart` packs the backend `error.code` into
    // `Failure.message` for uniform-envelope endpoints. AuthErrorCodes maps
    // it to a localization key (fallback: sda_error_generic).
    final key = AuthErrorCodes.localizedKey(failure.message);
    emit(SdaFailure(key));
  }

  SdaFailure _unknownActionFailure() {
    if (kDebugMode) {
      // Loud log for backend/app version skew (see spec.md §Edge Cases).
      debugPrint(
          '[SDA] Backend returned an unknown action string. App may be out of date.');
    }
    return SdaFailure(LocalizationKeys.sda_error_unknown_action);
  }
}
