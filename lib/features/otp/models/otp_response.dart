class OTPResponse {
  final String token;

  OTPResponse({required this.token});

  factory OTPResponse.fromJson(Map<String, dynamic> json) {
    return OTPResponse(token: json['token']);
  }

  // toJson
  Map toJson() {
    return {
      'token': token,
    };
  }
}
