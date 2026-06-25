import 'package:escola/features/incidents/bloc/incident_bloc.dart';
import 'package:escola/features/incidents/presentation/widgets/incident_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Parent-facing list of incidents for one of their children.
class ChildIncidentsScreen extends StatelessWidget {
  final IncidentBloc bloc;

  const ChildIncidentsScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Incidents')),
        body: const IncidentListView(),
      ),
    );
  }
}
