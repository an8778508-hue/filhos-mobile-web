class OTPErrorModel {
  final String? code;
  final String? message;

  const OTPErrorModel({
    required this.code,
    required this.message,
  });

  const OTPErrorModel.timeout()
      : message = null,
        code = 'timeout';

  const OTPErrorModel.alreadySent()
      : message = null,
        code = 'already_sent';

  const OTPErrorModel.verificationIdNotFound()
      : message = null,
        code = 'verification_id_null';

}
