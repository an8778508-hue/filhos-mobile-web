class OTPRequest {
  final String phoneNumber;
  final String? firebaseIdToken;

  OTPRequest({required this.phoneNumber, this.firebaseIdToken});

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
    };
  }
}
