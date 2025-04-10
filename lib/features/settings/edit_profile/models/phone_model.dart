
import 'package:escola/core/utils/valid_data.dart';

class PhoneModel {
  final String id;
  final String number;

  const PhoneModel({
    required this.id,
    required this.number,
  });

  factory PhoneModel.fromJson(Map<String, dynamic> json) => PhoneModel(
    id: validateString(json['id'].toString()),
    number: validateString(json['number']),
  );

  toJson(){
    return {
      'id':id,
      'number':number,
    };
  }
}
