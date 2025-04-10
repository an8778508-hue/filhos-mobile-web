class ConfirmOTPRequest {
  final String phone;
  final String code;

  ConfirmOTPRequest({
    required this.phone,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'code': code,
    };
  }
}
