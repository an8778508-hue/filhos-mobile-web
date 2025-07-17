part of 'login_bloc.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginReady extends LoginState {}

final class CodeSentVerifyPhoneState extends LoginState {}

final class LoginSuccess extends LoginState {}

final class LoginFailure extends LoginState {
  final Failure failure;

  const LoginFailure(this.failure);

  @override
  List<Object> get props => [failure];
}
final class LoginSocialSuccess extends LoginState {
  final UserModel userModel;
  const LoginSocialSuccess(this.userModel);

  @override
  List<Object> get props => [userModel];
}

final class LoginWithEmailSuccess extends LoginState {
  final UserModel userModel;
  const LoginWithEmailSuccess(this.userModel);

  @override
  List<Object> get props => [userModel];
}