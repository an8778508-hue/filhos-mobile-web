import 'package:escola/core/utils/valid_data.dart';

class RegionModel {
  final String id;
  final String name;
  final String city_id;

  const RegionModel({
    required this.id,
    required this.name,
    required this.city_id,
  });

  factory RegionModel.fromJson(Map<String, dynamic> json) => RegionModel(
        id: validateString(json['id']?.toString()),
        name: validateString(json['name']?.toString()),
        city_id: validateString(json['city_id']?.toString()),
      );
}
