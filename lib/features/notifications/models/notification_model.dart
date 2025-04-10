import 'package:escola/core/utils/valid_data.dart';

class NotificationModel {
  final String id;
  final String title;
  final String image;
  final String body;
  final String? read;
  final String? notified;
  final String? eventable_id;
  final String? eventable_type;
  final DateTime? date;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.image,
    required this.body,
    this.date,
    this.read,
    this.notified,
    this.eventable_id,
    this.eventable_type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: validateString(json['id']?.toString()),
        date: validString(json['date']?.toString()) ? DateTime.parse(json['date']) : null,
        title: validateString(json['title']?.toString()),
        image: validateString(json['image']?.toString()),
        body: validateString(json['body']?.toString()),
        read: validateString(json['read']?.toString()),
        notified: validateString(json['notified']?.toString()),
        eventable_id: validateString(json['eventable_id']?.toString()),
        eventable_type: validateString(json['eventable_type']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date,
        "title": title,
        "image": image,
        "body": body,
        "read": read,
        "notified": notified,
        "eventable_id": eventable_id,
        "eventable_type": eventable_type,
      };
}
