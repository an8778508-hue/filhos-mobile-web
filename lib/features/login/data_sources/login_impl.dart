import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
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
    try {
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
    } catch (e) {
      debugPrint('Unexpected error during OTP request: $e');
      await onFailed(OTPErrorModel(
        code: 'unexpected_error',
        message: e.toString(),
      ));
    }
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

  // Send the token to your backend
  Future<Either<Failure, UserModel>> sendSocialTokenToApi({required String idToken, required String provider}) async {
    try {
      return networkClient.handleRequest(
        NetworkRequest(
          method: HttpMethod.post,
          url: socialLoginEndpoint,
          body: {
            'token': idToken,
            'provider': provider,
            'role': (mainKey.currentContext?.isProfessors ?? false) ? 'teacher' : 'parent',
            'platform': Platform.isAndroid ? 'android' : 'ios',
          },
        ),
        onSuccess: (json) {
          // Extract user data from response and create UserModel
          // final userData = json?['user'] ?? {};
          // // Combine access token with user data
          // userData['access_token'] = json?['access_token'];
          //
          // // Create UserModel from the combined data
          // return UserModel.fromJson(userData);
          return UserModel.fromJson(json?['data'] ?? {});
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithGoogle() async {
    try {
      final String iosClientId =
      // Use the correct client ID based on your app flavor
      (mainKey.currentContext?.isProfessors ?? false)
          ? "328842559224-h5603ru66f13lgcfavj5pg4rd8fmc7rg.apps.googleusercontent.com" // prof
          : "328842559224-hdbup6e2enp5cidaeh7oqua8220pflpf.apps.googleusercontent.com"; // parent

      // Create a GoogleSignIn instance with the web client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // This is the crucial part - you need to provide your web client ID
        serverClientId: Platform.isAndroid?"328842559224-ebkef75qeupfjjsthn6cd0es0dp2hj89.apps.googleusercontent.com":iosClientId,
      );

      // Ensure a fresh sign-in by signing out first
      await googleSignIn.signOut();

      // Begin the sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return left(ServerFailure(message: 'Sign in aborted by user'));
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Log the tokens for debugging
      debugPrint('Google User Email: ${googleUser.email}');
      debugPrint('Google Auth accessToken: ${googleAuth.accessToken}');

      if (googleAuth.idToken == null) {
        throw Exception('No ID token returned - check serverClientId configuration');
      }

      // Send token to your backend
      final result = await sendSocialTokenToApi(idToken: googleAuth.accessToken!, provider: 'google');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return result.fold(
        (failure) => Left(failure),
        (r) async {
          UserBloc.get.loggedIn(r);
          return Right(r);
        },
      );
      // Create OAuth credential

      // Sign in to Firebase with the credential
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithFacebook() async {
    try {
      // Initialize Facebook login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status != LoginStatus.success) {
        return Left(ServerFailure(message: 'Facebook login failed or was cancelled'));
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;

      if (accessToken == null || accessToken.tokenString.isEmpty) {
        return Left(ServerFailure(message: 'Failed to get Facebook access token'));
      }

      // Log token for debugging
      debugPrint('Facebook Auth AccessToken: ${accessToken.tokenString}');

      // Get user data if needed
      final userData = await FacebookAuth.instance.getUserData();
      debugPrint('Facebook User Email: ${userData['email']}');
      debugPrint('Facebook User ID: ${userData['id']}');

      // Send token to your backend
      final result2 = await sendSocialTokenToApi(
          idToken: accessToken.tokenString,
          provider: 'facebook'
      );

      // Create OAuth credential for Firebase
      final credential = FacebookAuthProvider.credential(accessToken.tokenString);

      return result2.fold(
            (failure) => Left(failure),
            (r) async {
          UserBloc.get.loggedIn(r);
          return Right(r);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithApple() async {
    if (kIsWeb||Platform.isAndroid) {
      return Future.value(Left(ServerFailure(message: 'Apple Sign-In is not supported on android or web platforms')));
    }

    try {
      // Use the AppleSignIn package to initiate sign-in
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Get the ID token from the credential
      final idToken = appleCredential.identityToken; // Send this to your backend
      //print email and full name if needed
      // Log available info for debugging
      debugPrint('Apple User Email: ${appleCredential.email ?? "Not provided"}');
      debugPrint('Apple User Name: ${appleCredential.givenName ?? ""} ${appleCredential.familyName ?? ""}');
      debugPrint('Apple User ID: ${appleCredential.userIdentifier}');


      if (idToken == null) {
        return Left(ServerFailure(message: 'No ID token returned from Apple Sign-In'));
      }

      // Send token to your backend
      final result = await sendSocialTokenToApi(idToken: idToken, provider: 'apple');
      return result.fold(
        (failure) => Left(failure),
        (r) async {
          UserBloc.get.loggedIn(r);
          return Right(r);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
