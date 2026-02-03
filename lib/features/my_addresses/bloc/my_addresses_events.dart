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
