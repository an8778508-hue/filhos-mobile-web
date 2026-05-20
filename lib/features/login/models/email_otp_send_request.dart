class EmailOTPSendRequest {
  final String email;
  final String lang;

  const EmailOTPSendRequest({
    required this.email,
    required this.lang,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'lang': lang,
      };
}
