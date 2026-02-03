import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/exceptions.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/chat/data_sources/chat_repository.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';

class ChatImpl extends ChatRepo {
  final NetworkClientRepository networkClient;

  ChatImpl({required this.networkClient});
  @override
  Future<Either<Failure, void>> sendMessage({
    required Message message,
  }) async {
    return await arrangeRequestResult(
      request: () async {
        final String? childId = message.child?.id.toString();

        // sender user document
        final senderUser = _getChatUserById(id: message.sender.id);

        // receiver user document
        final receiverUser = _getChatUserById(id: message.reciever.id);

        // set data to sender user document
        await senderUser.set(message.sender.toJson());
        debugPrint('receiver useeeeeeeeeeeeeeer: ${message.reciever.toJson()}');

        // set data to receiver user document
        await receiverUser.set(message.reciever.toJson());

        // sender receiver document
        final senderReciverDocument = _getContactDocument(message.sender.id, childId ?? message.reciever.id);

        // receiver sender document
        final reciverSenderDocument = _getContactDocument(message.reciever.id, childId ?? message.sender.id);

        // set last Message to receiver-sender document
        final lastMessageData = (await reciverSenderDocument.get()).data();
        final LastMessage? lastMessage = lastMessageData == null ? null : LastMessage.fromJson(lastMessageData);

        final unReadMessagesCount = lastMessage?.unReadCount ?? 0;

        final recieverLastMessage = LastMessage(message: message, isRead: false, unReadCount: unReadMessagesCount + 1);

        await reciverSenderDocument.set(recieverLastMessage.toJson());

        // set last Message to sender-receiver document
        final senderLastMessage = LastMessage(message: message, isRead: true, unReadCount: 0);

        await senderReciverDocument.set(senderLastMessage.toJson());

        // check if message has child
        // if message has child then set message to child group
        // else set message to sender and receiver messages collection
        if (childId == null) {
          // set message to sender Messages collection
          await _setMessageToMessagesCollection(document: senderReciverDocument, message: message);

          // set message to receiver Messages collection
          await _setMessageToMessagesCollection(document: reciverSenderDocument, message: message);
        } else {
          // set message children collection
          await _setMessageToChildrenCollection(message: message);
        }

        // // update conversation
        // await updateConversations(message: message, isRead: false, unReadMessagesCount: unReadMessagesCount + 1);
      },
      errorText: "Failed to send Message",
    );
  }

  Future _setMessageToChildrenCollection({required Message message}) async {
    final document = FirebaseFirestore.instance
        .collection(childrenGroupsCollection)
        .doc(message.child!.id.toString())
        .collection(messagesCollection)
        .doc(message.timestamp.toString());

    await document.set(message.toJson());
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
        final int senderId = int.parse(message.sender.id);
        final int recieverId = int.parse(message.reciever.id);

        final conversationId = senderId < recieverId
            ? '${message.sender.id}-${message.reciever.id}'
            : '${message.reciever.id}-${message.sender.id}';

        final conversationDoc = FirebaseFirestore.instance.collection(conversationsCollection).doc(conversationId);

        final lastMessageData = LastMessage(message: message, isRead: isRead, unReadCount: unReadMessagesCount);

        conversationDoc.set(lastMessageData.toJson());

        final timeInMillis = _getTimeInMillis(message);

        await conversationDoc.collection(messagesCollection).doc(timeInMillis).set(message.toJson());
      },
      errorText: "Failed to update Conversations",
    );
  }

  @override
  Future<Either<Failure, Stream<QuerySnapshot<Map<String, dynamic>>>>> getMessages(
      {required String userId, required String? childId, required String contactId}) async {
    return await arrangeRequestResult(
      request: () async {
        if (childId != null) {
          final childGroupStream = FirebaseFirestore.instance
              .collection(childrenGroupsCollection)
              .doc(childId)
              .collection(messagesCollection)
              .snapshots();
          return childGroupStream;
        } else {
          final messagesStream = FirebaseFirestore.instance
              .collection(usersCollection)
              .doc(userId)
              .collection(contactsCollection)
              .doc(childId ?? contactId)
              .collection(messagesCollection)
              .snapshots();
          return messagesStream;
        }
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

  Future<void> _setMessageToMessagesCollection({required DocumentReference document, required Message message}) async {
    final timeInMillis = _getTimeInMillis(message);
    debugPrint("timeInMillis: $timeInMillis");
    await document.collection(messagesCollection).doc(timeInMillis).set(message.toJson());
  }

  String _getTimeInMillis(Message message) {
    final timeInMillis = message.timestamp ?? (DateTime.now()).millisecondsSinceEpoch;

    return timeInMillis.toString();
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
        debugPrint("dateeeeeeeeee: ${date['data']}");
        if(date['data'].isEmpty) throw ServerException(message: LocalizationKeys.no_teachers_for_this_child_yet.tr(navigatorKey.currentContext!));
        final list = mainKey.currentContext?.isParents == true ?date['data'][0]['teachers']:date['data'];
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
