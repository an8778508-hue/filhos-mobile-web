import 'package:bloc/bloc.dart';
import 'package:escola/features/attendance/bloc/attendance_state.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';
import 'package:escola/features/attendance/repo/attendance_repo.dart';

class AttendanceBloc extends Cubit<AttendanceState> {
  AttendanceBloc(this.repo, {this.children = const []}) : super(const AttendanceState());

  final AttendanceRepo repo;

  /// Optional roster of children (id -> name) the screen wants to display even
  /// before any attendance has been marked. When empty, the loaded attendance
  /// rows are used as the roster instead.
  final List<AttendanceModel> children;

  int? _classId;
  String? _date;

  /// Load attendance for a class/date. Seeds the roster from [children] when
  /// provided so every child shows a row even with no prior attendance.
  Future<void> load({required int classId, required String date}) async {
    _classId = classId;
    _date = date;

    emit(state.updateRosterState((s) => s.asLoading()).copyWith(submitted: false));

    final result = await repo.getAttendance(classId: classId, date: date);

    result.fold(
      (l) => emit(state.updateRosterState((s) => s.asFailed(l))),
      (loaded) {
        final roster = _mergeRoster(loaded);
        final selected = {for (final r in roster) r.childId: r.status};
        emit(state
            .updateRosterState((s) => s.asSuccessfullyLoaded(roster))
            .copyWith(selectedStatuses: selected));
      },
    );
  }

  /// Combine the seed [children] roster with any already-marked attendance rows,
  /// preferring the loaded row's status where present.
  List<AttendanceModel> _mergeRoster(List<AttendanceModel> loaded) {
    if (children.isEmpty) {
      return loaded;
    }
    return children.map((c) {
      final match = loaded.where((r) => r.childId == c.childId);
      return match.isNotEmpty ? match.first : c;
    }).toList();
  }

  /// Toggle/set a single child's status locally (before submit).
  void setStatus(int childId, AttendanceStatus status) {
    final updated = Map<int, AttendanceStatus>.from(state.selectedStatuses);
    updated[childId] = status;
    emit(state.copyWith(selectedStatuses: updated));
  }

  /// Mark every child in the roster present locally.
  void markAllPresent() {
    final updated = {for (final r in state.rosterState.data) r.childId: AttendanceStatus.present};
    emit(state.copyWith(selectedStatuses: updated));
  }

  /// Submit the current selection as a bulk update.
  Future<void> submit() async {
    final classId = _classId;
    final date = _date;
    if (classId == null || date == null) return;

    emit(state.copyWith(submitting: true, submitted: false));

    final records = state.rosterState.data
        .map((r) => {
              'child_id': r.childId,
              'status': attendanceStatusToString(state.statusFor(r.childId)),
            })
        .toList();

    final result = await repo.markBulk(classId: classId, date: date, records: records);

    result.fold(
      (l) => emit(state.copyWith(submitting: false).updateRosterState((s) => s.asFailed(l))),
      (saved) {
        final roster = _mergeRoster(saved.isNotEmpty ? saved : state.rosterState.data);
        emit(state
            .copyWith(submitting: false, submitted: true)
            .updateRosterState((s) => s.asSuccessfullyLoaded(roster)));
      },
    );
  }
}
