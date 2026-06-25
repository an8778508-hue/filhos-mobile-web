import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/urgent_messages/model/urgent_message_model.dart';

class UrgentMessageState {
  final GenericListState<UrgentMessageModel> messagesState;

  const UrgentMessageState({
    this.messagesState = const GenericListState<UrgentMessageModel>(),
  });

  UrgentMessageState copyWith({
    GenericListState<UrgentMessageModel>? messagesState,
  }) =>
      UrgentMessageState(
        messagesState: messagesState ?? this.messagesState,
      );

  UrgentMessageState updateMessagesState(
          GenericListState<UrgentMessageModel> Function(GenericListState<UrgentMessageModel> s) update) =>
      copyWith(messagesState: update(messagesState));

  List<UrgentMessageModel> get data => messagesState.data;

  int get unreadCount => data.where((m) => !m.isRead).length;
}
