import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

class UrgentMessageModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String? image;
  final bool isRead;
  final String? readAt;
  final int? childId;
  final String? childName;
  final String? senderName;
  final String? createdAt;

  const UrgentMessageModel({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.isRead = false,
    this.readAt,
    this.childId,
    this.childName,
    this.senderName,
    this.createdAt,
  });

  factory UrgentMessageModel.fromJson(Map<String, dynamic> json) {
    final child = validateDataModel(json['child'], (e) => e);
    final sender = validateDataModel(json['sender'], (e) => e);
    return UrgentMessageModel(
      id: validateInt(json['id']),
      title: validateString(json['title']),
      description: validateString(json['description']),
      image: validString(json['image']) ? json['image'] as String : null,
      isRead: validateBool(json['is_read']),
      readAt: validString(json['read_at']) ? json['read_at'] as String : null,
      childId: child != null ? validateInt(child['id']) : null,
      childName: child != null && validString(child['name']) ? child['name'] as String : null,
      senderName: sender != null && validString(sender['name']) ? sender['name'] as String : null,
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
    );
  }

  UrgentMessageModel copyWith({
    bool? isRead,
    String? readAt,
  }) =>
      UrgentMessageModel(
        id: id,
        title: title,
        description: description,
        image: image,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        childId: childId,
        childName: childName,
        senderName: senderName,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        image,
        isRead,
        readAt,
        childId,
        childName,
        senderName,
        createdAt,
      ];
}
