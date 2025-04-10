
import 'package:escola/core/utils/valid_data.dart';

class EmailModel {
  final String id;
  final String email;

  const EmailModel({
    required this.id,
    required this.email,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) => EmailModel(
    id: validateString(json['id'].toString()),
    email: validateString(json['email']),
  );
  toJson(){
    return {
      'id':id,
      'email':email,
    };
  }
}
