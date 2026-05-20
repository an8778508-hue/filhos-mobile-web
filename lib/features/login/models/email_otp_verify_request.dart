class EmailOTPVerifyRequest {
  final String email;
  final String code;

  const EmailOTPVerifyRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}
