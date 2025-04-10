import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/presentation/widgets/last_messages/last_message_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LastMessagesList extends StatelessWidget {
  final List<LastMessage> lastMessages;
  const LastMessagesList({
    super.key,
    required this.lastMessages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: lastMessages.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(top: 28.h),
      itemBuilder: (context, index) {
        final lastMessage = lastMessages[index];
        final isLast = index == lastMessages.length - 1;
        return LastMessageColumn(isLast: isLast, lastMessage: lastMessage);
      },
    );
  }
}

class LastMessageColumn extends StatelessWidget {
  final LastMessage lastMessage;
  final bool isLast;

  const LastMessageColumn({super.key, required this.lastMessage, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LastMessageItem(lastMessage: lastMessage),
        if (!isLast) ...[
          SizedBox(height: 16.h),
          Container(
            width: 300.w,
            height: 2.h,
            color: const Color(0xffececec),
          ),
          SizedBox(height: 16.h),
        ]
      ],
    );
  }
}
