import 'package:escola/core/components/icons/document_widget.dart';
import 'package:escola/core/components/video/video_player_widget.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class FileMessage extends StatelessWidget {
  final Message message;
  const FileMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isVideoFile = ChatHelper.isVideoFile(message.content);
    return isVideoFile
        ? SizedBox(width: 150.w, height: 150.h, child: VideoPlayerWidget(url: message.content))
        : GestureDetector(
            onTap: () => _launchUrl(), child: DocumentWidget(url: ChatHelper.getFileName(message.content)));
  }

  Future<void> _launchUrl() async {
    final Uri _url = Uri.parse(message.content);

    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}
