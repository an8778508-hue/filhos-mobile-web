import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/urgent_messages/bloc/urgent_message_bloc.dart';
import 'package:escola/features/urgent_messages/model/urgent_message_model.dart';
import 'package:escola/features/urgent_messages/presentation/parent_urgent_messages_screen.dart';
import 'package:escola/features/urgent_messages/repo/urgent_message_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUrgentMessageRepo extends Mock implements UrgentMessageRepo {}

void main() {
  testWidgets('Unread badge drops from 2 to 1 after marking one read', (tester) async {
    final repo = MockUrgentMessageRepo();

    const messages = [
      UrgentMessageModel(id: 1, title: 'First Urgent', description: 'desc 1', isRead: false),
      UrgentMessageModel(id: 2, title: 'Second Urgent', description: 'desc 2', isRead: false),
    ];

    // markRead returns the same item with is_read = true.
    when(() => repo.markRead(1)).thenAnswer(
      (_) async => Right<Failure, UrgentMessageModel>(
        messages[0].copyWith(isRead: true, readAt: '2026-06-25'),
      ),
    );

    final bloc = UrgentMessageBloc(repo);
    bloc.seed(messages);

    await tester.pumpWidget(
      MaterialApp(home: ParentUrgentMessagesScreen(bloc: bloc)),
    );
    await tester.pumpAndSettle();

    // Badge should show 2 unread.
    expect(find.text('2'), findsOneWidget);

    // Tap the first (unread) item -> triggers markRead(1).
    await tester.tap(find.text('First Urgent'));
    await tester.pumpAndSettle();

    // Badge should now show 1 unread.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });
}
