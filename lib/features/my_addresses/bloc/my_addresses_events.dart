import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class MyAddressesEvents {
  const MyAddressesEvents();
}

class FetchAddresses extends MyAddressesEvents {
  const FetchAddresses();
}

class SubmitMyAddressesEvent extends MyAddressesEvents {
}
