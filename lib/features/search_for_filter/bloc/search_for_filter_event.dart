
import 'package:equatable/equatable.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';

class SearchForFilterEvent extends Equatable {
  const SearchForFilterEvent();

  @override
  List<Object> get props => [];
}

class GetSearchForFilterItems extends SearchForFilterEvent {
  final SearchForFilterModelType searchModelType;

  GetSearchForFilterItems(this.searchModelType);
}

class SubmitSearchForFilter extends SearchForFilterEvent {
  final String query;
  final SearchForFilterModelType searchModelType;

  const SubmitSearchForFilter({required this.query,required this.searchModelType});
}

class ClearSearchForFilter extends SearchForFilterEvent {}
