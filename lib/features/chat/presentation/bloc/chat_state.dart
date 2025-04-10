part of 'chat_bloc.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

final class ChatInitial extends ChatState {}

class MessagesLoading extends ChatState {}

class ChildrenLoading extends ChatState {}

class ChildrenSucceed extends ChatState {
  final List<ChildModel> filteredChildren;

  const ChildrenSucceed({required this.filteredChildren});
}

class ChildrenFailed extends ChatState {
  final Failure failure;

  const ChildrenFailed({required this.failure});
}

class TeachersLoading extends ChatState {}

class TeachersSucceed extends ChatState {
  final List<ChatUser> teachers;

  const TeachersSucceed({required this.teachers});

  @override
  List<Object> get props => [teachers];
}

class TeachersFailed extends ChatState {
  final Failure failure;

  const TeachersFailed({required this.failure});
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;

  const MessagesLoaded({required this.messages});

  @override
  List<Object> get props => [messages];
}

class MessagesFailed extends ChatState implements ChatError {
  final Failure failure;

  const MessagesFailed({required this.failure});

  @override
  List<Object> get props => [failure];

  @override
  Failure get error => failure;
}

class LastMessagesLoading extends ChatState {}

class LastMessagesSucceed extends ChatState {
  final List<LastMessage> messages;

  const LastMessagesSucceed({required this.messages});

  @override
  List<Object> get props => [messages];
}

class LastMessagesFailed extends ChatState {
  final Failure failure;

  const LastMessagesFailed({required this.failure});

  @override
  List<Object> get props => [failure];
}

class SendMessageLoading extends ChatState {}

class SendMessageSuccess extends ChatState {}

class SendNotificationLoading extends ChatState {}

class SendNotificationSuccess extends ChatState {}

class SendTemporaryMessageSucceed extends ChatState {}

class SendMessageError extends ChatState implements ChatError {
  final Failure failure;

  const SendMessageError({required this.failure});

  @override
  List<Object> get props => [failure];

  @override
  Failure get error => failure;
}

class SendNotificationError extends ChatState {
  final Failure failure;

  const SendNotificationError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class MarkMassgesAsReadLoading extends ChatState {}

class MarkMassgesAsReadSuccess extends ChatState {}

class MarkMassgesAsReadError extends ChatState implements ChatError {
  final Failure failure;

  const MarkMassgesAsReadError({required this.failure});

  @override
  List<Object> get props => [failure];

  @override
  Failure get error => failure;
}

class ChatError extends ChatState {
  final Failure error;

  const ChatError({required this.error});

  @override
  List<Object> get props => [error];
}

class UpdateValuesLoading extends ChatState {}

class UpdateValuesSucceed extends ChatState {}

class RecordingReseted extends ChatState {}

class PlayingStoped extends ChatState {}

class PlayingStarted extends ChatState {}
