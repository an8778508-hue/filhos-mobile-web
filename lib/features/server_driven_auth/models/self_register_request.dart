/// `POST auth/self-register` request payload (Scenario 2).
/// See [specs/server_driven_auth/contracts/rest-endpoints.md] §3.
class SelfRegisterRequest {
  final String name;
  final String phone;
  final String countryCode;
  final String email;
  final String password;
  final String passwordConfirmation;

  /// `'parent'` | `'teacher'`. Flavor-derived (FR-SDA-03).
  final String role;

  const SelfRegisterRequest({
    required this.name,
    required this.phone,
    required this.countryCode,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'country_code': countryCode,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      };
}
