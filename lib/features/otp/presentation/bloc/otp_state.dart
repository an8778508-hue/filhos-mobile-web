part of 'otp_bloc.dart';

sealed class OTPState extends Equatable {
  const OTPState();

  @override
  List<Object> get props => [];
}

final class OTPInitial extends OTPState {}

final class OTPReady extends OTPState {}

final class OTPLoading extends OTPState {}

final class CodeSentVerifyPhoneState extends OTPState {}

final class OTPSuccess extends OTPState {}

final class OTPFailure extends OTPState {
  final Failure failure;
  const OTPFailure(this.failure);
  @override
  List<Object> get props => [failure];
}
