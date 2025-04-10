import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/chat/data_sources/chat_repository.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/professor_contacts.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepo chatRepo;
  final LocalDatabaseRepo localDatabase;
  final MyChildrenRepo myChildrenRepo;

  List<Message> messages = [];
  List<LastMessage> lastMessages = [];
  List<ChatUser> relatedTeachers = [];
  List<ChildModel> parentChildren = [];

  ChatUser? currentUser;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? messagesSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lastmessagesSubscription;

  int unReadMessagesCount = 0;

  ChatBloc({required this.chatRepo, required this.localDatabase, required this.myChildrenRepo}) : super(ChatInitial()) {
    on<ChatEvent>((event, emit) async {
      if (event is GetMessages) {
        await _getMessages(event, emit);
      } else if (event is MarkMessageAsSeen) {
        await _markMessageAsSeen(event, emit);
      } else if (event is GetLastMessages) {
        await _getLastMessages(event, emit);
      } else if (event is AddState) {
        emit(event.state);
      } else if (event is SendTemporaryMessages) {
        emit(UpdateValuesLoading());
        messages.addAll(event.messages);
        emit(SendTemporaryMessageSucceed());
      } else if (event is RemoveTemporaryMessages) {
        emit(UpdateValuesLoading());
        messages.remove(event.message);
        emit(UpdateValuesSucceed());
      } else if (event is SendMessage) {
        await _sendMessage(event, emit);
      } else if (event is SendMessageNotification) {
        await _sendMessageNotification(event, emit);
      } else if (event is GetParentChildren) {
        await _getParentChildren(event, emit);
      } else if (event is GetChildTeachers) {
        await _getChildTeachers(event, emit);
      }
    });
  }

  // getChildTeachers
  Future<void> _getChildTeachers(GetChildTeachers event, Emitter<ChatState> emit) async {
    relatedTeachers = [];
    emit(TeachersLoading());
    final result = await chatRepo.getRelatedTeachers(childId: event.child.id);
    return result.fold(
      (l) => emit(MessagesFailed(failure: l)),
      (teachers) {
        print('ChatBloc._getChildTeachers ${teachers}');
        relatedTeachers = teachers;
        emit(TeachersSucceed(teachers: teachers));
      },
    );
  }

  // get Parent children
  Future<void> _getParentChildren(GetParentChildren event, Emitter<ChatState> emit) async {
    if (mainKey.currentContext!.isParents) {
      emit(ChildrenLoading());
      final result = await myChildrenRepo.getChildren(1);
      return result.fold(
        (l) => emit(ChildrenFailed(failure: l)),
        (children) {
          parentChildren = children;
          emit(ChildrenSucceed(filteredChildren: getChildrenWithNoMessages(children)));
        },
      );
    }
  }

  List<ChildModel> getChildrenWithNoMessages(List<ChildModel> children) {
    final filteredChildren = children.where((element) => !lastMessages.any((e) => e.message.child?.id == element.id));
    return filteredChildren.toList();
  }

  // send notification
  Future<void> _sendMessageNotification(SendMessageNotification event, Emitter<ChatState> emit) async {
    emit(SendNotificationLoading());

    final result = await chatRepo.sendNotification(message: event.message);
    return result.fold((l) => SendNotificationError(failure: l), (r) => emit(SendNotificationSuccess()));
  }

  Future<void> _sendMessage(SendMessage event, Emitter<ChatState> emit) async {
    final senderType = event.message.sender.type;

    if (event.message.child != null) {
      if (senderType == UserType.parent) {
        await _sendToRelatedTeachers(event, emit);
      } else {
        final parent = event.message.child!.parent;
        if (parent != null) {
        print('ChatBloc._sendMessage      3 ${parent}');
          await _sendSingleMessage(event.message.copyWith(reciever: ChatUser.fromUserModel(parent)), emit);
        }
        await _sendToRelatedTeachers(event, emit);
      }
    } else {
      await _sendToRelatedTeachers(event, emit);
    }
  }

  Future<void> _sendToRelatedTeachers(SendMessage event, Emitter<ChatState> emit) async {
    final child = event.message.child;
    final sender = event.message.sender;
    final senderType = event.message.sender.type;

    if (child != null && relatedTeachers.isNotEmpty) {
      await Future.wait(
        relatedTeachers.map((e) async {
          final message = event.message.copyWith(reciever: e);
          if (sender.id != e.id ||senderType == UserType.parent) {
            await _sendSingleMessage(message, emit);
          }
        }).toList(),
      );
    }
  }

  Future<void> _sendSingleMessage(Message message, Emitter<ChatState> emit) async {
    emit(SendMessageLoading());
    final result = await chatRepo.sendMessage(message: message);
    return result.fold((l) {
      add(RemoveTemporaryMessages(message: message));
      emit(SendMessageError(failure: l));
    }, (r) {
      emit(SendMessageSuccess());
      add(SendMessageNotification(message: message));
    });
  }

  // mark as seen
  Future<void> _markMessageAsSeen(MarkMessageAsSeen event, Emitter<ChatState> emit) async {
    if (messages.isNotEmpty) {
      emit(MarkMassgesAsReadLoading());
      final String? childId = event.lastMessage.child == null ? null : event.lastMessage.child!.id.toString();

      final result = await chatRepo.markMessageAsSeen(
        lastMessage: event.lastMessage,
        userId: event.userId,
        contactId: childId ?? event.contactId,
      );
      result.fold(
        (l) => emit(MarkMassgesAsReadError(failure: l)),
        (r) => emit(MarkMassgesAsReadSuccess()),
      );
    }
  }

  //get last Messages
  Future<void> _getLastMessages(GetLastMessages event, Emitter<ChatState> emit) async {
    lastMessages = [];

    currentUser = await getCurrentUser();
    if (currentUser == null) return;

    emit(LastMessagesLoading());

    final messagesStreamResult = await chatRepo.getLastMessages(currentUser!.id);

    return messagesStreamResult.fold(
      (l) => emit(LastMessagesFailed(failure: l)),
      (r) => _listenToLastMessages(r, emit),
    );
  }

  // list to last Messages
  _listenToLastMessages(Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream, Emitter<ChatState> emit) async {
    await _lastmessagesSubscription?.cancel();

    _lastmessagesSubscription = messagesStream.listen((event) async {
      try {
        final loadedMessages = event.docs.map((e) => LastMessage.fromJson(e.data())).toList();

        lastMessages = loadedMessages;
        setUnReadMessagesCount(lastMessages);
        final filterdChildren = getChildrenWithNoMessages(parentChildren);
        add(AddState(state: ChildrenSucceed(filteredChildren: filterdChildren)));
        add(AddState(state: LastMessagesSucceed(messages: loadedMessages)));
      } catch (e, s) {
        debugPrint("error: $e $s");
        add(AddState(state: LastMessagesFailed(failure: ServerFailure(message: e.toString()))));
      }
    });
    return _lastmessagesSubscription;
  }

  void setUnReadMessagesCount(List<LastMessage> messagesParameters) {
    unReadMessagesCount = 0;
    for (var i = 0; i < messagesParameters.length; i++) {
      final lastMessage = messagesParameters[i];
      unReadMessagesCount += lastMessage.unReadCount ?? 0;
    }
  }

  // get Messages between two users
  _getMessages(GetMessages event, Emitter<ChatState> emit) async {
    try {
      messages = [];
      currentUser = await getCurrentUser();
      if (currentUser == null) return;
      emit(MessagesLoading());

      final messagesStreamResult = await chatRepo.getMessages(
        childId: event.child == null ? null : event.child!.id.toString(),
        userId: currentUser!.id,
        contactId: event.contact.id,
      );

      return messagesStreamResult.fold(
        (l) => emit(MessagesFailed(failure: l)),
        (r) async {
          await _listenToMessages(event, r, emit);
        },
      );
    } catch (e, s) {
      debugPrint("error$e");
      debugPrint("stack$s");

      emit(const MessagesFailed(failure: ServerFailure(message: "Failed to load messages")));
    }
  }

  // listen to messages
  _listenToMessages(GetMessages getMessagesEvent, Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream,
      Emitter<ChatState> emit) async {
    await messagesSubscription?.cancel();

    messagesSubscription = messagesStream.listen((event) {
      try {
        final loadedMessages = event.docs.map((e) => Message.fromJson(e.data())).toList();
        messages = loadedMessages;

        add(AddState(state: MessagesLoaded(messages: messages)));

        _callMarkMessagesAsSeen(getMessagesEvent, currentUser!.id, getMessagesEvent.contact.id);
      } catch (e, s) {
        debugPrint("error: $e $s");

        add(AddState(state: MessagesFailed(failure: ServerFailure(message: e.toString()))));
      }
    });
    return messagesSubscription;
  }

  _callMarkMessagesAsSeen(GetMessages getMessagesEvent, String userId, String contactId) {
    if (messages.isNotEmpty) {
      add(MarkMessageAsSeen(lastMessage: messages.last, userId: userId, contactId: contactId));
    }
  }

  Future<ChatUser?> getCurrentUser() async {
    // final user = await localDatabase.getUser();
    final user = UserBloc.get.state.user;
    if (user != null) {
      return ChatUser.fromUserModel(user);
    }
    return null;
  }

  List<LastMessage> getLastMessagesGroup(GroupType groupType) {
    final List<LastMessage> professorsMessages = [];
    final List<LastMessage> parentMessages = [];

    for (var i = 0; i < lastMessages.length; i++) {
      final message = lastMessages[i].message;
      final contact = message.sender.id == currentUser?.id ? message.reciever : message.sender;
      if (contact.type == UserType.professor && message.child == null) {
        professorsMessages.add(lastMessages[i]);
      } else {
        parentMessages.add(lastMessages[i]);
      }
    }
    if (groupType == GroupType.internals) {
      return professorsMessages;
    } else {
      return parentMessages;
    }
  }

  static String? getContactFullName(BuildContext context, ChatUser? contact, String? childName) {
    String? name = (childName ?? contact?.name);

    String nameDescription =
        context.isParents ? LocalizationKeys.teachers.tr(context) : LocalizationKeys.parent.tr(context);

    final String? fullName = childName != null ? "$name $nameDescription" : name;

    return fullName;
  }

  @override
  Future<void> close() async {
    messagesSubscription?.cancel();
    _lastmessagesSubscription?.cancel();
    return super.close();
  }
}
