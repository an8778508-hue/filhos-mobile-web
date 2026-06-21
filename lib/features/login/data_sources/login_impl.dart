import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/exceptions.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/models/email_otp_send_response.dart';
import 'package:escola/features/login/models/email_otp_verify_response.dart';
import 'package:escola/features/login/models/login_email_paramaters.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';
import 'package:escola/features/register/bloc/register_event.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginImpl extends LoginRepository {
  final NetworkClientRepository networkClient;

  LoginImpl(this.networkClient);

  @override
  Future<Either<Failure, UserModel>> login(LoginRequest request) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? deviceToken;

    try {
      deviceToken = await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG MODE: FCM token unavailable, using fallback: $e');
        deviceToken = 'debug-device-token';
      } else {
        rethrow;
      }
    }

    return networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.post, url: loginEndpoint, body: {
        'phone': request.phone,
        'country_code': request.country_code.toUpperCase(),
        'device_token': deviceToken,
        'role': isProfessorsFlavor ? 'teacher' : 'parent',
        if (request.firebaseIdToken != null) 'firebase_id_token': request.firebaseIdToken,
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

  static const String _debugOTPCode = '123456';
  bool _isDebugBypass = false;

  @override
  Future requestOTP({
    required String phone,
    required Future<void> Function(OTPRequest login) onSuccess,
    required Future<void> Function(OTPErrorModel error) onFailed,
    required Future<void> Function() onReady,
  }) async {
    if (kDebugMode) {
      debugPrint('DEBUG MODE: Bypassing Firebase phone verification');
      debugPrint('DEBUG MODE: Use code "$_debugOTPCode" to verify');
      _isDebugBypass = true;
      _verificationId = 'debug-verification-id';
      await Future.delayed(const Duration(milliseconds: 500));
      await onReady.call();
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (credential) async {
          final result = await _verifyCredentials(credential: credential, phone: phone);
          result.fold((l) => onFailed(l), (r) => onSuccess(r));
        },
        codeSent: (verificationId, resendToken) async {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onReady.call();
        },
        verificationFailed: (e) async {
          await onFailed(OTPErrorModel(code: e.code, message: e.message));
        },
        codeAutoRetrievalTimeout: (verificationId) async {
          await onFailed(const OTPErrorModel.timeout());
        },
      );
    } catch (e) {
      await onFailed(OTPErrorModel(code: 'unexpected_error', message: e.toString()));
    }
  }

  @override
  Future<Either<OTPErrorModel, OTPRequest>> confirmOTP({
    required String smsCode,
    required String phone,
  }) async {
    if (kDebugMode && _isDebugBypass) {
      if (smsCode == _debugOTPCode) {
        return Right(OTPRequest(phoneNumber: phone, firebaseIdToken: 'debug-firebase-id-token'));
      } else {
        return const Left(OTPErrorModel(
          code: 'invalid-verification-code',
          message: 'Invalid code. In debug mode, use: 123456',
        ));
      }
    }

    if (_verificationId == null) {
      return const Left(OTPErrorModel.verificationIdNotFound());
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _verifyCredentials(credential: credential, phone: phone);
  }

  Future<Either<OTPErrorModel, OTPRequest>> _verifyCredentials({
    required AuthCredential credential,
    required String phone,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      return Right(OTPRequest(phoneNumber: phone, firebaseIdToken: idToken));
    } on FirebaseAuthException catch (e) {
      return Left(OTPErrorModel(code: e.code, message: e.message));
    }
  }

  Future<Either<Failure, UserModel>> sendSocialTokenToApi({
    required String idToken,
    required String provider,
  }) async {
    try {
      return networkClient.handleRequest(
        NetworkRequest(
          method: HttpMethod.post,
          url: socialLoginEndpoint,
          body: {
            'token': idToken,
            'provider': provider,
            'role': isProfessorsFlavor ? 'teacher' : 'parent',
            // Platform (dart:io) is unavailable on web — report 'web' there.
            'platform': kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios'),
          },
        ),
        onSuccess: (json) => UserModel.fromJson(json?['data'] ?? {}),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithGoogle() async {
    try {
      final String iosClientId = isProfessorsFlavor
          ? "328842559224-h5603ru66f13lgcfavj5pg4rd8fmc7rg.apps.googleusercontent.com"
          : "328842559224-hdbup6e2enp5cidaeh7oqua8220pflpf.apps.googleusercontent.com";

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // On web, Platform (dart:io) throws and google_sign_in takes its client
        // id from the index.html meta tag instead of serverClientId.
        serverClientId: kIsWeb
            ? null
            : (Platform.isAndroid
                ? "328842559224-ebkef75qeupfjjsthn6cd0es0dp2hj89.apps.googleusercontent.com"
                : iosClientId),
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return left(ServerFailure(message: 'Sign in aborted by user'));

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw Exception('No ID token returned');

      final result = await sendSocialTokenToApi(idToken: googleAuth.accessToken!, provider: 'google');
      return result.fold((failure) => Left(failure), (r) async {
        UserBloc.get.loggedIn(r);
        return Right(r);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status != LoginStatus.success) {
        return Left(ServerFailure(message: 'Facebook login failed or was cancelled'));
      }
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null || accessToken.tokenString.isEmpty) {
        return Left(ServerFailure(message: 'Failed to get Facebook access token'));
      }
      final result2 = await sendSocialTokenToApi(idToken: accessToken.tokenString, provider: 'facebook');
      return result2.fold((failure) => Left(failure), (r) async {
        UserBloc.get.loggedIn(r);
        return Right(r);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithApple() async {
    if (kIsWeb || Platform.isAndroid) {
      return Future.value(Left(ServerFailure(message: 'Apple Sign-In is not supported on android or web platforms')));
    }
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final idToken = appleCredential.identityToken;
      if (idToken == null) return Left(ServerFailure(message: 'No ID token returned from Apple Sign-In'));
      final result = await sendSocialTokenToApi(idToken: idToken, provider: 'apple');
      return result.fold((failure) => Left(failure), (r) async {
        UserBloc.get.loggedIn(r);
        return Right(r);
      });
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> register({
    required RegisterParamaters event,
    required String otp,
  }) async {
    try {
      return await networkClient.handleRequest<UserModel>(
        NetworkRequest(
          method: HttpMethod.post,
          url: registerEndpoint,
          body: {
            'name': event.name,
            'email': event.email,
            'password': event.password,
            'password_confirmation': event.confirmPassword,
            'otp': otp,
            'role': isProfessorsFlavor ? 'teacher' : 'parent',
          },
        ),
        onSuccess: (json) {
          if (json['error'] == true || json['data'] == null) {
            throw ServerException(message: json['message'] ?? 'Registration failed');
          }
          return UserModel.fromJson(json['data']);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure(message: 'Registration failed'));
    }
  }

  @override
  Future<Either<Failure, UserModel>> loginWithEmail({required LoginEmailParamaters parameters}) async {
    try {
      return await networkClient.handleRequest<UserModel>(
        NetworkRequest(
          url: loginWithEmailEndpoint,
          method: HttpMethod.post,
          body: {
            // Backend `auth/login-with-email` validates/reads `email`, not `username`.
            'email': parameters.username,
            'password': parameters.password,
            'role': isProfessorsFlavor ? 'teacher' : 'parent',
          },
        ),
        onSuccess: (data) {
          if (data['error'] == true || data['data'] == null) {
            throw ServerException(message: data['message'] ?? 'Login failed');
          }
          return UserModel.fromJson(data['data']);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  // ── Email OTP → Laravel Backend (disney.filhos.app) ───────

  @override
  Future<Either<Failure, EmailOTPSendResponse>> requestEmailOTP({
    required String email,
    String purpose = 'login',
  }) async {
    try {
      return await networkClient.handleRequest<EmailOTPSendResponse>(
        NetworkRequest(
          method: HttpMethod.post,
          url: LoginRepository.emailOtpSendEndpoint,
          body: {
            'email': email,
            'purpose': purpose,
            'role': isProfessorsFlavor ? 'teacher' : 'parent',
          },
        ),
        onSuccess: (json) {
          if (json['error'] == true || json['data'] == null) {
            throw ServerException(message: json['message'] ?? 'Failed to send OTP');
          }
          return EmailOTPSendResponse.fromJson(json['data']);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, EmailOTPVerifyResponse>> confirmEmailOTP({
    required String email,
    required String code,
  }) async {
    try {
      return await networkClient.handleRequest<EmailOTPVerifyResponse>(
        NetworkRequest(
          method: HttpMethod.post,
          url: LoginRepository.emailOtpVerifyEndpoint,
          body: {
            'email': email,
            'otp': code,
            'role': isProfessorsFlavor ? 'teacher' : 'parent',
          },
        ),
        onSuccess: (json) {
          if (json['error'] == true || json['data'] == null) {
            throw ServerException(message: json['message'] ?? 'Invalid OTP');
          }
          // Laravel returns the user (with a real Sanctum access_token) inside
          // `data` — same shape as auth/login. Parse via the factory so there's a
          // single source of truth for the response shape.
          return EmailOTPVerifyResponse.fromJson(json);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}