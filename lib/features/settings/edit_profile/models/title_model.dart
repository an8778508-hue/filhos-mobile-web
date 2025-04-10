
import 'package:escola/core/utils/valid_data.dart';

class TitleModel {
  final String id;
  final String name;

  const TitleModel({
    required this.id,
    required this.name,
  });

  factory TitleModel.fromJson(Map<String, dynamic> json) => TitleModel(
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
