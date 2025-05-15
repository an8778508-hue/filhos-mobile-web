import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/utils/funuctions/date_functions.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:escola/features/chat/presentation/widgets/last_messages/last_message_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LastMessageItem extends StatelessWidget {
  final LastMessage lastMessage;
  const LastMessageItem({
    required this.lastMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<ChatBloc>().currentUser;
    final message = lastMessage.message;

    final ChatUser contact = message.sender.id == currentUser?.id ? message.reciever : message.sender;

    final int unReadMessagesCount = lastMessage.unReadCount ?? 0;

    final child = lastMessage.message.child;

    final avatar = child != null ? child.avatar : contact.avatar;

    String name = ChatBloc.getContactFullName(context, contact, child?.name) ?? "";

    return GestureDetector(
      onTap: () {
        WidgetFunctions.navigateTo(
            context,
            ChatScreen(
              contact: contact,
              child: lastMessage.message.child,
            ));
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              avatar: avatar,
              isChild: lastMessage.message.child != null,
              size: 50.w,
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: ChatColors.contactNameColor,
                          ),
                        ),
                        LastMessageContent(message: message)
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (unReadMessagesCount > 0) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unReadMessagesCount.toString(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w)
                      ],
                      if (message.dateTime != null) ...[
                        Text(
                          DateFunctions.formatDetailedTimestamp(message.dateTime),
                          style: TextStyle(
                              fontSize: 14.sp, fontWeight: FontWeight.w400, color: ChatColors.messageDateColor),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget adjustContent() {
}
