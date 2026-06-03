/// `POST auth/login` request payload (Scenarios 3, 4).
/// Distinct class name (`SdaLoginRequest`) so it does not collide with the
/// legacy `LoginRequest` in `lib/features/login/models/login_requset.dart`,
/// which is still alive behind the rollout flag.
class SdaLoginRequest {
  final String phone;
  final String countryCode;
  final String password;
  final String role;
  final String? deviceToken;

  const SdaLoginRequest({
    required this.phone,
    required this.countryCode,
    required this.password,
    required this.role,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'country_code': countryCode,
        'password': password,
        'role': role,
        if (deviceToken != null) 'device_token': deviceToken,
      };
}
