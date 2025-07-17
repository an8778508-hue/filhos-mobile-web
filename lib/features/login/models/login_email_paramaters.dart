import 'package:equatable/equatable.dart';

abstract class LoginWithEmailEvents extends Equatable {
  const LoginWithEmailEvents();

  @override
  List<Object> get props => [];
}

class LoginEmailParamaters extends LoginWithEmailEvents {
  final String email;
  final String password;

  const LoginEmailParamaters({
    required this.email,
    required this.password,
  });


  @override
  List<Object> get props => [ email, password];
}