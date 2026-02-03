
import 'package:escola/core/utils/valid_data.dart';

class AboutModel {
  final String content;
  final String email;
  final String phone;

  const AboutModel({
    required this.content,
    required this.email,
    required this.phone,
  });

  factory AboutModel.fromJson(Map<String, dynamic> json) => AboutModel(
    content: validateString(json['content']?.toString()),
    email: validateString(json['email']?.toString()),
    phone: validateString(json['phone']?.toString()),
  );
}
