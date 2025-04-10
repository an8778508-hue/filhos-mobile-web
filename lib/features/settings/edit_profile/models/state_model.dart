
import 'package:escola/core/utils/valid_data.dart';

class StateModel {
  final String id;
  final String name;

  const StateModel({
    required this.id,
    required this.name,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) => StateModel(
    id: validateString(json['id'].toString()),
    name: validateString(json['name']),
  );
}
