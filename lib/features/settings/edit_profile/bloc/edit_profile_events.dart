import 'dart:io';

import 'package:escola/features/add_address/bloc/add_address_events.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

@immutable
abstract class EditProfileEvents {
  const EditProfileEvents();
}

class SelectCountry extends EditProfileEvents {
  final AreaModel country;

  const SelectCountry(this.country);
}

class SelectCity extends EditProfileEvents {
  final CityModel city;

  const SelectCity(this.city);
}

class SelectRegion extends EditProfileEvents {
  final RegionModel region;

  const SelectRegion(this.region);
}

class SubmitEditProfileEvent extends EditProfileEvents {
  final String phone;
  final String name;
  final String email;
  final String? title;
  final String cpf;
  final int gender;
  final XFile? avatar;
  final List<String> phones;
  final List<String> emails;
  // final List<String> classes;

  const SubmitEditProfileEvent({
    required this.phone,
    required this.name,
    required this.email,
    required this.title,
    required this.phones,
    required this.gender,
    required this.emails,
    // required this.classes,
    required this.cpf,
    required this.avatar,
  });
}

class FetchEditProfileEvent extends EditProfileEvents {

  const FetchEditProfileEvent();
}
