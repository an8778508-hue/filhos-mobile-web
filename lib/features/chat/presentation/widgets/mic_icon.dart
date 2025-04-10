import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MicWidget extends StatelessWidget {
  const MicWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<AudioBloc>().add(StartRecording()),
      onLongPress: () => context.read<AudioBloc>().add(StartRecording()),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Icon(Icons.mic_none, color: const Color(0xff818181), size: 25.w),
      ),
    );
  }
}
