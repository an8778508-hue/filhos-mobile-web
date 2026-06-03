import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/server_driven_auth/models/auth_action.dart';

/// The uniform envelope every entry/step endpoint returns
/// (see [specs/server_driven_auth/contracts/rest-endpoints.md] §0).
///
/// Terminal endpoints (`set-initial-password`, `login`) return the existing
/// `{data, access_token}` shape and parse straight into [UserModel] instead —
/// handled in the repo impl, not here.
class AuthActionResponse {
  final AuthAction action;

  /// Opaque short-lived token (10 min TTL, single-use, scoped). Present on
  /// `CREATE_NEW_PASSWORD`, `VERIFY_EMAIL_OTP`, `VERIFY_RESET_OTP`,
  /// `SET_NEW_PASSWORD`. Held in transient screen state only — never persisted
  /// (FR-SDA-16).
  final String? tempToken;

  /// Seconds until [tempToken] expires (informational; UI may show a countdown).
  final int? expiresIn;

  /// Partial [UserModel] returned alongside `CREATE_NEW_PASSWORD` so the
  /// SetInitialPasswordScreen can render `id` + masked `email`.
  final UserModel? user;

  const AuthActionResponse({
    required this.action,
    this.tempToken,
    this.expiresIn,
    this.user,
  });

  factory AuthActionResponse.fromJson(Map<String, dynamic> json) {
    final dynamic userJson = json['user'];
    return AuthActionResponse(
      action: AuthAction.fromWire(json['action'] as String?),
      tempToken: json['temp_token'] as String?,
      expiresIn: json['expires_in'] is int ? json['expires_in'] as int : null,
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null,
    );
  }
}
