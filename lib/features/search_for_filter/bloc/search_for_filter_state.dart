
 import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/search/models/global_search.dart';

class SearchForFilterState extends Equatable {
  const SearchForFilterState();

  @override
  List<Object> get props => [];
}

final class SearchForFilterInitial extends SearchForFilterState {}

class SearchForFilterActivitiesLoading extends SearchForFilterState {}

class ChangeValueLoading extends SearchForFilterState {}

class ChangeValueSucceed extends SearchForFilterState {}

class SearchForFilterItemsLoading extends SearchForFilterState {}

class SearchForFilterItemsSucceed extends SearchForFilterState {
  final GlobalSearchResult? items;

  const SearchForFilterItemsSucceed({required this.items});

}

class SearchForFilterItemsError extends SearchForFilterState {
  final Failure failure;

  const SearchForFilterItemsError({required this.failure});

  @override
  List<Object> get props => [failure];
}
