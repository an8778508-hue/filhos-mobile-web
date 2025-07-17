// lib/features/auth/register/bloc/register_states.dart


import 'package:equatable/equatable.dart';

abstract class RegisterStates extends Equatable {
  const RegisterStates();
  @override
  List<Object> get props => [];
}

class InitialRegisterState extends RegisterStates {}

class LoadingRegisterState extends RegisterStates {}

class SuccessRegisterState extends RegisterStates {}

class ErrorRegisterState extends RegisterStates {
  final String error;
  const ErrorRegisterState(this.error);
}