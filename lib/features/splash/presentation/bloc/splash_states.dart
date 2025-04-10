part of 'splash_bloc.dart';


sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

final class SplashSuccess extends SplashState {
  final bool hasUser;

  const SplashSuccess(this.hasUser);
@override
List<Object> get props => [hasUser];
}

final class SplashFailure extends SplashState {
final Failure failure;
const SplashFailure(this.failure);
@override
List<Object> get props => [failure];
}
