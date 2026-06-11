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

/// Emitted once the verification OTP has been sent to the entered email.
/// The screen reacts by navigating to the OTP verification screen, where the
/// account is actually created after the code is confirmed.
class RegisterOtpSentState extends RegisterStates {
  final String maskedEmail;
  const RegisterOtpSentState(this.maskedEmail);

  @override
  List<Object> get props => [maskedEmail];
}

class ErrorRegisterState extends RegisterStates {
  final String error;
  const ErrorRegisterState(this.error);

  @override
  List<Object> get props => [error];
}