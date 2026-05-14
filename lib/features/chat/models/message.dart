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

  // toJson — uses Firestore's serverTimestamp sentinel so ordering doesn't
  // depend on the client clock. Pass [forServer]: true on write paths to opt
  // into the server timestamp; pass false (or omit) for local previews.
  Map<String, dynamic> toJson({bool forServer = true}) {
    final utcTime = dateTime?.toUtc();
    return {
      'id': id,
      'dateTime': forServer ? FieldValue.serverTimestamp() : utcTime,
      'content': content,
      'type': type.toTypeString(),
      // Numeric timestamp kept for back-compat with old readers; the
      // server-side `dateTime` is the authority for ordering.
      'timestamp': utcTime?.millisecondsSinceEpoch,
      'sender': sender.toJson(),
      'receiver': reciever.toJson(),
      "child": child?.toJson(),
    };
  }

  // fromJson — tolerant: a single doc with a missing/wrong `dateTime` must
  // not blank the entire conversation. Falls back to numeric `timestamp`
  // then to "now" so the message renders at least somewhere.
  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime? localTime;
    final raw = json['dateTime'];
    if (raw is Timestamp) {
      localTime = raw.toDate().toLocal();
    } else if (raw is DateTime) {
      localTime = raw.toLocal();
    } else if (raw is int) {
      localTime = DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    } else if (json['timestamp'] is int) {
      localTime = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int).toLocal();
    }

    int? ts;
    final rawTs = json['timestamp'];
    if (rawTs is int) {
      ts = rawTs;
    } else if (rawTs is num) {
      ts = rawTs.toInt();
    } else if (localTime != null) {
      ts = localTime.toUtc().millisecondsSinceEpoch;
    }

    return Message(
      id: json['id']?.toString() ?? '',
      timestamp: ts,
      dateTime: localTime,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString().toMessageType() ?? MessageType.text,
      sender: ChatUser.fromJson(_asMap(json['sender'])),
      reciever: ChatUser.fromJson(_asMap(json['receiver'])),
      child: json['child'] is Map<String, dynamic>
          ? ChildModel.fromJson(json['child'] as Map<String, dynamic>)
          : null,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};

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
