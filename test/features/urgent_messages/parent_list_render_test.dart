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
  testWidgets('Parent screen renders both message titles', (tester) async {
    final repo = MockUrgentMessageRepo();

    const messages = [
      UrgentMessageModel(id: 1, title: 'First Urgent', description: 'desc 1', isRead: false),
      UrgentMessageModel(id: 2, title: 'Second Urgent', description: 'desc 2', isRead: true),
    ];

    when(() => repo.getMessages())
        .thenAnswer((_) async => const Right<Failure, List<UrgentMessageModel>>(messages));

    final bloc = UrgentMessageBloc(repo);

    await tester.pumpWidget(
      MaterialApp(home: ParentUrgentMessagesScreen(bloc: bloc)),
    );

    await bloc.fetch();
    await tester.pumpAndSettle();

    expect(find.text('First Urgent'), findsOneWidget);
    expect(find.text('Second Urgent'), findsOneWidget);
  });
}
