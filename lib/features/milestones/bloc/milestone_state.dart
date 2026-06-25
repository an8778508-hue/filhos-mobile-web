import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/milestones/model/milestone_model.dart';

class MilestoneState {
  final GenericListState<MilestoneModel> milestonesState;

  const MilestoneState({
    this.milestonesState = const GenericListState<MilestoneModel>(),
  });

  List<MilestoneModel> get data => milestonesState.data;

  /// Milestones for a single domain (social|language|cognitive|motor),
  /// ordered by their minimum age band.
  List<MilestoneModel> byDomain(String domain) {
    final list = milestonesState.data.where((m) => m.domain == domain).toList();
    list.sort((a, b) => a.ageBandMin.compareTo(b.ageBandMin));
    return list;
  }

  MilestoneState copyWith({
    GenericListState<MilestoneModel>? milestonesState,
  }) =>
      MilestoneState(
        milestonesState: milestonesState ?? this.milestonesState,
      );

  MilestoneState updateMilestonesState(
    GenericListState<MilestoneModel> Function(GenericListState<MilestoneModel> s) update,
  ) =>
      copyWith(milestonesState: update(milestonesState));
}
