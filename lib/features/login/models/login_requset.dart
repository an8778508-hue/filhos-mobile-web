class LoginRequest {
  final String phone;
  final String country_code;
  final String? firebaseIdToken;

  LoginRequest({
    required this.phone,
    required this.country_code,
    this.firebaseIdToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'country_code': country_code,
      if (firebaseIdToken != null) 'firebase_id_token': firebaseIdToken,
    };
  }
}
