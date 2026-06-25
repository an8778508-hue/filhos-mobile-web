import 'package:bloc/bloc.dart';
import 'package:escola/features/urgent_messages/bloc/urgent_message_state.dart';
import 'package:escola/features/urgent_messages/model/urgent_message_model.dart';
import 'package:escola/features/urgent_messages/repo/urgent_message_repo.dart';

class UrgentMessageBloc extends Cubit<UrgentMessageState> {
  UrgentMessageBloc(this.repo) : super(const UrgentMessageState());

  final UrgentMessageRepo repo;

  Future<void> fetch({bool reload = false}) async {
    emit(state.updateMessagesState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getMessages();
    f.fold(
      (l) => emit(state.updateMessagesState((s) => s.asFailed(l))),
      (r) => emit(state.updateMessagesState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  Future<void> markRead(int id) async {
    final f = await repo.markRead(id);
    f.fold(
      (l) => null,
      (updated) {
        final newList = state.data
            .map((m) => m.id == updated.id ? updated : m)
            .toList();
        emit(state.updateMessagesState((s) => s.asSuccessfullyLoaded(newList)));
      },
    );
  }

  Future<void> send({
    required int parentId,
    int? childId,
    required String title,
    required String description,
  }) async {
    await repo.send(
      parentId: parentId,
      childId: childId,
      title: title,
      description: description,
    );
  }

  void seed(List<UrgentMessageModel> messages) {
    emit(state.updateMessagesState((s) => s.asSuccessfullyLoaded(messages)));
  }
}
