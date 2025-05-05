
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';

class AddAddressStates {
  final CountriesState countriesState;
  final CitiesState citiesState;
  final RegionsState regionsState;
  final SubmitAddressState submitAddressState;

  const AddAddressStates({
    this.countriesState = const CountriesState(),
    this.citiesState = const CitiesState(),
    this.regionsState = const RegionsState(),
    this.submitAddressState = const SubmitAddressState(),
  });

  AddAddressStates copyWith({
    CountriesState? countriesState,
    CitiesState? citiesState,
    RegionsState? regionsState,
    SubmitAddressState? submitAddressState,
  }) =>
      AddAddressStates(
        countriesState: countriesState ?? this.countriesState,
        submitAddressState: submitAddressState ?? this.submitAddressState,
        citiesState: citiesState ?? this.citiesState,
        regionsState: regionsState ?? this.regionsState,
      );

  AddAddressStates setCountriesState(CountriesState Function(CountriesState s) setter) => copyWith(
        countriesState: setter(countriesState),
      );

  AddAddressStates setCitiesState(CitiesState Function(CitiesState s) setter) => copyWith(
        citiesState: setter(citiesState),
      );

  AddAddressStates setRegionsState(RegionsState Function(RegionsState s) setter) => copyWith(
        regionsState: setter(regionsState),
      );

  AddAddressStates setSubmitAddressState(SubmitAddressState Function(SubmitAddressState s) setter) => copyWith(
        submitAddressState: setter(submitAddressState),
      );
}

class SubmitAddressState {
  final bool success;
  final bool loading;
  final String? error;

  const SubmitAddressState({
    this.success = false,
    this.loading = false,
    this.error,
  });

  SubmitAddressState get submitting => const SubmitAddressState(
        loading: true,
      );

  SubmitAddressState get succeeded => const SubmitAddressState(
        success: true,
      );

  SubmitAddressState failed(String error) => SubmitAddressState(
        error: error,
      );
}

class CountriesState {
  final CountryModel? selected;
  final List<CountryModel> data;
  final bool loading;
  final String? error;

  const CountriesState({
    this.selected,
    this.data = const [],
    this.loading = false,
    this.error,
  });

  CountriesState get fetching => const CountriesState(
        loading: true,
      );

  CountriesState success(List<CountryModel> data) => CountriesState(
        data: data,
        selected: selected,
      );

  CountriesState select(CountryModel selected) => CountriesState(
        data: data,
        selected: selected,
      );

  CountriesState failed(String error) => CountriesState(
        error: error,
      );
}


class CitiesState {
  final CityModel? selected;
  final List<CityModel> data;
  final bool loading;
  final String? error;

 const  CitiesState({
    this.selected,
    this.data = const [],
    this.loading = false,
    this.error,
  });

  CitiesState get fetching => CitiesState(
    loading: true,
  );

  CitiesState success(List<CityModel> data) => CitiesState(
    data: data,
    selected: selected,
  );

  CitiesState select(CityModel selected) => CitiesState(
    data: data,
    selected: selected,
  );

  CitiesState failed(String error) => CitiesState(
    error: error,
  );
}


class RegionsState {
  final RegionModel? selected;
  final List<RegionModel> data;
  final bool loading;
  final String? error;

  const RegionsState({
    this.selected,
    this.data = const [],
    this.loading = false,
    this.error,
  });

  RegionsState get fetching => const RegionsState(
    loading: true,
  );

  RegionsState success(List<RegionModel> data) => RegionsState(
    data: data,
    selected: selected,
  );

  RegionsState select(RegionModel selected) => RegionsState(
    data: data,
    selected: selected,
  );

  RegionsState failed(String error) => RegionsState(
    error: error,
  );
}
