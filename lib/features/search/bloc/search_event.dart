part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class ChildSearch extends SearchEvent {
  final String query;

  const ChildSearch({required this.query});
}

class GlobalSearch extends SearchEvent {
  final String query;
  final bool isTeacher;

  const GlobalSearch({required this.query, required this.isTeacher});
}

class ProfessorSearch extends SearchEvent {
  final String query;

  const ProfessorSearch({required this.query});
}

class ClearSearch extends SearchEvent {}

class ShowEmptySearch extends SearchEvent {}