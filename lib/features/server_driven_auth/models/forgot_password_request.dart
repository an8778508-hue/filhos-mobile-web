/// `POST auth/forgot-password` request payload (Scenario 5).
/// See [specs/server_driven_auth/contracts/rest-endpoints.md] §6.
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}
