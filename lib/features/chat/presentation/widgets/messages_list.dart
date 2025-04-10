import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/widgets/empty_messages.dart';
import 'package:escola/features/chat/presentation/widgets/message_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessagesList extends StatefulWidget {
  const MessagesList({super.key});

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reversedMessages = context.read<ChatBloc>().messages.reversed.toList();

    final state = context.watch<ChatBloc>().state;

    if (reversedMessages.isEmpty && state is! MessagesLoading) {
      return const EmptyMessages();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      child: ListView.builder(
          reverse: true,
          shrinkWrap: true,
          controller: _scrollController,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          itemBuilder: (context, index) {
            final message = reversedMessages[index];
            return MessageItem(message: message);
          },
          itemCount: reversedMessages.length),
    );
  }
}
