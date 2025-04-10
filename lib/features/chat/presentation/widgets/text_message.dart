import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TextMessage extends StatelessWidget {
  final Message message;
  const TextMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<ChatBloc>().currentUser?.id;
    final sendId = message.sender.id;
    final isSend = userId == sendId;

    return ConfigSelector(
      selector: (config) => config.styling,
      builder:(context, state) => Container(
        padding: EdgeInsetsDirectional.fromSTEB(15.w, 15.h, 25.w, 15.h),
        constraints: BoxConstraints(maxWidth: getRelativeWidth(0.75)),
        decoration: BoxDecoration(
            color: !isSend ? ChatColors.contactMessageBackgroundColor : ChatColors.userMessageBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: isSend ? const Radius.circular(21) : const Radius.circular(5),
              bottomRight: const Radius.circular(21),
              topRight: isSend ? const Radius.circular(5) : const Radius.circular(21),
              bottomLeft: const Radius.circular(21),
            )),
        child: Text(
          message.content,
          style: TextStyle(
              color: isSend ? Colors.black : ChatColors.contactNameColor, fontSize: 16.sp, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
