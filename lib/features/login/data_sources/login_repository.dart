import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';

abstract class LoginRepository {
  final String loginEndpoint = "auth/login";
  final String socialLoginEndpoint = "auth/social-login";
  Future<Either<Failure, UserModel>> login(LoginRequest request);
  Future <Either<Failure, UserModel>> signInWithGoogle();
  Future <Either<Failure, UserModel>> signInWithFacebook();

  Future requestOTP({
    required String phone,
    required Future<void> Function() onReady,
    required Future<void> Function(OTPRequest login) onSuccess,
    required Future<void> Function(OTPErrorModel error) onFailed,
  });

  Future<Either<OTPErrorModel, OTPRequest>> confirmOTP({
    required String smsCode,
    required String phone,
  });
}
