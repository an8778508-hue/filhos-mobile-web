part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class GetMessages extends ChatEvent {
  final ChatUser contact;
  final ChildModel? child;

  const GetMessages({
    required this.contact,
    required this.child,
  });

  @override
  List<Object> get props => [contact];
}

class GetChildTeachers extends ChatEvent {
  final ChildModel child;

  const GetChildTeachers({required this.child});

  @override
  List<Object> get props => [child];
}

class SendTextMessage extends ChatEvent {}

class SendImagesMessage extends ChatEvent {}

class MarkMessageAsSeen extends ChatEvent {
  final Message lastMessage;
  final String userId, contactId;

  const MarkMessageAsSeen({required this.lastMessage, required this.userId, required this.contactId});

  @override
  List<Object> get props => [lastMessage, userId, contactId];
}

class GetLastMessages extends ChatEvent {}

class GetParentChildren extends ChatEvent {}

class SendTemporaryMessages extends ChatEvent {
  final List<Message> messages;

  const SendTemporaryMessages({required this.messages});

  @override
  List<Object> get props => [messages];
}

class AddState extends ChatEvent {
  final ChatState state;

  const AddState({required this.state});

  @override
  List<Object> get props => [state];
}

class UpdateMessageContent extends ChatEvent {
  final String content;

  const UpdateMessageContent({required this.content});

  @override
  List<Object> get props => [content];
}

class AddImages extends ChatEvent {
  final List<XFile> images;

  const AddImages({required this.images});

  @override
  List<Object> get props => [images];
}

class DeleteImage extends ChatEvent {
  final int index;

  const DeleteImage({required this.index});

  @override
  List<Object> get props => [index];
}

class RemoveTemporaryMessages extends ChatEvent {
  final Message message;

  const RemoveTemporaryMessages({required this.message});

  @override
  List<Object> get props => [message];
}

class SendMessage extends ChatEvent {
  final Message message;

  const SendMessage({required this.message});

  @override
  List<Object> get props => [message];
}

class SendMessageNotification extends ChatEvent {
  final Message message;

  const SendMessageNotification({required this.message});

  @override
  List<Object> get props => [message];
}
