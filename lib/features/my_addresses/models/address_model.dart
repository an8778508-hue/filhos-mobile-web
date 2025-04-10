
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';

class AddressModel {
  final CityModel? cityModel;
  final RegionModel? regionModel;
  final CountryModel? countryModel;
  final String? id;
  final String? name;
  final String? country_id;
  final String? country;
  final String? city;
  final String? brazil_state_code;
  final String? area;
  final String? address;
  final String? zip_code;
  final String? complement;

  const AddressModel({
    required this.cityModel,
    required this.regionModel,
    required this.countryModel,
    required this.id,
    required this.name,
    required this.country_id,
    required this.country,
    required this.city,
    required this.brazil_state_code,
    required this.area,
    required this.address,
    required this.zip_code,
    required this.complement,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    cityModel: json?['state_model']==null ?null:CityModel.fromJson(validateMap(json['state_model'])),
    regionModel: json?['city_model']==null ?null:RegionModel.fromJson(validateMap(json['city_model'])),
    countryModel: json?['country_model']==null ?null:CountryModel.fromJson(validateMap(json?['country_model']??{})),
    id: validateString(json['id']?.toString()),
    name: validateString(json['name']?.toString()),
    country_id: validateString(json['country_id']?.toString()),
    country: validateString(json['country']?.toString()),
    city: validateString(json['city']?.toString()),
    brazil_state_code: validateString(json['brazil_state_code']?.toString()),
    area: validateString(json['area']?.toString()),
    address: validateString(json['address']?.toString()),
    zip_code: validateString(json['zip_code']?.toString()),
    complement: validateString(json['complete_address']?.toString()),
  );
}
