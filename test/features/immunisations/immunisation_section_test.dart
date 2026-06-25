import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/immunisations/bloc/immunisation_bloc.dart';
import 'package:escola/features/immunisations/model/immunisation_model.dart';
import 'package:escola/features/immunisations/presentation/immunisation_section.dart';
import 'package:escola/features/immunisations/repo/immunisation_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockImmunisationRepo extends Mock implements ImmunisationRepo {}

ImmunisationModel _immunisation(
  int id,
  String name, {
  bool isDueSoon = false,
  String? nextDueDate,
}) =>
    ImmunisationModel(
      id: id,
      vaccineName: name,
      dateGiven: '2026-01-01',
      nextDueDate: nextDueDate,
      notes: 'Notes $id',
      childId: 1,
      isDueSoon: isDueSoon,
    );

void main() {
  late MockImmunisationRepo repo;

  setUp(() {
    repo = MockImmunisationRepo();
  });

  Future<void> pump(WidgetTester tester, ImmunisationBloc bloc, {bool canEdit = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ImmunisationSection(bloc: bloc, canEdit: canEdit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list renders one row per immunisation returned by the repo', (tester) async {
    final records = [
      _immunisation(1, 'MMR'),
      _immunisation(2, 'Polio'),
      _immunisation(3, 'Hepatitis B'),
    ];

    when(() => repo.getForChild(any(), prefix: any(named: 'prefix')))
        .thenAnswer((_) async => Right<Failure, List<ImmunisationModel>>(records));

    final bloc = ImmunisationBloc(repo, childId: 1, prefix: 'teacher');
    await bloc.fetch();

    await pump(tester, bloc);

    expect(find.text('MMR'), findsOneWidget);
    expect(find.text('Polio'), findsOneWidget);
    expect(find.text('Hepatitis B'), findsOneWidget);

    for (final r in records) {
      expect(find.byKey(Key('immunisation_row_${r.id}')), findsOneWidget);
    }
  });

  testWidgets('amber highlight appears only on due-soon records', (tester) async {
    final dueSoon = _immunisation(1, 'MMR', isDueSoon: true, nextDueDate: '2026-07-01');
    final notDue = _immunisation(2, 'Polio', isDueSoon: false, nextDueDate: '2027-01-01');

    when(() => repo.getForChild(any(), prefix: any(named: 'prefix')))
        .thenAnswer((_) async => Right<Failure, List<ImmunisationModel>>([dueSoon, notDue]));

    final bloc = ImmunisationBloc(repo, childId: 1, prefix: 'parent');
    await bloc.fetch();

    await pump(tester, bloc);

    // The due-soon record carries the amber-highlight container + badge.
    final dueSoonContainerFinder = find.byKey(Key('immunisation_due_soon_${dueSoon.id}'));
    expect(dueSoonContainerFinder, findsOneWidget);
    expect(find.byKey(Key('immunisation_due_badge_${dueSoon.id}')), findsOneWidget);

    // Its decoration uses the amber colour.
    final container = tester.widget<Container>(dueSoonContainerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, ImmunisationSection.dueSoonColor.withOpacity(0.25));
    expect(decoration.border, isNotNull);

    // The not-due record has neither the highlight container nor the badge.
    expect(find.byKey(Key('immunisation_due_soon_${notDue.id}')), findsNothing);
    expect(find.byKey(Key('immunisation_due_badge_${notDue.id}')), findsNothing);

    // Both rows still render.
    expect(find.byKey(Key('immunisation_row_${dueSoon.id}')), findsOneWidget);
    expect(find.byKey(Key('immunisation_row_${notDue.id}')), findsOneWidget);
  });
}
