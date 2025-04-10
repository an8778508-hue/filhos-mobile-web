import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/my_app.dart';
import 'package:escola/flavors/app_flavors.dart';

abstract class ChatRepo {
  final String sendNotificationEndpoint = '/auth/chat';
  String get teachersEndpoint => mainKey.currentContext?.isParents == true?'parent/children/teachers':'teacher/children-teachers';
  final String usersCollection = 'chatUsers';
  final String messagesCollection = 'messages';
  final String contactsCollection = 'contacts';
  final String childrenGroupsCollection = 'childrenMessages';
  final String conversationsCollection = 'conversations';
  final String fieldTimestamp = 'timestamp';

  Future<Either<Failure, void>> sendMessage({required Message message});

  Future<Either<Failure, List<ChatUser>>> getRelatedTeachers({required int childId});

  Future<Either<Failure, void>> sendNotification({required Message message});

  Future<Either<Failure, void>> updateConversations(
      {required Message message, required bool isRead, required int unReadMessagesCount});

  Future<Either<Failure, void>> markMessageAsSeen({
    required String contactId,
    required String userId,
    required Message lastMessage,
  });

  Future<Either<Failure, Stream<QuerySnapshot<Map<String, dynamic>>>>> getMessages(
      {required String userId, required String? childId, required String contactId});

  Future<Either<Failure, Stream<QuerySnapshot<Map<String, dynamic>>>>> getLastMessages(String userId);
}
