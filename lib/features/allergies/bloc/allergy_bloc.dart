import 'package:bloc/bloc.dart';
import 'package:escola/features/allergies/bloc/allergy_state.dart';
import 'package:escola/features/allergies/model/allergy_model.dart';
import 'package:escola/features/allergies/repo/allergy_repo.dart';

class AllergyBloc extends Cubit<AllergyState> {
  AllergyBloc(this.repo, {this.childId = 0, this.prefix = 'parent'}) : super(const AllergyState());

  final AllergyRepo repo;
  final int childId;
  final String prefix;

  Future<void> fetch({bool reload = false}) async {
    emit(state.updateAllergiesState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getForChild(childId, prefix: prefix);
    f.fold(
      (l) => emit(state.updateAllergiesState((s) => s.asFailed(l))),
      (r) => emit(state.updateAllergiesState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  Future<void> create({
    required String allergen,
    required String severity,
    required String reactionDescription,
    required String actionToTake,
  }) async {
    final f = await repo.create(
      childId: childId,
      allergen: allergen,
      severity: severity,
      reactionDescription: reactionDescription,
      actionToTake: actionToTake,
    );
    f.fold(
      (l) => emit(state.updateAllergiesState((s) => s.asFailed(l))),
      (created) => emit(state.updateAllergiesState((s) => s.asSuccessfullyLoaded([...state.data, created]))),
    );
  }

  Future<void> update({
    required int id,
    required String allergen,
    required String severity,
    required String reactionDescription,
    required String actionToTake,
  }) async {
    final f = await repo.update(
      id: id,
      allergen: allergen,
      severity: severity,
      reactionDescription: reactionDescription,
      actionToTake: actionToTake,
    );
    f.fold(
      (l) => emit(state.updateAllergiesState((s) => s.asFailed(l))),
      (updated) {
        final newList = state.data.map((a) => a.id == updated.id ? updated : a).toList();
        emit(state.updateAllergiesState((s) => s.asSuccessfullyLoaded(newList)));
      },
    );
  }

  Future<void> remove(int id) async {
    final f = await repo.delete(id);
    f.fold(
      (l) => emit(state.updateAllergiesState((s) => s.asFailed(l))),
      (_) {
        final newList = state.data.where((a) => a.id != id).toList();
        emit(state.updateAllergiesState((s) => s.asSuccessfullyLoaded(newList)));
      },
    );
  }

  /// Seed allergies directly (used by tests / parent-passed data).
  void seed(List<AllergyModel> allergies) {
    emit(state.updateAllergiesState((s) => s.asSuccessfullyLoaded(allergies)));
  }
}
