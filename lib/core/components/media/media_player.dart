import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/video/video_player_widget.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MediaPLayer extends StatelessWidget {
  final String? url;
  const MediaPLayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final ext = url?.split('.').last ?? "";
    final fileIsImage = isImage(ext);
    final fileIsVideo = isVideo(ext);
    return fileIsImage
        ? CommonImage(imageUrl: url, fit: BoxFit.cover)
        : fileIsVideo
            ? VideoPlayerWidget(url: url ?? "")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_copy_outlined,
                    color: context.colors.primary,
                    size: 24.sp,
                  ),
                  Text(
                    ext,
                    style: TextStyle(
                      color: context.colors.primaryLight,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
  }
}
