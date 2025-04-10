import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TextMessageBloc extends Bloc<ChatEvent, ChatState> {
  final ChatUser? contactUser;
  final ChatBloc chatBloc;
  final ChildModel? child;

  String? content;
  TextEditingController controller = TextEditingController();
  TextMessageBloc({
    required this.chatBloc,
    required this.child,
    required this.contactUser,
  }) : super(ChatInitial()) {
    on<ChatEvent>((event, emit) async {
      if (event is UpdateMessageContent) {
        emit(UpdateValuesLoading());
        content = event.content;
        controller.text = event.content;
        emit(UpdateValuesSucceed());
      } else if (event is SendTextMessage) {
        emit(UpdateValuesLoading());
        controller.clear();
        emit(UpdateValuesSucceed());
        if (stringNotNullOrEmpty(content) && chatBloc.currentUser != null && contactUser != null) {
          final message = await ChatHelper.buildMessageFromContent(
              content: content!,
              sender: chatBloc.currentUser!,
              reciever: contactUser!,
              child: child,
              type: MessageType.text);
          chatBloc.add(SendTemporaryMessages(messages: [message]));
          chatBloc.add(SendMessage(message: message));
        }
      }
    });
  }
}
