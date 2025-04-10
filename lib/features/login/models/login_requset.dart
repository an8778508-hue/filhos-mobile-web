class LoginRequest {
  final String phone;
  final String country_code;

  LoginRequest({
    required this.phone,
    required this.country_code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'country_code': country_code,
    };
  }
}
