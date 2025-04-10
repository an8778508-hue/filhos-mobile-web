import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:escola/core/components/loading/loading.dart';

class AudioMessage extends StatefulWidget {
  final Message message;
  const AudioMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<ChatBloc>().currentUser?.id;
    final sendId = widget.message.sender.id;
    final isSend = userId == sendId;

    final AudioPlayer? audioPlayer = context.watch<AudioBloc>().messagesAudioPlayers[widget.message.id];

    final int currentProgressSeconds =
        context.watch<AudioBloc>().audioPlayersPosition[widget.message.id]?.inSeconds ?? 0;

    final PlayState playState =
        context.watch<AudioBloc>().audioPlayersIsPlaying[widget.message.id] ?? PlayState.loading;

    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        return Stack(
          children: [
            Container(
              width: getRelativeWidth(0.5),
              constraints: BoxConstraints(maxWidth: getRelativeWidth(0.75)),
              decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: isSend ? const Radius.circular(21) : const Radius.circular(5),
                    bottomRight: const Radius.circular(21),
                    topRight: isSend ? const Radius.circular(5) : const Radius.circular(21),
                    bottomLeft: const Radius.circular(21),
                  )),
              child: Container(
                padding: EdgeInsets.only(left: 5.w, right: 15.w, top: 5.h, bottom: 5.h),
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (playState != PlayState.loading) {
                          if (playState != PlayState.playing) {
                            context.read<AudioBloc>().add(PlayAudio(message: widget.message));
                          } else {
                            context.read<AudioBloc>().add(PauseAudio(message: widget.message));
                          }
                        }
                      },
                      child: Container(
                        width: 35.w,
                        height: 35.w,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Icon(
                            playState == PlayState.playing ? Icons.pause : Icons.play_arrow,
                            color: context.colors.primary,
                            size: 25.w,
                          ),
                        ),
                      ),
                    ),
                    if (playState == PlayState.loading) ...[
                      SizedBox(
                        width: 15.w,
                        height: 15.w,
                        child: Loading(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      ),
                    ] else ...[
                      Text(
                        getTimeFromDuration(playState, audioPlayer, currentProgressSeconds),
                        style: TextStyle(color: Colors.white, fontSize: 12.w, fontWeight: FontWeight.w900),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

int getSecondsDifference(AudioPlayer? audioPlayer, int currentProgress) {
  final Duration totalDuration = audioPlayer?.duration ?? Duration.zero;
  final int totalSeconds = totalDuration.inSeconds;
  final int currentSeconds = currentProgress;
  // final Duration durationDifference = totalDuration - currentProgress;
  final int durationDifferenceSeconds = totalSeconds - currentSeconds;
  final int result = durationDifferenceSeconds > 0 ? durationDifferenceSeconds : totalSeconds;
  return result;
  // final diff = durationDifference > Duration.zero ? durationDifference : totalDuration;
  // if (diff.inSeconds == 0) return totalDuration;
  // return diff;
}

// // converts duratino to formate mm:ss
// String getTime(AudioPlayer? audioPlayer, int currentProgress) {
//   return getTimeFromDuration(getSecondsDifference(audioPlayer, currentProgress));
// }

String getTimeFromDuration(PlayState playState, AudioPlayer? audioPlayer, int secondsValue) {
  final int totalDuration = audioPlayer?.duration?.inSeconds ?? 0;
  int seconds = secondsValue > 0 ? secondsValue : totalDuration;
  if (playState == PlayState.notPlaying) seconds = totalDuration;
  final int minutes = seconds ~/ 60;
  final int remainingSeconds = seconds % 60;
  final String minutesString = minutes < 10 ? "0$minutes" : "$minutes";
  final String secondsString = remainingSeconds < 10 ? "0$remainingSeconds" : "$remainingSeconds";
  return "$minutesString:$secondsString";
  // if (duration == null) return ""; // "00:00";
  // String twoDigits(int n) => n.toString().padLeft(2, "0");
  // String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  // String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  // return "$twoDigitMinutes:$twoDigitSeconds";
}
