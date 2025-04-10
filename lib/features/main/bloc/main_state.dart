part of 'main_bloc.dart';

sealed class MainState extends Equatable {
  const MainState();

  @override
  List<Object> get props => [];
}

final class MainInitial extends MainState {}

final class ChangePageLading extends MainState {}

final class ChangePageSucceed extends MainState {
  final String selectedPage;

  const ChangePageSucceed({required this.selectedPage});
}
