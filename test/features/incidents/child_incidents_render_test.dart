import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/incidents/bloc/incident_bloc.dart';
import 'package:escola/features/incidents/model/incident_model.dart';
import 'package:escola/features/incidents/presentation/child_incidents_screen.dart';
import 'package:escola/features/incidents/repo/incident_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentRepo extends Mock implements IncidentRepo {}

void main() {
  testWidgets('Parent screen renders one row per incident returned by the repo',
      (tester) async {
    final repo = MockIncidentRepo();

    const incidents = [
      IncidentModel(
        id: 1,
        incidentType: 'accident',
        severity: 'minor',
        description: 'Tripped in the playground.',
        actionTaken: 'Plaster applied.',
        childName: 'Liam',
      ),
      IncidentModel(
        id: 2,
        incidentType: 'illness',
        severity: 'serious',
        description: 'High temperature.',
        actionTaken: 'Sent home.',
        childName: 'Liam',
      ),
    ];

    when(() => repo.getChildIncidents(any()))
        .thenAnswer((_) async => const Right<Failure, List<IncidentModel>>(incidents));

    final bloc = IncidentBloc(repo);

    await tester.pumpWidget(
      MaterialApp(home: ChildIncidentsScreen(bloc: bloc)),
    );

    await bloc.fetchChildIncidents(7);
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Tripped in the playground.'), findsOneWidget);
    expect(find.text('High temperature.'), findsOneWidget);
  });
}
