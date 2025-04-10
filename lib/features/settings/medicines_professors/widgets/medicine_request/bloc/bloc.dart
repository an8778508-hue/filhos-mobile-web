import 'dart:io';

import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedReqBloc extends Cubit<GenericState> {
  MedReqBloc(this.repo) : super(const GenericState());

  final MedicinesProfessorsRepo repo;

  acceptRequest(String id) async {
    emit(state.asLoading());
    final f = await repo.acceptRequest(
      id,
    );
    f.fold(
      (l) => emit(state.asFailed(l)),
      (r) => emit(state.asSuccess()),
    );
  }

  rejectRequest(String id, String reason, List<File> attachments) async {
    emit(state.asLoading());
    final f = await repo.rejectRequest(id, reason, attachments);
    f.fold(
      (l) => emit(state.asFailed(l)),
      (r) => emit(state.asSuccess()),
    );
  }
}
