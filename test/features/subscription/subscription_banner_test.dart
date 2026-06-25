import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/subscription/bloc/subscription_bloc.dart';
import 'package:escola/features/subscription/model/subscription_model.dart';
import 'package:escola/features/subscription/presentation/subscription_expired_screen.dart';
import 'package:escola/features/subscription/presentation/subscription_gate.dart';
import 'package:escola/features/subscription/presentation/widgets/subscription_banner.dart';
import 'package:escola/features/subscription/repo/subscription_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubscriptionRepo extends Mock implements SubscriptionRepo {}

SubscriptionBloc _bloc(SubscriptionRepo repo) => SubscriptionBloc(repo);

void main() {
  // (1) Amber trial banner shows the number of days remaining.
  testWidgets('amber trial banner shows days remaining', (tester) async {
    final repo = MockSubscriptionRepo();
    when(() => repo.getSubscription()).thenAnswer(
      (_) async => const Right<Failure, SubscriptionModel>(
        SubscriptionModel(
          id: 1,
          plan: 'trial',
          status: 'trial',
          daysRemaining: 5,
          isExpired: false,
        ),
      ),
    );

    final bloc = _bloc(repo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionGate(
            bloc: bloc,
            child: const Text('dashboard'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Amber-keyed banner is present.
    expect(find.byKey(SubscriptionBanner.amberTrialKey), findsOneWidget);

    // The number of days remaining ('5') is rendered.
    expect(find.text('5'), findsOneWidget);

    // The amber colour is applied to the banner border.
    final container = tester.widget<Container>(
      find.byKey(SubscriptionBanner.amberTrialKey),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.border!.top.color, SubscriptionBanner.amber);

    // The dashboard is still shown (not blocked).
    expect(find.text('dashboard'), findsOneWidget);
    expect(find.byKey(SubscriptionExpiredScreen.blockingKey), findsNothing);
  });

  // (2) Expired status shows the full-screen blocking widget and hides the app.
  testWidgets('expired subscription blocks the app', (tester) async {
    final repo = MockSubscriptionRepo();
    when(() => repo.getSubscription()).thenAnswer(
      (_) async => const Right<Failure, SubscriptionModel>(
        SubscriptionModel(
          id: 1,
          plan: 'monthly',
          status: 'expired',
          daysRemaining: -3,
          isExpired: true,
        ),
      ),
    );

    final bloc = _bloc(repo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionGate(
            bloc: bloc,
            child: const Text('dashboard'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The blocking widget is shown.
    expect(find.byKey(SubscriptionExpiredScreen.blockingKey), findsOneWidget);
    expect(find.text('Subscription expired'), findsOneWidget);

    // The underlying dashboard is NOT shown (navigation/use is blocked).
    expect(find.text('dashboard'), findsNothing);
    expect(find.byKey(SubscriptionBanner.amberTrialKey), findsNothing);
  });
}
