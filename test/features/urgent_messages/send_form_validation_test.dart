import 'package:escola/features/urgent_messages/presentation/send_urgent_message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Send with empty fields shows validation errors and does not call onSend',
      (tester) async {
    var sendCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SendUrgentMessageScreen(
          parents: const [
            {'id': 1, 'name': 'Parent One'},
          ],
          onSend: ({required parentId, required title, required description}) {
            sendCalled = true;
          },
        ),
      ),
    );

    // Tap Send without filling anything.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
    await tester.pumpAndSettle();

    // Validation messages should be visible.
    expect(find.text('Please select a parent'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);

    // Callback must NOT have been invoked.
    expect(sendCalled, isFalse);
  });
}
