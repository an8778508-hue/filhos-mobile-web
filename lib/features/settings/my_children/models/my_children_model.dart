
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';

class AddressModel {
  final CityModel? cityModel;
  final RegionModel? regionModel;
  final AreaModel? areaModel;
  final String address;
  final String street;
  final String phone_number;
  final String zip_code;

  const AddressModel({
    required this.address,
    required this.cityModel,
    required this.regionModel,
    required this.areaModel,
    required this.street,
    required this.phone_number,
    required this.zip_code,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    cityModel: CityModel.fromJson(validateMap(json)),
    regionModel: RegionModel.fromJson(validateMap(json)),
    areaModel: AreaModel.fromJson(validateMap(json)),
    address: validateString(json['address']?.toString()),
    street: validateString(json['street']?.toString()),
    phone_number: validateString(json['phone_number']?.toString()),
    zip_code: validateString(json['zip_code']?.toString()),
  );
}
