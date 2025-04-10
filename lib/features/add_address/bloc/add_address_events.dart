import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/my_addresses/models/address_model.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class AddAddressEvents {
  const AddAddressEvents();
}

class FetchCountries extends AddAddressEvents {
  final AddressModel? addressModel;

  const FetchCountries({this.addressModel});
}

class SelectCountry extends AddAddressEvents {
  final CountryModel country;

  const SelectCountry(this.country);
}

class SelectCity extends AddAddressEvents {
  final CityModel city;

  const SelectCity(this.city);
}

class SelectRegion extends AddAddressEvents {
  final RegionModel region;

  const SelectRegion(this.region);
}

class SubmitAddAddressEvent extends AddAddressEvents {
  final String? id;
  final String? name;
  final String? country_id;
  final String? country;
  final String? city_id;
  final String? city;
  final String? region_id;
  final String? brazil_state_code;
  final String? area;
  final String? address;
  final String? state;
  final String? zip_code;
  final String? complement;

  SubmitAddAddressEvent({
    this.id,
    this.name,
    this.country_id,
    this.country,
    this.city_id,
    this.city,
    this.region_id,
    this.brazil_state_code,
    this.area,
    this.address,
    this.state,
    this.zip_code,
    this.complement,
  });
}
