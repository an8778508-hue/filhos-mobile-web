import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_requset.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/user/bloc/user_bloc.dart';
import '../../models/login_email_paramaters.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Cubit<LoginState> {
  final LoginRepository loginRepository;
  final LocalDatabaseRepo localDatabase;

  LoginBloc(this.loginRepository, this.localDatabase) : super(LoginInitial()) {}
  int? pendingOTPTime;
  OTPRequest? loginModel;
  Timer? _timer;
  final int otpTimeout = 60;

  Future<void> requestOTP({
    required String phone,
    required String countryCode,
  }) async {
    emit(LoginLoading());
    await _init(phone);
    final lastOtpPhone = await localDatabase.read(key: LocalKeys.last_otp_phone);
    if (pendingOTPTime != null && lastOtpPhone == phone) {
      // emit(LoginFailure(NetworkFailure(message: const OTPErrorModel.alreadySent().code ?? '')));
      // print('OTPBloc.requestOTP ${l.code}');
      // if(l.code == 'already_sent'){
      emit(LoginReady());
      return;
      // }
      return;
    }
    await localDatabase.write(key: LocalKeys.last_otp_request, value: DateTime.now().millisecondsSinceEpoch);
    await localDatabase.write(key: LocalKeys.last_otp_phone, value: phone);
    _startTimer();
        debugPrint('OTPBloc.requestOtttttttttttttttttttttTP ${phone}');
    await loginRepository.requestOTP(
      phone: phone,
      onReady: () async {
        _startTimer();
        emit(LoginReady());
      },
      onFailed: (l) async {
        print('OTPBloc.requestOTP ${l.message}');
        if (l.code == 'already_sent') {
          emit(LoginReady());
          return;
        }
        if (!isClosed) {
          emit(LoginFailure(NetworkFailure(message: '${l.code}''${l.message}' ?? '')));
        }
      },
      onSuccess: (r) async {},
    );
  }

  _startTimer() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final pendingTime = pendingOTPTime ?? otpTimeout;

      if (pendingTime <= 0) {
        localDatabase.delete(key: LocalKeys.last_otp_request);
        localDatabase.delete(key: LocalKeys.last_otp_phone);
        pendingOTPTime = null;
        _timer?.cancel();
        return;
      }

      if (pendingOTPTime != null) {
        pendingOTPTime = pendingOTPTime! - 1;
      }
    });
  }

  _init(String phone) async {
    final lastOTPRequest = await localDatabase.read(key: LocalKeys.last_otp_request);
    final lastOtpPhone = await localDatabase.read(key: LocalKeys.last_otp_phone);
    if (lastOTPRequest != null && lastOTPRequest is int && phone == lastOtpPhone) {
      final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastOTPRequest));
      if (diff.inSeconds < otpTimeout) {
        pendingOTPTime = otpTimeout - diff.inSeconds;
      }
    }

    if (pendingOTPTime != null) {
      _startTimer();
    }
  }

  clearError() {
    emit(LoginInitial());
  }

  Future<void> loginWithGoogle() async {
    emit(LoginLoading());
    final result = await loginRepository.signInWithGoogle();
    result.fold(
          (failure) => emit(LoginFailure(failure)),
          (userModel) async {
            debugPrint('LoginBloc.loginWithGoogle userModel: $userModel');
            emit(LoginSocialSuccess(userModel ));
          },
    );
  }
  Future<void> loginWithFacebook() async {
    emit(LoginLoading());
    final result = await loginRepository.signInWithFacebook();
    result.fold(
          (failure) => emit(LoginFailure(failure)),
          (userModel) async {
            debugPrint('LoginBloc.loginWithFacebook userModel: $userModel');
            emit(LoginSocialSuccess(userModel));
          },
    );
  }


  Future<void> loginWithApple() async {
    emit(LoginLoading());
    final result = await loginRepository.signInWithApple();
    result.fold(
          (failure) => emit(LoginFailure(failure)),
          (userModel) async {
            debugPrint('LoginBloc.loginWithApple userModel: $userModel');
            emit(LoginSocialSuccess(userModel));
          },
    );
  }
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());
    final result = await loginRepository.loginWithEmail(
      parameters: LoginEmailParamaters(email: email, password: password),
    );
    result.fold(
      (failure) => emit(LoginFailure(failure)),
      (userModel) async {
        debugPrint('LoginBloc.loginWithEmail userModel: $userModel');
        UserBloc.get.loggedIn(userModel);
        emit(LoginWithEmailSuccess(userModel));
      },
    );
  }

}
