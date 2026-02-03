
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/my_addresses/models/address_model.dart';

class MyAddressesStates {
  final AddressesState addressesState;

  const MyAddressesStates({
    this.addressesState = const AddressesState(),
  });

  MyAddressesStates copyWith({
    AddressesState? addressesState,
  }) =>
      MyAddressesStates(
        addressesState: addressesState ?? this.addressesState,
      );

  MyAddressesStates setAddressesState(AddressesState Function(AddressesState s) setter) => copyWith(
        addressesState: setter(addressesState),
      );

}

class AddressesState {
  final List<AddressModel> data;
  final bool loading;
  final String? error;

  const AddressesState({
    this.data = const [],
    this.loading = false,
    this.error,
  });

  AddressesState get fetching => const AddressesState(
        loading: true,
      );

  AddressesState success(List<AddressModel> data) => AddressesState(
        data: data,
      );

  AddressesState select(AreaModel selected) => AddressesState(
        data: data,
      );

  AddressesState failed(String error) => AddressesState(
        error: error,
      );
}
