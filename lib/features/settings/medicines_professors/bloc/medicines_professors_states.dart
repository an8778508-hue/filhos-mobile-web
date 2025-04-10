import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/settings/medicines/models/medicine_model.dart';
import 'package:escola/features/settings/medicines_professors/models/medicine_prescription_model.dart';

class MedicinesProfessorsStates {
  final GenericListState<MedicineModel> requestsState;
  final GenericListState<MedicinePrescriptionModel> historyState;
  final GenericListState<MedicinePrescriptionModel> reminderState;

  const MedicinesProfessorsStates({
    this.requestsState = const GenericListState<MedicineModel>(),
    this.historyState = const GenericListState<MedicinePrescriptionModel>(),
    this.reminderState = const GenericListState<MedicinePrescriptionModel>(),
  });

  MedicinesProfessorsStates copyWith({
    GenericListState<MedicineModel>? requestsState,
    GenericListState<MedicinePrescriptionModel>? historyState,
    GenericListState<MedicinePrescriptionModel>? reminderState,
  }) =>
      MedicinesProfessorsStates(
        requestsState: requestsState ?? this.requestsState,
        historyState: historyState ?? this.historyState,
        reminderState: reminderState ?? this.reminderState,
      );

  MedicinesProfessorsStates setRequestsState(GenericListState<MedicineModel> Function(GenericListState<MedicineModel> s) setter) =>
      copyWith(
        requestsState: setter(requestsState),
      );

  MedicinesProfessorsStates setHistoryState(
          GenericListState<MedicinePrescriptionModel> Function(GenericListState<MedicinePrescriptionModel> s) setter) =>
      copyWith(
        historyState: setter(historyState),
      );

  MedicinesProfessorsStates setReminderState(
          GenericListState<MedicinePrescriptionModel> Function(GenericListState<MedicinePrescriptionModel> s) setter) =>
      copyWith(
        reminderState: setter(reminderState),
      );
}
