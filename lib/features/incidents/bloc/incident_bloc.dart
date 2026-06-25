import 'package:bloc/bloc.dart';
import 'package:escola/features/incidents/bloc/incident_state.dart';
import 'package:escola/features/incidents/model/incident_model.dart';
import 'package:escola/features/incidents/repo/incident_repo.dart';

class IncidentBloc extends Cubit<IncidentState> {
  IncidentBloc(this.repo) : super(const IncidentState());

  final IncidentRepo repo;

  /// Teacher: load the authenticated teacher's own reports.
  Future<void> fetchTeacherIncidents({bool reload = false}) async {
    emit(state.updateIncidentsState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getTeacherIncidents();
    f.fold(
      (l) => emit(state.updateIncidentsState((s) => s.asFailed(l))),
      (r) => emit(state.updateIncidentsState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  /// Admin: load all incidents with optional filters.
  Future<void> fetchAdminIncidents({
    int? childId,
    String? incidentType,
    String? severity,
    String? from,
    String? to,
    bool reload = false,
  }) async {
    emit(state.updateIncidentsState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getAdminIncidents(
      childId: childId,
      incidentType: incidentType,
      severity: severity,
      from: from,
      to: to,
    );
    f.fold(
      (l) => emit(state.updateIncidentsState((s) => s.asFailed(l))),
      (r) => emit(state.updateIncidentsState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  /// Parent: load incidents for one of their children.
  Future<void> fetchChildIncidents(int childId, {bool reload = false}) async {
    emit(state.updateIncidentsState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await repo.getChildIncidents(childId);
    f.fold(
      (l) => emit(state.updateIncidentsState((s) => s.asFailed(l))),
      (r) => emit(state.updateIncidentsState((s) => s.asSuccessfullyLoaded(r))),
    );
  }

  /// Teacher: log an incident.
  Future<void> logIncident({
    required int childId,
    required String incidentType,
    required String severity,
    required String description,
    required String actionTaken,
    String? occurredAt,
  }) async {
    await repo.logIncident(
      childId: childId,
      incidentType: incidentType,
      severity: severity,
      description: description,
      actionTaken: actionTaken,
      occurredAt: occurredAt,
    );
  }

  void seed(List<IncidentModel> incidents) {
    emit(state.updateIncidentsState((s) => s.asSuccessfullyLoaded(incidents)));
  }
}
