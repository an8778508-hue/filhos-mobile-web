import 'package:escola/features/incidents/bloc/incident_bloc.dart';
import 'package:escola/features/incidents/bloc/incident_state.dart';
import 'package:escola/features/incidents/model/incident_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renders the incident list from an [IncidentBloc]. Shared by the admin and
/// parent screens (they differ only in how the data is loaded + filters).
class IncidentListView extends StatelessWidget {
  const IncidentListView({super.key, this.emptyText = 'No incidents'});

  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentBloc, IncidentState>(
      builder: (context, state) {
        final ls = state.incidentsState;
        if (ls.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.data.isEmpty) {
          return Center(child: Text(emptyText));
        }
        return ListView.builder(
          itemCount: state.data.length,
          itemBuilder: (context, index) => _IncidentTile(item: state.data[index]),
        );
      },
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.item});

  final IncidentModel item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${item.incidentType} · ${item.severity}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.description),
          if (item.childName != null) Text('Child: ${item.childName}'),
          if (item.occurredAt != null) Text('When: ${item.occurredAt}'),
        ],
      ),
      isThreeLine: true,
    );
  }
}
