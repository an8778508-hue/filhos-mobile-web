part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeFetchDataEvent extends HomeEvent {}

final class ReloadHomeFetchDataEvent extends HomeEvent {
  final bool silent;
  final Completer? completer;

  const ReloadHomeFetchDataEvent({this.silent = false, required this.completer});
}

final class HomeFetchedSuccessfullyEvent extends HomeEvent {}
