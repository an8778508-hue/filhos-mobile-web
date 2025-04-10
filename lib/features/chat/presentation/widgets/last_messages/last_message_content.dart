import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LastMessageContent extends StatelessWidget {
  final Message message;
  const LastMessageContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final sendByCurrentUser = context.read<ChatBloc>().currentUser?.id == message.sender.id;
    final String senderName =
        (sendByCurrentUser || message.child == null || message.sender.name == null) ? "" : "${message.sender.name} : ";

    if (message.type == MessageType.image) {
      return Row(
        children: [
          Icon(
            Icons.camera_alt_rounded,
            color: ChatColors.messageContentColor,
            size: 25.w,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              "$senderName Image",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: ChatColors.messageContentColor,
              ),
            ),
          ),
        ],
      );
    } else if (message.type == MessageType.audio) {
      return Row(
        children: [
          Icon(
            Icons.mic_rounded,
            color: ChatColors.messageContentColor,
            size: 25.w,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              "$senderName Audio",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: ChatColors.messageContentColor,
              ),
            ),
          ),
        ],
      );
    } else if (message.type == MessageType.file) {
      final isVideo = ChatHelper.isVideoFile(message.content);
      return Row(
        children: [
          Icon(
            isVideo ? Icons.slow_motion_video : Icons.file_present,
            color: ChatColors.messageContentColor,
            size: 25.w,
          ),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              "$senderName ${isVideo ? LocalizationKeys.video.tr(context) : LocalizationKeys.file.tr(context)}",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: ChatColors.messageContentColor,
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      senderName + message.content,
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: ChatColors.messageContentColor),
    );
  }
}
