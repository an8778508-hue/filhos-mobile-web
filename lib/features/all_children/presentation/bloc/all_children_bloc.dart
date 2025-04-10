import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/all_children/data_source/all_children_dc.dart';
import 'package:escola/features/diary/models/school_item.dart';

part 'all_children_event.dart';
part 'all_children_state.dart';

class AllChildrenBloc extends Bloc<AllChildrenEvent, AllChildrenState> {
  final AllChildrenRepo allChildrenRepo;

  List<SchoolItem>? allChildren;
  AllChildrenBloc(
    this.allChildrenRepo,
  ) : super(AllChildrenInitial()) {
    on<AllChildrenEvent>((event, emit) async {
      if (event is GetAllChildren) {
        await _handleAllchildren(event, emit);
      }
    });
  }

  Future<void> _handleAllchildren(
      GetAllChildren event, Emitter<AllChildrenState> emit) async {
    emit(AllChildrenLoading());
    await allChildrenRepo.getAllChildren().then((value) {
      value.fold(
        (l) => emit(AllChildrenFailed(failure: l)),
        (items) {
          allChildren = items;
          emit(AllChildrenSucceed(items: items));
        },
      );
    });
  }
}
