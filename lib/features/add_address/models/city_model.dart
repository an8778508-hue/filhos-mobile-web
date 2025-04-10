
import 'package:escola/core/utils/valid_data.dart';

class CityModel {
  final String id;
  final String name;
  final String country_id;

  const CityModel({
    required this.id,
    required this.name,
    required this.country_id,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    id: validateString(json['id']?.toString()),
    name: validateString(json['name']?.toString()),
    country_id: validateString(json['country_id']?.toString()),
  );
}
