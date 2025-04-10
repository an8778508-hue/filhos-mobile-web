import 'package:escola/core/utils/valid_data.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool requireApproval;
  final bool teacherAllowActions;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.requireApproval,
    required this.teacherAllowActions,
  });

  //from json
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: validateString(json['id'].toString()),
      title: validateString(json['title']),
      description: validateString(json['description']),
      imageUrl: validateString(json['image']),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      requireApproval: isSuccess(json['has_approval']) && isSuccess(json['approved']),
      teacherAllowActions: isSuccess(json['teacher_allow_actions']),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'start_date': startDate,
      'end_date': endDate,
      'require_approval': requireApproval,
      'teacher_allow_actions': teacherAllowActions,
    };
  }
}
