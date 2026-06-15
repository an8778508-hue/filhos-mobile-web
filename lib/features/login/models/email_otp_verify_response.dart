import 'package:escola/core/models/user_model.dart';

class EmailOTPVerifyResponse {
  final String accessToken;
  final UserModel user;

  const EmailOTPVerifyResponse({
    required this.accessToken,
    required this.user,
  });

  factory EmailOTPVerifyResponse.fromJson(Map<String, dynamic> json) {
    // Laravel (auth/login shape): the user — including the real Sanctum
    // access_token — lives inside `data`.
    final data = json['data'] as Map<String, dynamic>;
    return EmailOTPVerifyResponse(
      accessToken: (data['access_token'] ?? '').toString(),
      user: UserModel.fromJson(data),
    );
  }
}
