import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_events.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_states.dart';
import 'package:escola/features/settings/medicines/repo/medicines_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicinesBloc extends Bloc<MedicinesEvents, MedicinesStates> {
  final MedicinesRepo medicinesRepo;

  CityModel? initialCity;
  RegionModel? initialRegion;

  MedicinesBloc({
    required this.medicinesRepo,
    this.initialCity,
    this.initialRegion,
  }) : super(const MedicinesStates()) {
    on<SubmitMedicinesEvent>(
      (event, emit) async {},
    );
    on<DeleteMedicine>(
      (event, emit) async {
        emit(state.setDeleteState((s) => s.asLoading()));
        final f = await medicinesRepo.deleteMedicine(event.id);
        f.fold(
          (l) => emit(state.setDeleteState((s) => s.asFailed(l))),
          (r) {
            emit(state.setDeleteState((s) => s.asSuccess()));
            add(const FetchMedicines());
          },
        );
      },
    );
    on<FetchMedicines>(
      (event, emit) async {
        emit(state.setMedicinesState((s) => s.fetching));
        final f = await medicinesRepo.getMedicines();
        f.fold(
          (l) async => emit(state.setMedicinesState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setMedicinesState((s) => s.success(r)));
          },
        );
      },
    );
    on<LoadMoreMedicines>(
      (event, emit) async {
        if (state.allMedicinesState.isLoading) {
          return;
        }
        emit(state.setMedicinesState((s) => s.asLoadingMore));
        final f = await medicinesRepo.getMedicines(state.allMedicinesState.currentPage + 1);
        f.fold(
          (l) async => emit(state.setMedicinesState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setMedicinesState((s) => s.successLoadingMore(r)));
          },
        );
      },
    );
  }
}
