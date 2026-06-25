import 'package:bloc/bloc.dart';
import 'package:escola/features/immunisations/bloc/immunisation_state.dart';
import 'package:escola/features/immunisations/model/immunisation_model.dart';
import 'package:escola/features/immunisations/repo/immunisation_repo.dart';

class ImmunisationBloc extends Cubit<ImmunisationState> {
  ImmunisationBloc(this.repo, {this.childId = 0, this.prefix = 'parent'})
      : super(const ImmunisationState());

  final ImmunisationRepo repo;
  final int childId;
  final String prefix;

  Future<void> fetch({bool reload = false}) async {
    emit(state.updateImmunisationsState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getForChild(childId, prefix: prefix);
    f.fold(
      (l) => emit(state.updateImmunisationsState((s) => s.asFailed(l))),
      (r) => emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  Future<void> fetchUpcoming({bool reload = false}) async {
    emit(state.updateImmunisationsState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getUpcoming();
    f.fold(
      (l) => emit(state.updateImmunisationsState((s) => s.asFailed(l))),
      (r) => emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  Future<void> create({
    required String vaccineName,
    required String dateGiven,
    String? nextDueDate,
    String? notes,
  }) async {
    final f = await repo.create(
      childId: childId,
      vaccineName: vaccineName,
      dateGiven: dateGiven,
      nextDueDate: nextDueDate,
      notes: notes,
    );
    f.fold(
      (l) => emit(state.updateImmunisationsState((s) => s.asFailed(l))),
      (created) =>
          emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded([...state.data, created]))),
    );
  }

  Future<void> update({
    required int id,
    required String vaccineName,
    required String dateGiven,
    String? nextDueDate,
    String? notes,
  }) async {
    final f = await repo.update(
      id: id,
      vaccineName: vaccineName,
      dateGiven: dateGiven,
      nextDueDate: nextDueDate,
      notes: notes,
    );
    f.fold(
      (l) => emit(state.updateImmunisationsState((s) => s.asFailed(l))),
      (updated) {
        final newList = state.data.map((a) => a.id == updated.id ? updated : a).toList();
        emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded(newList)));
      },
    );
  }

  Future<void> remove(int id) async {
    final f = await repo.delete(id);
    f.fold(
      (l) => emit(state.updateImmunisationsState((s) => s.asFailed(l))),
      (_) {
        final newList = state.data.where((a) => a.id != id).toList();
        emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded(newList)));
      },
    );
  }

  /// Seed records directly (used by tests / parent-passed data).
  void seed(List<ImmunisationModel> immunisations) {
    emit(state.updateImmunisationsState((s) => s.asSuccessfullyLoaded(immunisations)));
  }
}
