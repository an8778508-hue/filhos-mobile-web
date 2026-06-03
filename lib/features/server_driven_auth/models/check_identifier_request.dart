/// `POST auth/check-identifier` request payload — the unified entry point.
/// See [specs/server_driven_auth/contracts/rest-endpoints.md] §1.
class CheckIdentifierRequest {
  final String phone;
  final String countryCode;

  /// `'parent'` | `'teacher'`. Derived pre-login from
  /// `context.isProfessors ? 'teacher' : 'parent'` (FR-SDA-03).
  final String role;

  const CheckIdentifierRequest({
    required this.phone,
    required this.countryCode,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'country_code': countryCode,
        'role': role,
      };
}
