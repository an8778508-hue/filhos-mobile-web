class EmailOTPSendResponse {
  final String maskedEmail;
  final int retryAfter;

  const EmailOTPSendResponse({
    required this.maskedEmail,
    required this.retryAfter,
  });

  factory EmailOTPSendResponse.fromJson(Map<String, dynamic> json) =>
      EmailOTPSendResponse(
        maskedEmail: json['masked_email'] as String,
        retryAfter: (json['retry_after'] as num).toInt(),
      );
}
