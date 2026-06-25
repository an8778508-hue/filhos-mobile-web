import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/allergies/bloc/allergy_bloc.dart';
import 'package:escola/features/allergies/model/allergy_model.dart';
import 'package:escola/features/allergies/presentation/allergy_section.dart';
import 'package:escola/features/allergies/repo/allergy_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAllergyRepo extends Mock implements AllergyRepo {}

AllergyModel _allergy(int id, String allergen, {String severity = 'mild'}) => AllergyModel(
      id: id,
      allergen: allergen,
      severity: severity,
      reactionDescription: 'Reaction $id',
      actionToTake: 'Action $id',
      childId: 1,
    );

void main() {
  late MockAllergyRepo repo;

  setUp(() {
    repo = MockAllergyRepo();
  });

  Future<void> pump(WidgetTester tester, AllergyBloc bloc, {bool canEdit = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AllergySection(bloc: bloc, canEdit: canEdit),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('list renders one row per allergy returned by the repo', (tester) async {
    final allergies = [
      _allergy(1, 'Peanuts', severity: 'severe'),
      _allergy(2, 'Eggs', severity: 'moderate'),
      _allergy(3, 'Dust', severity: 'mild'),
    ];

    when(() => repo.getForChild(any(), prefix: any(named: 'prefix')))
        .thenAnswer((_) async => Right<Failure, List<AllergyModel>>(allergies));

    final bloc = AllergyBloc(repo, childId: 1, prefix: 'teacher');
    await bloc.fetch();

    await pump(tester, bloc);

    expect(find.text('Peanuts'), findsOneWidget);
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Dust'), findsOneWidget);

    for (final a in allergies) {
      expect(find.byKey(Key('allergy_row_${a.id}')), findsOneWidget);
    }
  });

  testWidgets('red badge is visible when allergies exist', (tester) async {
    when(() => repo.getForChild(any(), prefix: any(named: 'prefix')))
        .thenAnswer((_) async => Right<Failure, List<AllergyModel>>([
              _allergy(1, 'Peanuts', severity: 'severe'),
              _allergy(2, 'Eggs', severity: 'moderate'),
            ]));

    final bloc = AllergyBloc(repo, childId: 1, prefix: 'parent');
    await bloc.fetch();

    await pump(tester, bloc);

    final badge = find.byKey(const Key('allergy_badge'));
    expect(badge, findsOneWidget);

    // Badge container is red.
    final container = tester.widget<Container>(badge);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.red);

    // Shows the count.
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('red badge is absent when there are no allergies', (tester) async {
    when(() => repo.getForChild(any(), prefix: any(named: 'prefix')))
        .thenAnswer((_) async => const Right<Failure, List<AllergyModel>>([]));

    final bloc = AllergyBloc(repo, childId: 1, prefix: 'parent');
    await bloc.fetch();

    await pump(tester, bloc);

    expect(find.byKey(const Key('allergy_badge')), findsNothing);
    expect(find.text('No allergies recorded'), findsOneWidget);
  });
}
