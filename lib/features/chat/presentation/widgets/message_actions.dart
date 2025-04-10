import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/images_message_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/text_message_bloc.dart';
import 'package:escola/features/chat/presentation/widgets/camera_icon.dart';
import 'package:escola/features/chat/presentation/widgets/chat_text_field.dart';
import 'package:escola/features/chat/presentation/widgets/gallery_files.dart';
import 'package:escola/features/chat/presentation/widgets/gallery_icon.dart';
import 'package:escola/features/chat/presentation/widgets/mic_icon.dart';
import 'package:escola/features/chat/presentation/widgets/recording_widget.dart';
import 'package:escola/features/chat/presentation/widgets/send_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatActions extends StatefulWidget {
  const ChatActions({super.key});

  @override
  State<ChatActions> createState() => _ChatActionsState();
}

class _ChatActionsState extends State<ChatActions> {
  @override
  Widget build(BuildContext context) {
    final images = context.watch<ImagesMessageBloc>().imagesInTheField;
    final recordingState = context.watch<AudioBloc>().recordingState;
    if (images.isNotEmpty) return const GalleryFiles();
    if (recordingState == RecordingState.recording) {
      return const RecordingWidget();
    }
    return Row(
      children: [
        const GalleryIcon(),
        const SizedBox(width: 5),
        const CameraIcon(),
        const MicWidget(),
        const SizedBox(width: 5),
        const Expanded(child: ChatTextField()),
        const SizedBox(width: 10),
        SendButton(
          onPressed: () =>
              context.read<TextMessageBloc>().add(SendTextMessage()),
        ),
      ],
    );
  }
}
