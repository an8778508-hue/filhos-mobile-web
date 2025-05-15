import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:flutter/cupertino.dart';

class Message extends Equatable {
  final String id;
  final DateTime? dateTime;
  final int? timestamp;
  final String content;
  final MessageType? type;
  final ChatUser sender;
  final ChatUser reciever;
  final ChildModel? child;

  const Message({
    required this.id,
    required this.dateTime,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.sender,
    required this.reciever,
    required this.child,
  });

  @override
  List<Object?> get props => [id, dateTime, content, type, sender, reciever, timestamp, child];

  // toJson
  toJson() {
    final utcTime = dateTime?.toUtc();
    debugPrint('date time: $dateTime  timestamp: $timestamp content: $content  to utc time: $utcTime   to jsonnnn' );
    final utcTimeTimestamp = utcTime?.millisecondsSinceEpoch;
    return {
      'id': id,
      'dateTime': utcTime,
      'content': content,
      'type': type.toTypeString(),
      'timestamp': utcTimeTimestamp,
      'sender': sender.toJson(),
      'receiver': reciever.toJson(),
      "child": child?.toJson(),
    };
  }

  // fromJson
  factory Message.fromJson(Map<String, dynamic> json) {
    Timestamp firestoreTimestamp = json['dateTime'];
    // DateTime localTime = firestoreTimestamp.toDate().toLocal();
    DateTime utcTime = firestoreTimestamp.toDate();
    debugPrint('date time: ${firestoreTimestamp.toDate()}   content: ${json['content']}   to utc time: $utcTime  from jsonnnn ' );
    //todo
    return Message(
      id: json['id'].toString(),
      timestamp: json['timestamp'] == null
          ? null
          : json['timestamp'] is int
              ? json['timestamp']
              : json['timestamp'].toInt(),
      dateTime: utcTime,
      content: json['content'],
      type: json['type'].toString().toMessageType(),
      sender: ChatUser.fromJson(json['sender']),
      reciever: ChatUser.fromJson(json['receiver']),
      child: json['child'] == null ? null : ChildModel.fromJson(json['child']),
    );
  }

  // copy with
  Message copyWith({
    String? id,
    DateTime? dateTime,
    String? content,
    MessageType? type,
    ChatUser? sender,
    ChatUser? reciever,
    int? timestamp,
    ChildModel? child,
  }) {
    return Message(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      dateTime: dateTime ?? this.dateTime,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      reciever: reciever ?? this.reciever,
      child: child ?? this.child,
    );
  }
}

enum MessageType { text, audio, image, file }

extension FromStringToType on String? {
  MessageType toMessageType() {
    switch (this) {
      case 'text':
        return MessageType.text;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'image':
        return MessageType.image;
      default:
        return MessageType.text;
    }
  }
}

extension FromTypeToString on MessageType? {
  String toTypeString() {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.file:
        return 'file';
      case MessageType.audio:
        return 'audio';
      case MessageType.image:
        return 'image';
      default:
        return 'text';
    }
  }
}
