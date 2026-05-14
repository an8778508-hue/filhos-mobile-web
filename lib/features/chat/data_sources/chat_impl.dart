import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/exceptions.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/chat/data_sources/chat_repository.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';

/// Cap on initial messages stream — protects against unbounded reads on long
/// conversations. UI pagination can request more if needed.
const int _messagesPageSize = 50;

class ChatImpl extends ChatRepo {
  final NetworkClientRepository networkClient;

  ChatImpl({required this.networkClient});
  @override
  Future<Either<Failure, void>> sendMessage({
    required Message message,
  }) async {
    return await arrangeRequestResult(
      request: () async {
        final fs = FirebaseFirestore.instance;
        final String? childId = message.child?.id.toString();

        final senderUser = _getChatUserById(id: message.sender.id);
        final receiverUser = _getChatUserById(id: message.reciever.id);

        final senderReciverDocument = _getContactDocument(message.sender.id, childId ?? message.reciever.id);
        final reciverSenderDocument = _getContactDocument(message.reciever.id, childId ?? message.sender.id);

        final messageJson = message.toJson(); // server timestamp on `dateTime`

        // Sender's last-message doc: read by the sender, so isRead=true.
        final senderLastMessage = {
          'message': messageJson,
          'isRead': true,
          'unReadCount': 0,
        };

        // Receiver's last-message doc: increment unread atomically rather
        // than read-then-write — two near-simultaneous sends would otherwise
        // both compute the same count and one increment would be lost.
        final receiverLastMessageBase = {
          'message': messageJson,
          'isRead': false,
          'unReadCount': FieldValue.increment(1),
        };

        // All writes go through a WriteBatch so a network failure between
        // steps cannot leave the contact list and message collection
        // out of sync.
        final batch = fs.batch();
        batch.set(senderUser, message.sender.toJson(), SetOptions(merge: true));
        batch.set(receiverUser, message.reciever.toJson(), SetOptions(merge: true));
        batch.set(senderReciverDocument, senderLastMessage);
        batch.set(reciverSenderDocument, receiverLastMessageBase, SetOptions(merge: true));

        if (childId == null) {
          batch.set(_messageDoc(senderReciverDocument, message), messageJson);
          batch.set(_messageDoc(reciverSenderDocument, message), messageJson);
        } else {
          final childDoc = fs
              .collection(childrenGroupsCollection)
              .doc(childId)
              .collection(messagesCollection)
              .doc(message.id.isNotEmpty ? message.id : null); // auto-id when none provided
          batch.set(childDoc, messageJson);
        }

        await batch.commit();
      },
      errorText: "Failed to send Message",
    );
  }

  DocumentReference<Map<String, dynamic>> _messageDoc(
    DocumentReference<Map<String, dynamic>> contact,
    Message message,
  ) {
    // Prefer a stable client-supplied id; fall back to auto-id from Firestore
    // so two messages in the same millisecond cannot overwrite each other.
    final col = contact.collection(messagesCollection);
    return message.id.isNotEmpty ? col.doc(message.id) : col.doc();
  }

  @override
  Future<Either<Failure, void>> markMessageAsSeen({
    required String contactId,
    required String userId,
    required Message lastMessage,
  }) async {
    debugPrint('mark messages as seen:  5555555555555555555555 ${lastMessage.toJson()} eeeend');
    // if (lastMessage.sender.id == userId) return Right(() {
    //   debugPrint('mark messages as seen:  666666666666666666666666666666666 ${lastMessage.toJson()} eeeend');
    // });

    return await arrangeRequestResult(
      request: () async {
        debugPrint('mark messages as seen:  222222222222222222222 ${lastMessage.toJson()} eeeend');
        // sender receiver document
        final String? childId = lastMessage.child?.id.toString();
        final userContactDocument = _getContactDocument(userId, childId ?? contactId);
        final lastMessageData = LastMessage(message: lastMessage, isRead: true, unReadCount: 0);
        await userContactDocument.set(lastMessageData.toJson());
        // await updateConversations(message: lastMessage, isRead: true, unReadMessagesCount: 0);
      },
      errorText: "Failed to mark Messages as seen",
    );
  }

