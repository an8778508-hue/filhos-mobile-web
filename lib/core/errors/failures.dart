import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({this.message = "Server Error"});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = "Server Error"});

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = "Network Error"});

  @override
  List<Object?> get props => [message];
}
