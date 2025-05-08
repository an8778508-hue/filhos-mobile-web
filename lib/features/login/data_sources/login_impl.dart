import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';
import 'package:escola/my_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:escola/flavors/app_flavors.dart';

class LoginImpl extends LoginRepository {
  final NetworkClientRepository networkClient;

  LoginImpl(this.networkClient);
  @override
  Future<Either<Failure, UserModel>> login(LoginRequest request) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? deviceToken = await messaging.getToken();
    return networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.post, url: loginEndpoint, body: {
        'phone': request.phone,
        'country_code': request.country_code.toUpperCase(),
        'device_token': deviceToken,
        'role': (mainKey.currentContext?.isProfessors ?? false) ? 'teacher' : 'parent',
      }, headers: {
        'school': StaticConfig.schoolId
      }),
      onSuccess: (json) {
        return UserModel.fromJson(json?['data'] ?? {});
      },
    );
  }

  int? _resendToken;
  String? _verificationId;

  @override
  Future requestOTP({
    required String phone,
    required Future<void> Function(OTPRequest login) onSuccess,
    required Future<void> Function(OTPErrorModel error) onFailed,
    required Future<void> Function() onReady,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (credential) async {
        debugPrint('OTP AUTO VERIFICATION ');

        final result = await _verifyCredentials(
          credential: credential,
          phone: phone,
        );
        result.fold(
          (l) => onFailed(l),
          (r) => onSuccess(r),
        );
      },
      codeSent: (verificationId, resendToken) async {
        debugPrint('OTP SENT $verificationId $resendToken');
        _verificationId = verificationId;
        _resendToken = resendToken;
        onReady.call();
      },
      verificationFailed: (e) async {
        debugPrint('OTP AUTO VERIFICATION FAILED ${e.code}\n\t\t${e.message}');
        await onFailed(
          OTPErrorModel(
            code: e.code,
            message: e.message,
          ),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) async {
        debugPrint('OTP TIMEOUT $verificationId');
        await onFailed(const OTPErrorModel.timeout());
      },
    );
  }

  @override
  Future<Either<OTPErrorModel, OTPRequest>> confirmOTP({
    required String smsCode,
    required String phone,
  }) async {
    if (_verificationId == null) {
      return const Left(OTPErrorModel.verificationIdNotFound());
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _verifyCredentials(
      credential: credential,
      phone: phone,
    );
  }

  Future<Either<OTPErrorModel, OTPRequest>> _verifyCredentials({
    required AuthCredential credential,
    required String phone,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      return Right(OTPRequest(phoneNumber: phone));
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP MANUAL VERIFICATION FAILED ${e.code}\n\t\t${e.message}');
      if (e.code == 'invalid-verification-code') {
        return Left(OTPErrorModel(
          code: e.code,
          message: e.message,
        ));
      } else {
        return Left(OTPErrorModel(
          code: e.code,
          message: e.message,
        ));
      }
    }
  }
}
