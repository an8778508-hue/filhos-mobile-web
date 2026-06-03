/// The complete server-driven-auth action vocabulary.
///
/// Returned by the backend (see [specs/server_driven_auth/contracts/rest-endpoints.md]
/// §0 Action vocabulary) as a case-sensitive UPPER_SNAKE string. `fromWire`
/// parses it; any unknown string maps to [AuthAction.unknown] so the
/// [AuthActionDispatcher] can surface a controlled error rather than crash.
enum AuthAction {
  /// Admin-created user, password not yet set → `SetInitialPasswordScreen`.
  createNewPassword,

  /// Active user with a password → reveal inline password field on
  /// `LoginScreen` (no navigation).
  requirePassword,

  /// Self-register OTP pending → `EmailOtpScreen`.
  verifyEmailOtp,

  /// Account awaiting admin approval → `PendingApprovalScreen`.
  goToPendingApproval,

  /// Reset OTP pending → `ResetOtpScreen`.
  verifyResetOtp,

  /// Reset OTP verified → `SetNewPasswordScreen`.
  setNewPassword,

  /// Phone not registered → inline "create account?" prompt.
  notFound,

  /// `status = suspended` → inline suspended error.
  accountSuspended,

  /// Fallthrough for any backend string this client doesn't recognize.
  /// Surfaces `sda_error_unknown_action` and is logged to Crashlytics so
  /// backend/app version skew is observable.
  unknown;

  /// Case-sensitive exact match. Do NOT add lower-case fallbacks here —
  /// per FR-SDA-05 the wire vocabulary is normative.
  static AuthAction fromWire(String? raw) {
    switch (raw) {
      case 'CREATE_NEW_PASSWORD':
        return AuthAction.createNewPassword;
      case 'REQUIRE_PASSWORD':
        return AuthAction.requirePassword;
      case 'VERIFY_EMAIL_OTP':
        return AuthAction.verifyEmailOtp;
      case 'GO_TO_PENDING_APPROVAL':
        return AuthAction.goToPendingApproval;
      case 'VERIFY_RESET_OTP':
        return AuthAction.verifyResetOtp;
      case 'SET_NEW_PASSWORD':
        return AuthAction.setNewPassword;
      case 'NOT_FOUND':
        return AuthAction.notFound;
      case 'ACCOUNT_SUSPENDED':
        return AuthAction.accountSuspended;
      default:
        return AuthAction.unknown;
    }
  }
}
