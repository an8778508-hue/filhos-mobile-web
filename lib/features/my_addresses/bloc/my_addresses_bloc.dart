import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_events.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_states.dart';
import 'package:escola/features/my_addresses/repo/my_addresses_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyAddressesBloc extends Bloc<MyAddressesEvents, MyAddressesStates> {
  final MyAddressesRepo myAddressesRepo;

  CityModel? initialCity;
  RegionModel? initialRegion;

  MyAddressesBloc({
    required this.myAddressesRepo,
    this.initialCity,
    this.initialRegion,
  }) : super(const MyAddressesStates()) {
    on<SubmitMyAddressesEvent>(
      (event, emit) async {
      },
    );
    on<FetchAddresses>(
      (event, emit) async {
        emit(state.setAddressesState((s) => s.fetching));
        final f = await myAddressesRepo.getAddresses();
        f.fold(
          (l) async => emit(state.setAddressesState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setAddressesState((s) => s.success(r)));
          },
        );
      },
    );
  }
}
