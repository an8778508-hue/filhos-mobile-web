import 'package:escola/features/urgent_messages/bloc/urgent_message_bloc.dart';
import 'package:escola/features/urgent_messages/bloc/urgent_message_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ParentUrgentMessagesScreen extends StatelessWidget {
  final UrgentMessageBloc bloc;

  const ParentUrgentMessagesScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<UrgentMessageBloc, UrgentMessageState>(
            builder: (context, state) {
              final unread = state.unreadCount;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Urgent Messages'),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        body: BlocBuilder<UrgentMessageBloc, UrgentMessageState>(
          builder: (context, state) {
            final ms = state.messagesState;
            if (ms.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.data.isEmpty) {
              return const Center(child: Text('No urgent messages'));
            }
            return ListView.builder(
              itemCount: state.data.length,
              itemBuilder: (context, index) {
                final item = state.data[index];
                return ListTile(
                  leading: !item.isRead
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox(width: 10, height: 10),
                  title: Text(item.title),
                  subtitle: Text(item.description),
                  onTap: () {
                    if (!item.isRead) {
                      bloc.markRead(item.id);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
