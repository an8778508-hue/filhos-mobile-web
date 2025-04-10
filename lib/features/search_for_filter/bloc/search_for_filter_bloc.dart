import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/data_sources/search_dc.dart';
import 'package:escola/features/search/models/global_search.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_event.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_state.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';


class SearchForFilterBloc extends Bloc<SearchForFilterEvent, SearchForFilterState> {
  final SearchRepo searchRepo;
  final LocalDatabaseRepo localDatabaseRepo;

  List<SchoolItem>? diaryItems;

  GlobalSearchResult? searchForFilterItems;

  SearchForFilterBloc(this.searchRepo, this.localDatabaseRepo) : super(SearchForFilterInitial()) {
    on<SearchForFilterEvent>((event, emit) async {
      if (event is GetSearchForFilterItems) {
        // await _handleSearchForFilterItems(event, emit);
      } else if (event is SubmitSearchForFilter) {
        await _handleSearchForFilter(event, emit);
      } else if (event is ClearSearchForFilter) {
        await _handleClearSearchForFilter(event, emit);
      }
    });
  }

  Future<void> _handleClearSearchForFilter(
      ClearSearchForFilter event, Emitter<SearchForFilterState> emit) async {
    emit(SearchForFilterItemsLoading());
    searchForFilterItems = null;
    emit(SearchForFilterItemsSucceed(items: searchForFilterItems));
  }

  Future<void> _handleSearchForFilter(SubmitSearchForFilter event, Emitter<SearchForFilterState> emit) async {
    emit(SearchForFilterItemsLoading());
    await searchRepo.globalSearchForProfessor(event.query).then((value) {
      value.fold(
        (l) => emit(SearchForFilterItemsError(failure: l)),
        (items) {
          searchForFilterItems = items;
          emit(SearchForFilterItemsSucceed(items: items));
        },
      );
    });
  }

  // Future<void> _handleSearchForFilterItems(
  //     GetSearchForFilterItems event, Emitter<SearchForFilterState> emit) async {
  //   emit(SearchForFilterItemsLoading());
  //   await diaryRepo.getSearchForFilterModels(event.searchModelType).then((value) {
  //     value.fold(
  //       (l) => emit(SearchForFilterItemsError(failure: l)),
  //       (items) {
  //         diaryItems = items;
  //         emit(SearchForFilterItemsSucceed(items: items));
  //       },
  //     );
  //   });
  // }
}
