import 'package:equatable/equatable.dart';

abstract class RegisterEvents extends Equatable {
  const RegisterEvents();

  @override
  List<Object> get props => [];
}

class RegisterParamaters extends RegisterEvents {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterParamaters({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
  @override
  List<Object> get props => [name, email, password, confirmPassword];
}