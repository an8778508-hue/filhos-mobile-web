import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/incidents/model/incident_model.dart';

class IncidentState {
  final GenericListState<IncidentModel> incidentsState;

  const IncidentState({
    this.incidentsState = const GenericListState<IncidentModel>(),
  });

  IncidentState copyWith({
    GenericListState<IncidentModel>? incidentsState,
  }) =>
      IncidentState(
        incidentsState: incidentsState ?? this.incidentsState,
      );

  IncidentState updateIncidentsState(
          GenericListState<IncidentModel> Function(GenericListState<IncidentModel> s) update) =>
      copyWith(incidentsState: update(incidentsState));

  List<IncidentModel> get data => incidentsState.data;
}
