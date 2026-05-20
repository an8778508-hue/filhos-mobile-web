import 'package:escola/core/models/user_model.dart';

class EmailOTPVerifyResponse {
  final String accessToken;
  final UserModel user;

  const EmailOTPVerifyResponse({
    required this.accessToken,
    required this.user,
  });

  factory EmailOTPVerifyResponse.fromJson(Map<String, dynamic> json) =>
      EmailOTPVerifyResponse(
        accessToken: json['access_token'] as String,
        user: UserModel.fromJson(json['data'] as Map<String, dynamic>),
      );
}
