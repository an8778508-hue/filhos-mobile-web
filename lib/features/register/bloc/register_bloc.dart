// lib/features/auth/register/bloc/register_bloc.dart

import 'package:escola/features/register/bloc/register_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../login/data_sources/login_repository.dart';

class RegisterBloc extends Cubit<RegisterStates> {
  final LoginRepository loginRepository;

  RegisterBloc(this.loginRepository) : super(InitialRegisterState());

  Future<void> sendEmailOtp({required String email}) async {
    emit(LoadingRegisterState());
    try {
      final result = await loginRepository.requestEmailOTP(email: email);
      result.fold(
            (failure) => emit(ErrorRegisterState(failure.message)),
            (response) => emit(RegisterOtpSentState(response.maskedEmail)),
      );
    } catch (e) {
      emit(ErrorRegisterState(e.toString()));
    }
  }
}