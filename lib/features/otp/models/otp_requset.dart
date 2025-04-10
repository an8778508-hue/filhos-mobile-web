class OTPRequest {
  final String phoneNumber;

  OTPRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
    };
  }
}
