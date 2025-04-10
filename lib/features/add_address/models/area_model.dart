import 'package:escola/core/utils/valid_data.dart';

class AreaModel {
  final String id;
  final String value;
  final String name;
  final String code;
  final String phone_code;
  final String emoji_u;
  final String emoji_image;

  const AreaModel({
    required this.id,
    required this.value,
    required this.name,
    required this.code,
    required this.phone_code,
    required this.emoji_u,
    required this.emoji_image,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
        id: validateString(json['id']?.toString()),
        value: validateString(json['value']?.toString()),
        name: validateString(json['name']?.toString()),
        code: validateString(json['code']?.toString()),
        phone_code: validateString(json['phone_code']?.toString()),
        emoji_u: validateString(json['emoji_u']?.toString()),
        emoji_image: validateString(json['emoji_image']?.toString()),
      );
}
