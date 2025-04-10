import 'package:bloc/bloc.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_impl.dart';
import 'package:escola/features/settings/medicines_professors/models/medicine_prescription_model.dart';

class MedPresBloc extends Cubit<GenericState> {
  final MedicinesProfessorsRepo repo;

  MedPresBloc(this.repo) : super(const GenericState());

  Future check(PrescriptionModel item) async {
    if (state.loading) {
      return;
    }
    emit(state.asLoading());
    final f = await repo.markMedicineReminder(item.id);
    f.fold(
      (l) => emit(state.asFailed(l)),
      (r) => emit(state.asSuccess()),
    );
  }
}
