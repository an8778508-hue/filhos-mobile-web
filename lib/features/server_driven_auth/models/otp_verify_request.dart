/// Used by `POST auth/verify-email-otp` (Scenario 2) and
/// `POST auth/verify-reset-otp` (Scenario 5). The endpoint URL differs; the
/// payload shape is identical — both require the originating [tempToken] plus
/// the 6-digit [code].
class OtpVerifyRequest {
  final String tempToken;
  final String code;

  const OtpVerifyRequest({required this.tempToken, required this.code});

  Map<String, dynamic> toJson() => {
        'temp_token': tempToken,
        'code': code,
      };
}