  @override
  Future<Either<Failure, void>> updateConversations(
      {required Message message, required bool isRead, required int unReadMessagesCount}) async {
    return await arrangeRequestResult(
      request: () async {
        // Lexicographic compare is UUID-safe; int.parse would crash if the
        // backend ever issues non-numeric user ids.
        final ids = [message.sender.id, message.reciever.id]..sort();
        final conversationId = '${ids.first}-${ids.last}';

        final conversationDoc = FirebaseFirestore.instance.collection(conversationsCollection).doc(conversationId);

        final lastMessageData = LastMessage(message: message, isRead: isRead, unReadCount: unReadMessagesCount);

        await conversationDoc.set(lastMessageData.toJson());

        final messageDoc = _messageDoc(conversationDoc, message);
        await messageDoc.set(message.toJson());
      },
      errorText: "Failed to update Conversations",
    );
  }

  @override
  Future<Either<Failure, Stream<QuerySnapshot<Map<String, dynamic>>>>> getMessages(
      {required String userId, required String? childId, required String contactId}) async {
    return await arrangeRequestResult(
      request: () async {
        // Order by `timestamp` (numeric millis, written by the sender on every
        // message) and cap at the most recent N. Without this the stream
        // returned the whole collection in undefined order — both an ordering
        // bug and a cost bug on long conversations.
        final base = childId != null
            ? FirebaseFirestore.instance
                .collection(childrenGroupsCollection)
                .doc(childId)
                .collection(messagesCollection)
            : FirebaseFirestore.instance
                .collection(usersCollection)
                .doc(userId)
                .collection(contactsCollection)
                .doc(contactId)
                .collection(messagesCollection);

        return base
            .orderBy('timestamp', descending: true)
            .limit(_messagesPageSize)
            .snapshots();
      },
      errorText: "Failed to get Messages",
    );
  }

  @override
  Future<Either<Failure, Stream<QuerySnapshot<Map<String, dynamic>>>>> getLastMessages(String userId) async {
    return await arrangeRequestResult(
      request: () {
        final lastMessagesStream = FirebaseFirestore.instance
            .collection(usersCollection)
            .doc(userId)
            .collection(contactsCollection)
            .orderBy("message.timestamp", descending: true)
            .snapshots();

        return lastMessagesStream;
      },
      errorText: "Failed to get last Messages",
    );
  }

  @override
  Future<Either<Failure, void>> sendNotification({required Message message}) async {
    final body = {
      "receiver_id": message.reciever.id,
      "data": {
        "type": "chat",
        "sender": message.sender.toJson(),
        if (message.child != null) "child": message.child!.toJson(),
      },
      "title": message.sender.name,
      "message": getMessageContent(message),
    };
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.post, url: sendNotificationEndpoint, body: body),
    );
  }

  String getMessageContent(Message message) {
    final isVideo = ChatHelper.isVideoFile(message.content);

    return message.type == MessageType.audio
        ? "Audio"
        : message.type == MessageType.image
            ? Platform.isAndroid
                ? ""
                : "Image"
            : isVideo
                ? "Video"
                : message.type == MessageType.file
                    ? "File"
                    : message.content;
  }

  DocumentReference<Map<String, dynamic>> _getChatUserById({required String id}) {
    final chatUser = FirebaseFirestore.instance.collection(usersCollection).doc(id);

    return chatUser;
  }

  DocumentReference<Map<String, dynamic>> _getContactDocument(
    String firstId,
    String secondId,
  ) {
    final contact = FirebaseFirestore.instance
        .collection(usersCollection)
        .doc(firstId.toString())
        .collection(contactsCollection)
        .doc(secondId.toString());
    return contact;
  }

  Future<Either<Failure, T>> arrangeRequestResult<T>({
    required Function request,
    String? errorText,
  }) async {
    try {
      final result = await request();

      return Right(result);
    } catch (e, s) {
      debugPrint("error: $e");
      debugPrint("stack: $s");

      return Left(ServerFailure(message: errorText ?? "Server Error, please contact us"));
    }
  }

  @override
  Future<Either<Failure, List<ChatUser>>> getRelatedTeachers({required int childId}) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: teachersEndpoint,
        queryParameters: {"child_id": childId.toString()},
      ),
      onSuccess: (date) {
        // Role from the authenticated user — never from a global widget key,
        // which can be null in background isolates / early boot.
        final isParents = UserBloc.get.state.user?.type == UserType.parent;
        final list = isParents ? date['data'][0]['teachers'] : date['data'];
        final teachers = (list as List).map((e) => UserModel.fromJson(e)).toList();
        if (teachers.isEmpty) {
          throw ServerException(
              message: LocalizationKeys.no_teachers_for_this_child_yet.tr(navigatorKey.currentContext!));
        }
        return teachers.map((e) => ChatUser.fromUserModel(e)).toList();
      },
    );
  }
}
