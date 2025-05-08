import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/data_sources/search_dc.dart';
import 'package:escola/features/search/models/global_search.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepo searchRepo;
  List<SchoolItem>? schoolItemsResult;
  GlobalSearchResult? globalSearchResult;

  SearchBloc(this.searchRepo) : super(SearchInitial()) {
    on<SearchEvent>((event, emit) async {
      if (event is ChildSearch) {
        await _childSearch(event, emit);
      } else if (event is GlobalSearch) {
        await _globalSearch(event, emit);
      } else if (event is ProfessorSearch) {
        await _professorSearch(event, emit);
      } else if (event is ClearSearch) {
        emit(SearchLoading());
        schoolItemsResult = null;
        globalSearchResult = null;
        emit(SearchSucceed());
      }
    });
  }

  _globalSearch(GlobalSearch event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    return searchRepo.globalSearchForProfessor(event.query,event.isTeacher).then((result) {
      result.fold(
        (failure) => emit(SearchFailed(failure: failure)),
        (results) {
          globalSearchResult = results;
          emit(SearchSucceed());
        },
      );
    });
  }

  _professorSearch(ProfessorSearch event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    return searchRepo.professorSearch(event.query).then((result) {
      result.fold(
        (failure) => emit(SearchFailed(failure: failure)),
        (results) {
          globalSearchResult = GlobalSearchResult(
              teachers: results,
              parents: const [],
              children: const [],
              levels: const []);
          emit(SearchSucceed());
        },
      );
    });
  }

  _childSearch(ChildSearch event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    return searchRepo.childSearch(event.query).then((result) {
      result.fold(
        (failure) => emit(SearchFailed(failure: failure)),
        (results) {
          schoolItemsResult = results;
          emit(SearchSucceed());
        },
      );
    });
  }
}
