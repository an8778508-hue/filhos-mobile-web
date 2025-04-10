import 'package:escola/core/models/announcements_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class AnnouncementsWithDateModel {
  final String id;
  final DateTime? date;
  final List<AnnouncementsModel> announcements;

  AnnouncementsWithDateModel({
    required this.id,
    required this.date,
    required this.announcements,
  });

  //from json
  factory AnnouncementsWithDateModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementsWithDateModel(
      id: validateString(json['id']),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      announcements: json['announcements'] != null
          ? (json['announcements'] as List).map((announcement) => AnnouncementsModel.fromJson(announcement)).toList()
          : [],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'announcements': announcements.map((announcement) => announcement.toJson()).toList(),
    };
  }
}
/*
{
    "data": [
        {
            "id": 3,
            "school_id": 1,
            "content": "Test Message 3",
            "send_to": [
                "parents"
            ],
            "class_id": null,
            "class": null,
            "attachments": [
                "https://escola.spotlayer.com/storage/announcement_attachments/2023-11-09_17-05-45_whatsapp-image-2023-11-05-at-43415-pmjpeg_589212.jpg"
            ],
            "created_from": "api",
            "creator": {
                "id": 86,
                "name": "Test teacher",
                "type": "teacher",
                "avatar": null
            },
            "receivers_count": 1,
            "sent_status": "successed"
        },
        {
            "id": 2,
            "school_id": 1,
            "content": "Test Message 2",
            "send_to": [
                "parents"
            ],
            "class_id": null,
            "class": null,
            "attachments": [],
            "created_from": "api",
            "creator": {
                "id": 86,
                "name": "Test teacher",
                "type": "teacher",
                "avatar": null
            },
            "receivers_count": 1,
            "sent_status": "successed"
        },
        {
            "id": 1,
            "school_id": 1,
            "content": "Test Message",
            "send_to": [
                "parents"
            ],
            "class_id": null,
            "class": null,
            "attachments": [],
            "created_from": "api",
            "creator": {
                "id": 86,
                "name": "Test teacher",
                "type": "teacher",
                "avatar": null
            },
            "receivers_count": 1,
            "sent_status": "successed"
        }
    ],
    "message": "DataSent",
    "statusCode": 200
}
*/