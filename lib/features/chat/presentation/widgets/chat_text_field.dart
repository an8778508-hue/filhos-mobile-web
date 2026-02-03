import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/text_message_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatTextField extends StatelessWidget {
  const ChatTextField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: ChatColors.backgroundTextField,
        borderRadius: BorderRadius.circular(22.5),
      ),
      child: Center(
        child: TextFormField(
          controller: context.watch<TextMessageBloc>().controller,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (value) {
            context.read<TextMessageBloc>().add(SendTextMessage());
          },
          onTapOutside: (value) {
            // unfocus
            FocusScope.of(context).unfocus();
          },
          onChanged: (value) {
            context
                .read<TextMessageBloc>()
                .add(UpdateMessageContent(content: value));
          },
          style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintStyle: TextStyle(
                color: const Color(0xffA9B1C3),
                fontSize: 16.sp,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w400),
            contentPadding: EdgeInsets.symmetric(horizontal: 15.w),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22.5),
                borderSide: BorderSide.none),
            hintText: LocalizationKeys.chat.tr(context),
          ),
        ),
      ),
    );
  }
}
