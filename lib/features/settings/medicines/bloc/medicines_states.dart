import 'package:escola/core/models/generic_state.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/medicines/models/medicine_model.dart';

class MedicinesStates {
  final AllMedicinesState allMedicinesState;
  final GenericState deleteState;

  const MedicinesStates({
    this.allMedicinesState = const AllMedicinesState(),
    this.deleteState = const GenericState(),
  });

  MedicinesStates copyWith({
    AllMedicinesState? allMedicinesState,
    GenericState? deleteState,
  }) =>
      MedicinesStates(
        allMedicinesState: allMedicinesState ?? this.allMedicinesState,
        deleteState: deleteState ?? this.deleteState,
      );

  MedicinesStates setMedicinesState(AllMedicinesState Function(AllMedicinesState s) setter) => copyWith(
        allMedicinesState: setter(allMedicinesState),
      );

  MedicinesStates setDeleteState(GenericState Function(GenericState s) setter) => copyWith(
        deleteState: setter(deleteState),
      );
}

class AllMedicinesState {
  final List<MedicineModel> data;
  final bool loading;
  final bool loadingMore;
  final bool noMore;
  final int currentPage;
  final String? error;

  const AllMedicinesState({
    this.data = const [],
    this.loading = false,
    this.loadingMore = false,
    this.noMore = false,
    this.currentPage = 1,
    this.error,
  });

  AllMedicinesState get fetching => const AllMedicinesState(
        loading: true,
      );

  AllMedicinesState get asLoadingMore => AllMedicinesState(
        loadingMore: true,
        data: data,
        currentPage: currentPage,
        noMore: noMore,
      );

  AllMedicinesState successLoadingMore(List<MedicineModel> data) => AllMedicinesState(
        data: [...this.data, ...data],
        currentPage: currentPage + 1,
        noMore: !validList(data),
      );

  AllMedicinesState success(List<MedicineModel> data) => AllMedicinesState(
        data: data,
      );

  AllMedicinesState failed(String error) => AllMedicinesState(
        error: error,
      );

  bool get isLoading => loading || loadingMore;
}
