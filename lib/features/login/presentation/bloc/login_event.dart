part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginByPhone extends LoginEvent {
  final LoginRequest loginRequest;
  const LoginByPhone(this.loginRequest);
  @override
  List<Object> get props => [loginRequest];
}

