import 'package:escola/core/localization/localization_keys.dart';

/// Maps backend `error.code` strings (see
/// [specs/server_driven_auth/contracts/rest-endpoints.md] §0 Error codes) to
/// the localization key the dispatcher / cubit surfaces.
///
/// We carry the raw `code` inside `Failure.message` from the impl, then translate
/// here. Unknown codes fall back to a generic localized string and are logged so
/// version skew is visible in Crashlytics.
class AuthErrorCodes {
  static String localizedKey(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return LocalizationKeys.sda_error_invalid_credentials;
      case 'ACCOUNT_SUSPENDED':
        return LocalizationKeys.sda_error_account_suspended;
      case 'TOKEN_INVALID':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_SCOPE_MISMATCH':
        return LocalizationKeys.sda_error_token_invalid;
      case 'OTP_INVALID':
        return LocalizationKeys.sda_error_invalid_credentials;
      case 'OTP_EXPIRED':
        return LocalizationKeys.sda_error_otp_expired;
      case 'OTP_TOO_MANY_ATTEMPTS':
        return LocalizationKeys.sda_error_otp_too_many;
      case 'PASSWORD_RESET_UNAVAILABLE':
        return LocalizationKeys.sda_error_reset_unavailable;
      case 'VALIDATION_ERROR':
        return LocalizationKeys.sda_error_generic;
      case 'EMAIL_ALREADY_REGISTERED':
      case 'RATE_LIMITED':
      case 'OTP_BYPASSED':
      default:
        return LocalizationKeys.sda_error_generic;
    }
  }
}
