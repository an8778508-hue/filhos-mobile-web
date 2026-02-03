import 'package:escola/features/add_address/bloc/add_address_events.dart';
import 'package:escola/features/add_address/bloc/add_address_states.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/add_address/repo/add_address_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAddressBloc extends Bloc<AddAddressEvents, AddAddressStates> {
  final AddressesRepo addressesRepo;

  CityModel? initialCity;
  RegionModel? initialRegion;

  AddAddressBloc({
    required this.addressesRepo,
    this.initialCity,
    this.initialRegion,
  }) : super(const AddAddressStates()) {
    on<SubmitAddAddressEvent>(
      (event, emit) async {
        emit(state.setSubmitAddressState((s) => s.submitting));
        final response = await addressesRepo.addOrUpdateAddress(
          id: event.id,
          name: event.name,
          country_id: event.country_id,
          country: event.country,
          city_id: event.city_id,
          city: event.city,
          region_id: event.region_id,
          brazil_state_code: event.brazil_state_code,
          area: event.area,
          address: event.address,
          state: event.state,
          zip_code: event.zip_code,
          complement: event.complement,
        );
        response.fold(
          (l) => emit(state.setSubmitAddressState((s) => s.failed(l.message))),
          (r) => emit(state.setSubmitAddressState((s) => s.succeeded)),
        );
      },
    );
    on<FetchCountries>(
      (event, emit) async {
        emit(state.setCountriesState((s) => s.fetching));
        final f = await addressesRepo.getCountries();
        f.fold(
          (l) async => emit(state.setCountriesState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setCountriesState((s) => s.success(r)));
            if (r.isNotEmpty) {
              if (event.addressModel?.countryModel != null) {
                add(SelectCountry(event.addressModel!.countryModel!));
              } else {
                // add(SelectCountry(r.first));
              }
            }
          },
        );
      },
    );
    on<SelectCountry>(
      (event, emit) async {
        emit(state.setCountriesState((s) => s.select(event.country)).setCitiesState((s) => s.fetching));
        final f = await addressesRepo.getCities(event.country.id);
        f.fold(
          (l) async => emit(state.setCitiesState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setCitiesState((s) => s.success(r)));
            if (initialCity != null) {
              add(SelectCity(initialCity!));
              initialCity = null;
            } else {
              if (r.isNotEmpty) {
                // add(SelectCity(r.first));
              }
            }
          },
        );
      },
    );
    on<SelectCity>(
      (event, emit) async {
        emit(state.setCitiesState((s) => s.select(event.city)).setRegionsState((s) => s.fetching));
        final f = await addressesRepo.getRegions(event.city.id);
        f.fold(
          (l) async => emit(state.setRegionsState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setRegionsState((s) => s.success(r)));
            if (initialRegion != null) {
              add(SelectRegion(initialRegion!));
              initialRegion = null;
            } else {
              if (r.isNotEmpty) {
                // add(SelectRegion(r.first));
              }
            }
          },
        );
      },
    );
    on<SelectRegion>(
      (event, emit) async {
        emit(state.setRegionsState((s) => s.select(event.region)));
      },
    );
  }
}
