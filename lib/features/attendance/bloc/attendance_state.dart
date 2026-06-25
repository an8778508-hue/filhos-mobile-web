import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';

class AttendanceState {
  /// The roster rows (one per child) loaded for the selected class/date.
  final GenericListState<AttendanceModel> rosterState;

  /// The teacher's locally chosen status per child id (before submitting).
  final Map<int, AttendanceStatus> selectedStatuses;

  /// True while a bulk submit is in flight.
  final bool submitting;

  /// True once a submit has succeeded.
  final bool submitted;

  const AttendanceState({
    this.rosterState = const GenericListState<AttendanceModel>(),
    this.selectedStatuses = const {},
    this.submitting = false,
    this.submitted = false,
  });

  AttendanceState copyWith({
    GenericListState<AttendanceModel>? rosterState,
    Map<int, AttendanceStatus>? selectedStatuses,
    bool? submitting,
    bool? submitted,
  }) =>
      AttendanceState(
        rosterState: rosterState ?? this.rosterState,
        selectedStatuses: selectedStatuses ?? this.selectedStatuses,
        submitting: submitting ?? this.submitting,
        submitted: submitted ?? this.submitted,
      );

  AttendanceState updateRosterState(
          GenericListState<AttendanceModel> Function(GenericListState<AttendanceModel> s) update) =>
      copyWith(rosterState: update(rosterState));

  /// Resolve the effective status for a child: locally selected else loaded else present.
  AttendanceStatus statusFor(int childId) {
    if (selectedStatuses.containsKey(childId)) {
      return selectedStatuses[childId]!;
    }
    final existing = rosterState.data.where((r) => r.childId == childId);
    return existing.isNotEmpty ? existing.first.status : AttendanceStatus.present;
  }
}
