import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/models/login_requset.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/models/otp_requset.dart';
import 'package:flutter/cupertino.dart';

// part 'otp_event.dart';
part 'otp_state.dart';

class OTPBloc extends Cubit<OTPState> {
  final LoginRepository loginRepository;
  final LocalDatabaseRepo localDatabase;
  OTPRequest? loginModel;
  Timer? _timer;
  int? pendingOTPTime;
  bool rememberMe = false;
  ValueNotifier<bool> ready = ValueNotifier(false);

  OTPBloc(this.loginRepository, this.localDatabase) : super(OTPInitial()) {
    // on<OTPEvent>((event, emit) async {
    //   if (event is RequestOTPEvent) {
    //     await requestOTP(emit,phone: event.loginRequest.phoneNumber,);
    //   }
    //   if (event is SubmitOTPEvent) {
    //     await confirmSMSCode(emit,phone: event.otpRequest.phone,code: event.otpRequest.phone);
    //   }
    // });
  }

  final int otpTimeout = 60;

  _successOTP(OTPRequest model, String countryCode) async {
    final loginResponse =
        await loginRepository.login(LoginRequest(phone: model.phoneNumber, country_code: countryCode));
    await loginResponse.fold((l) async => emit(OTPFailure(l)), (user) async {
      localDatabase.delete(key: LocalKeys.last_otp_request);
      localDatabase.delete(key: LocalKeys.last_otp_phone);
      _timer?.cancel();
      loginModel = model;

      if (rememberMe) {
        localDatabase.write(key: LocalKeys.rememberMe, value: rememberMe);
      }
      UserBloc.get.loggedIn(user);
      emit(OTPSuccess());
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

  void _startTimer() {
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

  Future<void> requestOTP({
    required String phone,
    required String countryCode,
    required bool remember,
  }) async {
    rememberMe = remember;
    emit(OTPLoading());
    await _init(phone);
    final lastOtpPhone = await localDatabase.read(key: LocalKeys.last_otp_phone);
    if (pendingOTPTime != null && lastOtpPhone == phone) {
      emit(OTPFailure(NetworkFailure(message: OTPErrorModel.alreadySent().code ?? '')));
      // print('OTPBloc.requestOTP ${l.code}');
      // if(l.code == 'already_sent'){
      ready.value = true;
      return;
      // }
    }
    await localDatabase.write(key: LocalKeys.last_otp_request, value: DateTime.now().millisecondsSinceEpoch);
    await localDatabase.write(key: LocalKeys.last_otp_phone, value: phone);
    pendingOTPTime = otpTimeout;
    _startTimer();

    await loginRepository.requestOTP(
      phone: phone,
      onReady: () async {
        _startTimer();
        ready.value = true;
        emit(OTPReady());
      },
      onFailed: (l) async {
        print('OTPBloc.requestOTP ${l.code}');
        if (l.code == 'already_sent') {
          ready.value = true;
          return;
        }
        if (!isClosed) {
          emit(OTPFailure(NetworkFailure(message: l.code ?? '')));
        }
      },
      onSuccess: (r) async => _successOTP(r, countryCode),
    );
  }

  Future<void> resendOTP({
    required String phone,
    required String countryCode,
  }) async {
    // safeEmit(const OTPState());
    await requestOTP(phone: phone, remember: rememberMe, countryCode: countryCode);
  }

  confirmSMSCode({
    required String code,
    required String phone,
    required String countryCode,
  }) async {
    emit(OTPLoading());
// safeEmit(state.asLoading());
    final f = await loginRepository.confirmOTP(
      smsCode: code,
      phone: phone,
    );
    f.fold(
      (l) {
        emit(OTPFailure(NetworkFailure(message: l.code ?? '')));
      },
      (r) => _successOTP(r, countryCode),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
