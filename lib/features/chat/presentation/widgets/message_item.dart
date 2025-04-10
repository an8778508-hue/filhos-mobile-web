import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/utils/funuctions/date_functions.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:escola/features/chat/presentation/widgets/Image_message.dart';
import 'package:escola/features/chat/presentation/widgets/audio_message.dart';
import 'package:escola/features/chat/presentation/widgets/file_message.dart';
import 'package:escola/features/chat/presentation/widgets/text_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  const MessageItem({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<ChatBloc>().currentUser?.id;
    final sendId = message.sender.id;
    final sendByCurrentUser = userId == sendId;
    return Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: sendByCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!sendByCurrentUser) ...[
                Avatar(
                  size: 40.w,
                  avatar: message.sender.avatar,
                ),
                SizedBox(width: 10.w)
              ],
              Container(
                margin: EdgeInsets.only(bottom: 5.h),
                child: Column(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: sendByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!sendByCurrentUser && message.child != null && message.sender.name != null) ...[
                      Text(
                        message.sender.name!,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5.h)
                    ],
                    if (message.type == MessageType.audio) ...[
                      const SizedBox(),
                      AudioMessage(message: message),
                    ] else if (message.type == MessageType.file) ...[
                      const SizedBox(),
                      FileMessage(message: message)
                    ] else if (message.type == MessageType.image) ...[
                      ImageMessage(message: message)
                    ] else ...[
                      TextMessage(message: message),
                    ],
                    SizedBox(height: 9.h),
                    if (message.dateTime != null)
                      Align(
                        child: Text(
                          DateFunctions.formatDayMonthYearHourMin((message.dateTime!)),
                          style: TextStyle(
                            color: ChatColors.messageDateColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ]);
  }

// format date and time if today show time only else show date and time
  String getFormatedDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (aDate == today) {
      return DateFunctions.formatTimeTo12HourFormat(dateTime);
    } else {
      return DateFunctions.formatDate(dateTime);
    }
  }
}
