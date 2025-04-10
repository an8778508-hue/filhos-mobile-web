part of 'search_bloc.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSucceed extends SearchState {}

final class SearchFailed extends SearchState {
  final Failure failure;

  const SearchFailed({required this.failure});
}
