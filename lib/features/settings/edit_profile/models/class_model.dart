
import 'package:escola/core/utils/valid_data.dart';

class ClassModel {
  final String id;
  final String name;

  const ClassModel({
    required this.id,
    required this.name,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
    id: validateString(json['id'].toString()),
    name: validateString(json['name']),
  );

  toJson(){
    return {
      'id':id,
      'name':name,
    };
  }
}
