import 'package:escola/features/incidents/presentation/log_incident_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Submit with empty required fields shows validation and does not call onSubmit',
      (tester) async {
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LogIncidentScreen(
          childId: 1,
          onSubmit: ({
            required childId,
            required incidentType,
            required severity,
            required description,
            required actionTaken,
            occurredAt,
          }) {
            submitted = true;
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Please select an incident type'), findsOneWidget);
    expect(find.text('Please select a severity'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    expect(find.text('Action taken is required'), findsOneWidget);

    expect(submitted, isFalse);
  });

  testWidgets('Submit with valid fields calls onSubmit with the expected payload',
      (tester) async {
    int? capturedChildId;
    String? capturedType;
    String? capturedSeverity;
    String? capturedDescription;
    String? capturedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: LogIncidentScreen(
          childId: 42,
          onSubmit: ({
            required childId,
            required incidentType,
            required severity,
            required description,
            required actionTaken,
            occurredAt,
          }) {
            capturedChildId = childId;
            capturedType = incidentType;
            capturedSeverity = severity;
            capturedDescription = description;
            capturedAction = actionTaken;
          },
        ),
      ),
    );

    // Select incident type.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('accident').last);
    await tester.pumpAndSettle();

    // Select severity.
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('minor').last);
    await tester.pumpAndSettle();

    // Fill text fields.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'), 'Tripped over a toy.');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Action taken'), 'Comforted and applied a plaster.');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(capturedChildId, 42);
    expect(capturedType, 'accident');
    expect(capturedSeverity, 'minor');
    expect(capturedDescription, 'Tripped over a toy.');
    expect(capturedAction, 'Comforted and applied a plaster.');
  });
}
