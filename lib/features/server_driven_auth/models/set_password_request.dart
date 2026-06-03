/// Used by both `POST auth/set-initial-password` (Scenario 1) and
/// `POST auth/reset-password` (Scenario 5). The [tempToken] scope is enforced
/// server-side — a `set-password` token cannot reset a password and vice versa
/// (FR-SDA-15 — see security.md §2).
class SetPasswordRequest {
  final String tempToken;
  final String password;
  final String passwordConfirmation;

  const SetPasswordRequest({
    required this.tempToken,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() => {
        'temp_token': tempToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
}
