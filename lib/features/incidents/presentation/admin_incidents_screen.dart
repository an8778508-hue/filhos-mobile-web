import 'package:escola/features/incidents/bloc/incident_bloc.dart';
import 'package:escola/features/incidents/presentation/widgets/incident_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Admin list of all incidents, with type/severity filters.
class AdminIncidentsScreen extends StatefulWidget {
  final IncidentBloc bloc;

  const AdminIncidentsScreen({super.key, required this.bloc});

  @override
  State<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends State<AdminIncidentsScreen> {
  static const _incidentTypes = ['accident', 'illness', 'behaviour', 'other'];
  static const _severities = ['minor', 'moderate', 'serious'];

  String? _type;
  String? _severity;

  void _applyFilters() {
    widget.bloc.fetchAdminIncidents(
      incidentType: _type,
      severity: _severity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Incidents')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All')),
                        ..._incidentTypes
                            .map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
                      ],
                      onChanged: (v) {
                        setState(() => _type = v);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'Severity'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All')),
                        ..._severities
                            .map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                      ],
                      onChanged: (v) {
                        setState(() => _severity = v);
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: IncidentListView()),
          ],
        ),
      ),
    );
  }
}
