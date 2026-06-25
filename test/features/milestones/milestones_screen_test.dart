import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/milestones/bloc/milestone_bloc.dart';
import 'package:escola/features/milestones/model/milestone_model.dart';
import 'package:escola/features/milestones/presentation/milestones_screen.dart';
import 'package:escola/features/milestones/repo/milestone_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMilestoneRepo extends Mock implements MilestoneRepo {}

MilestoneBloc _bloc(MilestoneRepo repo, {bool asTeacher = false}) =>
    MilestoneBloc(repo, childId: 1, asTeacher: asTeacher);

List<MilestoneModel> _sampleMilestones() => const [
      MilestoneModel(
        id: 1,
        domain: 'social',
        ageBandMin: 0,
        ageBandMax: 12,
        descriptionAr: 'يبتسم',
      ),
      MilestoneModel(
        id: 2,
        domain: 'language',
        ageBandMin: 0,
        ageBandMax: 12,
        descriptionAr: 'يقول كلمته الأولى',
      ),
      MilestoneModel(
        id: 3,
        domain: 'cognitive',
        ageBandMin: 0,
        ageBandMax: 12,
        descriptionAr: 'يتابع الأشياء',
      ),
      MilestoneModel(
        id: 4,
        domain: 'motor',
        ageBandMin: 0,
        ageBandMax: 12,
        descriptionAr: 'يجلس',
      ),
    ];

void _stubGet(MilestoneRepo repo, List<MilestoneModel> data) {
  when(() => repo.getChildMilestones(
        any(),
        asTeacher: any(named: 'asTeacher'),
      )).thenAnswer((_) async => Right<Failure, List<MilestoneModel>>(data));
}

void main() {
  testWidgets('renders the four domain tabs', (tester) async {
    final repo = MockMilestoneRepo();
    _stubGet(repo, _sampleMilestones());

    final bloc = _bloc(repo);

    await tester.pumpWidget(MaterialApp(home: MilestonesScreen(bloc: bloc)));
    await tester.pumpAndSettle();

    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Cognitive'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);
  });

  testWidgets('teacher toggling a milestone marks it reached in the bloc', (tester) async {
    final repo = MockMilestoneRepo();
    _stubGet(repo, _sampleMilestones());
    when(() => repo.mark(
          childId: any(named: 'childId'),
          milestoneId: any(named: 'milestoneId'),
          notes: any(named: 'notes'),
          observedAt: any(named: 'observedAt'),
        )).thenAnswer((_) async => const Right<Failure, bool>(true));

    final bloc = _bloc(repo, asTeacher: true);

    await tester.pumpWidget(MaterialApp(home: MilestonesScreen(bloc: bloc)));
    await tester.pumpAndSettle();

    // The first (social) tab shows an unchecked checkbox for milestone id 1.
    expect(bloc.state.data.firstWhere((m) => m.id == 1).reached, isFalse);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    verify(() => repo.mark(
          childId: 1,
          milestoneId: 1,
          notes: any(named: 'notes'),
          observedAt: any(named: 'observedAt'),
        )).called(1);

    // Bloc state reflects the milestone is now reached.
    expect(bloc.state.data.firstWhere((m) => m.id == 1).reached, isTrue);
  });

  testWidgets('overdue milestone shows the amber specialist prompt', (tester) async {
    final repo = MockMilestoneRepo();
    _stubGet(repo, const [
      MilestoneModel(
        id: 10,
        domain: 'social',
        ageBandMin: 0,
        ageBandMax: 12,
        descriptionAr: 'يبتسم',
        reached: false,
        overdue: true,
      ),
    ]);

    final bloc = _bloc(repo);

    await tester.pumpWidget(MaterialApp(home: MilestonesScreen(bloc: bloc)));
    await tester.pumpAndSettle();

    final finder = find.text(kMilestoneOverdueText);
    expect(finder, findsOneWidget);

    final Text widget = tester.widget(finder);
    expect(widget.style?.color, Colors.amber);
  });
}
