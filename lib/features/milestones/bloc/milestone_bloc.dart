import 'package:bloc/bloc.dart';
import 'package:escola/features/milestones/bloc/milestone_state.dart';
import 'package:escola/features/milestones/repo/milestone_repo.dart';

/// Drives a single child's milestone progress, grouped by domain.
///
/// Teachers (asTeacher: true) can [mark] milestones reached; parents see a
/// read-only view.
class MilestoneBloc extends Cubit<MilestoneState> {
  MilestoneBloc(
    this.repo, {
    required this.childId,
    this.asTeacher = false,
  }) : super(const MilestoneState());

  final MilestoneRepo repo;
  final int childId;
  final bool asTeacher;

  static const domains = ['social', 'language', 'cognitive', 'motor'];

  /// Initial load or pull-to-refresh.
  Future<void> fetch({bool reload = false}) async {
    emit(state.updateMilestonesState((s) => reload ? s.asReloading() : s.asLoading()));

    final result = await repo.getChildMilestones(childId, asTeacher: asTeacher);

    result.fold(
      (failure) => emit(state.updateMilestonesState((s) => s.asFailed(failure))),
      (list) => emit(state.updateMilestonesState((s) => s.asSuccessfullyLoaded(list))),
    );
  }

  /// Teacher marks a milestone reached. Optimistically flips the local state
  /// on success (and clears the overdue flag).
  Future<void> mark(int milestoneId, {String? notes}) async {
    if (!asTeacher) return;

    final result = await repo.mark(
      childId: childId,
      milestoneId: milestoneId,
      notes: notes,
    );

    result.fold(
      (failure) => emit(state.updateMilestonesState((s) => s.asFailed(failure))),
      (_) {
        final updated = state.data
            .map((m) => m.id == milestoneId ? m.copyWith(reached: true, overdue: false) : m)
            .toList();
        emit(state.updateMilestonesState((s) => s.asSuccessfullyLoaded(updated)));
      },
    );
  }
}
