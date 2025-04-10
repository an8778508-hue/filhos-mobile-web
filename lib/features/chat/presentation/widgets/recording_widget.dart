import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';

import 'package:escola/features/chat/presentation/widgets/send_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordingWidget extends StatelessWidget {
  const RecordingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recordTime = context.watch<AudioBloc>().currentRecordTime;

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.read<AudioBloc>().add(DeleteRecording());
          },
          icon: Icon(Icons.delete,
              size: 25.w, color: ChatColors.actionIconsColor),
        ),
        Expanded(
          child: Container(
            height: 45.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(recordTime.toString().substring(2, 7),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ),
        SendButton(
          onPressed: () =>
              context.read<AudioBloc>().add(SendRecordingMessage()),
        ),
      ],
    );
  }
}
