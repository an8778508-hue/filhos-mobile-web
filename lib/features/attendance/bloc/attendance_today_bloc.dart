import 'package:bloc/bloc.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';
import 'package:escola/features/attendance/repo/attendance_repo.dart';

class AttendanceTodayBloc extends Cubit<GenericDataState<AttendanceTodayModel>> {
  AttendanceTodayBloc(this.repo) : super(const GenericDataState<AttendanceTodayModel>());

  final AttendanceRepo repo;

  Future<void> fetch() async {
    emit(state.asLoading());
    final result = await repo.getToday();
    result.fold(
      (l) => emit(state.asFailed(l)),
      (r) => emit(state.asSuccess(r)),
    );
  }
}
