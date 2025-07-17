// lib/features/auth/register/bloc/register_bloc.dart

import 'package:escola/features/register/bloc/register_event.dart';
import 'package:escola/features/register/bloc/register_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/user/bloc/user_bloc.dart';
import '../../login/data_sources/login_repository.dart';

class RegisterBloc extends Cubit<RegisterStates> {
  final LoginRepository loginRepository;

  RegisterBloc(this.loginRepository) : super(InitialRegisterState());

  Future<void> submitRegister(RegisterParamaters event) async {
    emit(LoadingRegisterState());
    try {
      final result = await loginRepository.register(event: event);
      result.fold(
        (failure) => emit(ErrorRegisterState(failure.message)),
        (success) {
          UserBloc.get.loggedIn(success);
          emit(SuccessRegisterState());
        },
      );
    } catch (e) {
      emit(ErrorRegisterState(e.toString()));
    }

  }
}