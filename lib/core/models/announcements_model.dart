import 'package:escola/core/models/tag_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class AnnouncementsModel {
  final String id;
  final String title;
  final String content;
  final String ?image;
  final DateTime? date;
  final List<TagModel?>? tags;
  final List<String> attachments;

  AnnouncementsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.tags,
    required this.attachments,
    this.image,
  });

  //from json
  factory AnnouncementsModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementsModel(
      id: validateString(json['id'].toString()),
      title: validateString(json['title']),
      content: validateString(json['content']),
      date: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      image: json['image'],
      tags: json['tags']== null ?[]:List<TagModel>.from(json['tags']?.map((x) => TagModel.fromJson(x))),
      attachments:json['attachments']== null?[]: List<String>.from(json['attachments']?.map((x) => x)) ?? [],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'tags': tags,
    };
  }
}
