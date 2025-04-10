import 'package:escola/core/utils/valid_data.dart';

class TagModel {
  final int id;
  final String name;

  TagModel({
    required this.id,
    required this.name,
  });

  //from json
  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: validateInt(json['id']),
      name: validateString(json['name']),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
