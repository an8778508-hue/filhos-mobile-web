import 'package:equatable/equatable.dart';
import 'package:escola/features/chat/models/message.dart';

class LastMessage extends Equatable {
  final Message message;
  final bool isRead;
  final int? unReadCount;

  const LastMessage(
      {required this.message, required this.unReadCount, required this.isRead});

  // to Json
  toJson() {
    return {
      'message': message.toJson(),
      'isRead': isRead,
      'unReadCount': unReadCount ?? 0,
    };
  }

  // from Json
  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      unReadCount: json['unReadCount'] ?? 0,
      message: Message.fromJson(json['message']),
      isRead: json['isRead'],
    );
  }

  @override
  List<Object?> get props => [message, isRead, unReadCount];
}
