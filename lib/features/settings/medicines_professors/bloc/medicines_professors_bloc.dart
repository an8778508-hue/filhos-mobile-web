import 'dart:io';

import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_states.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicinesProfessorsBloc extends Cubit<MedicinesProfessorsStates> {
  final MedicinesProfessorsRepo medicinesProfessorsRepo;

  MedicinesProfessorsBloc({
    required this.medicinesProfessorsRepo,
  }) : super(const MedicinesProfessorsStates());

  loadRequests([RequestType type = RequestType.load]) async {
    emit(state.setRequestsState((s) {
      switch (type) {
        case RequestType.load:
          return s.asLoading();
        case RequestType.reload:
          return s.asReloading();
        case RequestType.loadMore:
          return s.asLoadingMore();
      }
    }));
    final currentPage = state.requestsState.currentPage;
    final page = type == RequestType.loadMore ? currentPage + 1 : 1;
    final f = await medicinesProfessorsRepo.getMedicineRequests(page);
    f.fold(
      (l) async => emit(state.setRequestsState((s) => s.asFailed(l))),
      (r) async =>
          emit(state.setRequestsState((s) => type == RequestType.loadMore ? s.asSuccessfullyLoadedMore(r) : s.asSuccessfullyLoaded(r))),
    );
  }

  loadHistory([RequestType type = RequestType.load]) async {
    emit(state.setHistoryState((s) {
      switch (type) {
        case RequestType.load:
          return s.asLoading();
        case RequestType.reload:
          return s.asReloading();
        case RequestType.loadMore:
          return s.asLoadingMore();
      }
    }));
    final currentPage = state.historyState.currentPage;
    final page = type == RequestType.loadMore ? currentPage + 1 : 1;
    final f = await medicinesProfessorsRepo.getMedicineHistory(page);
    f.fold(
      (l) async => emit(state.setHistoryState((s) => s.asFailed(l))),
      (r) async =>
          emit(state.setHistoryState((s) => type == RequestType.loadMore ? s.asSuccessfullyLoadedMore(r) : s.asSuccessfullyLoaded(r))),
    );
  }

  loadReminders([RequestType type = RequestType.load, bool delay = false]) async {
    emit(state.setReminderState((s) {
      switch (type) {
        case RequestType.load:
          return s.asLoading();
        case RequestType.reload:
          return s.asReloading();
        case RequestType.loadMore:
          return s.asLoadingMore();
      }
    }));
    final currentPage = state.historyState.currentPage;
    final page = type == RequestType.loadMore ? currentPage + 1 : 1;
    final f = await medicinesProfessorsRepo.getMedicineReminder(page);
    f.fold(
      (l) async => emit(state.setReminderState((s) => s.asFailed(l))),
      (r) async {
        if(delay){
          await Future.delayed(const Duration(milliseconds: 1500));
        }
        emit(state.setReminderState((s) => type == RequestType.loadMore ? s.asSuccessfullyLoadedMore(r) : s.asSuccessfullyLoaded(r)));
      },
    );
  }
}
