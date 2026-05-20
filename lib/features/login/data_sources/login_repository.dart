import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/login/models/email_otp_send_response.dart';
import 'package:escola/features/login/models/email_otp_verify_response.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';

import '../../register/bloc/register_event.dart';
import '../models/login_email_paramaters.dart';

abstract class LoginRepository {
  final String loginEndpoint = "auth/login";
  final String socialLoginEndpoint = "auth/social-login";
  final String registerEndpoint = "auth/register";
  final String loginWithEmailEndpoint = "auth/login-with-email";
  static const String emailOtpSendEndpoint = 'auth/email-otp/send';
  static const String emailOtpVerifyEndpoint = 'auth/email-otp/verify';
  Future<Either<Failure, UserModel>> login(LoginRequest request);
  Future <Either<Failure, UserModel>> signInWithGoogle();
  Future <Either<Failure, UserModel>> signInWithFacebook();
  Future <Either<Failure, UserModel>> signInWithApple();

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

  // Register methods
  Future<Either<Failure, UserModel>> register({
   required RegisterParamaters event,
  });
  Future<Either<Failure, UserModel>> loginWithEmail({
    required LoginEmailParamaters parameters,

  });

  Future<Either<Failure, EmailOTPSendResponse>> requestEmailOTP({
    required String email,
  });

  Future<Either<Failure, EmailOTPVerifyResponse>> confirmEmailOTP({
    required String email,
    required String code,
  });
}
