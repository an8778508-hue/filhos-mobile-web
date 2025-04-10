import 'package:escola/features/settings/my_children/bloc/my_children_events.dart';
import 'package:escola/features/settings/my_children/bloc/my_children_states.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyChildrenBloc extends Bloc<MyChildrenEvents, MyChildrenStates> {
  final MyChildrenRepo myMyChildrenRepo;

  MyChildrenBloc({
    required this.myMyChildrenRepo,
  }) : super(const MyChildrenStates()) {
    on<SubmitMyChildrenEvent>(
      (event, emit) async {},
    );
    on<FetchMyChildren>(
      (event, emit) async {
        emit(state.setChildrenState((s) => s.fetching));
        final f = await myMyChildrenRepo.getChildren(event.page);
        f.fold(
          (l) async => emit(state.setChildrenState((s) => s.failed(l))),
          (r) async {
            emit(state.setChildrenState((s) => s.success(r)));
          },
        );
      },
    );
  }
}
