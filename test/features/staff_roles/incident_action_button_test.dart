import 'package:escola/core/user/nursery_role.dart';
import 'package:escola/features/staff_roles/presentation/widgets/incident_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(NurseryRole role, {VoidCallback? onPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: IncidentActionButton(
          role: role,
          onPressed: onPressed ?? () {},
        ),
      ),
    );
  }

  testWidgets('assistant_teacher does NOT see the incident button', (tester) async {
    await tester.pumpWidget(wrap(const NurseryRole(NurseryRole.assistantTeacher)));

    expect(find.byType(IncidentActionButton), findsOneWidget);
    expect(find.byKey(const ValueKey('incident_action_button')), findsNothing);
    expect(find.text('Log incident'), findsNothing);
  });

  testWidgets('lead_teacher DOES see the incident button', (tester) async {
    await tester.pumpWidget(wrap(const NurseryRole(NurseryRole.leadTeacher)));

    expect(find.byKey(const ValueKey('incident_action_button')), findsOneWidget);
    expect(find.text('Log incident'), findsOneWidget);
  });

  testWidgets('owner and admin see the incident button', (tester) async {
    await tester.pumpWidget(wrap(const NurseryRole(NurseryRole.owner)));
    expect(find.byKey(const ValueKey('incident_action_button')), findsOneWidget);

    await tester.pumpWidget(wrap(const NurseryRole(NurseryRole.admin)));
    expect(find.byKey(const ValueKey('incident_action_button')), findsOneWidget);
  });

  testWidgets('null role (full access) sees the incident button', (tester) async {
    await tester.pumpWidget(wrap(const NurseryRole(null)));
    expect(find.byKey(const ValueKey('incident_action_button')), findsOneWidget);
  });

  testWidgets('tapping the visible button invokes onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(const NurseryRole(NurseryRole.leadTeacher), onPressed: () => tapped = true),
    );

    await tester.tap(find.byKey(const ValueKey('incident_action_button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  test('NurseryRole capability map matches the 4-tier taxonomy', () {
    expect(const NurseryRole(NurseryRole.owner).canManageBilling, isTrue);
    expect(const NurseryRole(NurseryRole.admin).canManageBilling, isFalse);
    expect(const NurseryRole(NurseryRole.admin).canSeeIncidents, isTrue);
    expect(const NurseryRole(NurseryRole.leadTeacher).canSeeIncidents, isTrue);
    expect(const NurseryRole(NurseryRole.assistantTeacher).canSeeIncidents, isFalse);
    expect(const NurseryRole(NurseryRole.assistantTeacher).canTakeAttendance, isFalse);
    expect(const NurseryRole(NurseryRole.assistantTeacher).canUseGallery, isTrue);
    // null / empty = full access.
    expect(const NurseryRole(null).canManageBilling, isTrue);
    expect(const NurseryRole('').canManageBilling, isTrue);
  });
}
