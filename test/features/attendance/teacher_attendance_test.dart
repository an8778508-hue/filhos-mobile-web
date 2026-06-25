import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/attendance/bloc/attendance_bloc.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';
import 'package:escola/features/attendance/presentation/teacher_attendance_screen.dart';
import 'package:escola/features/attendance/repo/attendance_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepo extends Mock implements AttendanceRepo {}

AttendanceModel _child(int id, String name) =>
    AttendanceModel(id: 0, childId: id, childName: name, classId: 1);

void main() {
  late MockAttendanceRepo repo;

  final roster = [
    _child(101, 'Alice'),
    _child(102, 'Bob'),
    _child(103, 'Carol'),
  ];

  final classes = [
    {'id': 1, 'name': 'Class A'},
  ];

  setUp(() {
    repo = MockAttendanceRepo();
    // load() pulls existing attendance for the class/date; start empty.
    when(() => repo.getAttendance(classId: any(named: 'classId'), date: any(named: 'date')))
        .thenAnswer((_) async => const Right<Failure, List<AttendanceModel>>([]));
  });

  AttendanceBloc buildBloc() => AttendanceBloc(repo, children: roster);

  Future<void> pump(WidgetTester tester, AttendanceBloc bloc) async {
    await tester.pumpWidget(
      MaterialApp(home: TeacherAttendanceScreen(bloc: bloc, classes: classes)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('roster displays one row per child', (tester) async {
    final bloc = buildBloc();
    await pump(tester, bloc);

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);

    // One toggle group per child.
    for (final c in roster) {
      expect(find.byKey(Key('toggle_${c.childId}')), findsOneWidget);
    }
  });

  testWidgets("toggling a child's status updates the bloc state", (tester) async {
    final bloc = buildBloc();
    await pump(tester, bloc);

    // Default is present.
    expect(bloc.state.statusFor(101), AttendanceStatus.present);

    // Tap "Absent" (third button) for Alice's toggle group.
    final absentLabel = find.descendant(
      of: find.byKey(const Key('toggle_101')),
      matching: find.text('Absent'),
    );
    await tester.tap(absentLabel);
    await tester.pumpAndSettle();

    expect(bloc.state.statusFor(101), AttendanceStatus.absent);
    expect(bloc.state.selectedStatuses[101], AttendanceStatus.absent);
  });

  testWidgets('submit sends the correct bulk payload to the repo', (tester) async {
    when(() => repo.markBulk(
          classId: any(named: 'classId'),
          date: any(named: 'date'),
          records: any(named: 'records'),
        )).thenAnswer((_) async => const Right<Failure, List<AttendanceModel>>([]));

    final bloc = buildBloc();
    await pump(tester, bloc);

    // Set Bob to late, leave others present.
    final lateLabel = find.descendant(
      of: find.byKey(const Key('toggle_102')),
      matching: find.text('Late'),
    );
    await tester.tap(lateLabel);
    await tester.pumpAndSettle();

    // Submit.
    await tester.tap(find.byKey(const Key('submit_attendance')));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.markBulk(
          classId: captureAny(named: 'classId'),
          date: captureAny(named: 'date'),
          records: captureAny(named: 'records'),
        )).captured;

    expect(captured[0], 1); // classId
    final records = captured[2] as List;
    expect(records.length, 3);

    final byChild = {for (final r in records) r['child_id'] as int: r['status']};
    expect(byChild[101], 'present');
    expect(byChild[102], 'late');
    expect(byChild[103], 'present');
  });
}
