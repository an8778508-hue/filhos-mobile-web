part of 'main_bloc.dart';

sealed class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object> get props => [];
}

class ChangePage extends MainEvent {
  final String id;

  const ChangePage({required this.id});

  @override
  List<Object> get props => [id];
}
