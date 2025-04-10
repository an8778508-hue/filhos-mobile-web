part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeFetchedSuccessfully extends HomeState {
  final HomeModel homeModel;

  const HomeFetchedSuccessfully({
    required this.homeModel,
  });

  @override
  List<Object> get props => [homeModel];
}

final class HomeError extends HomeState {
  final Failure failure;

  const HomeError({required this.failure});

  @override
  List<Object> get props => [failure];
}
