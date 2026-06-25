import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A square thumbnail for a video answer: shows the thumbnail image with a
/// centered, semi-transparent play button overlay.
///
/// Self-contained so it can be used both in the diary "add" form (showing a
/// freshly-picked local video's poster) and in the parent timeline (showing a
/// server-returned `video_thumbnail_path`). The image source is resolved from
/// the path: an `http`/`https` path is loaded over the network, anything else
/// is treated as a local file.
class VideoThumbnail extends StatelessWidget {
  /// Thumbnail image path. May be a remote URL or a local file path. When
  /// null/empty a neutral placeholder background is shown (still with the play
  /// button), so a video without a poster still reads as "tap to play".
  final String? thumbnailPath;

  /// Tapping the thumbnail (typically opens the inline player).
  final VoidCallback? onTap;

  final double? size;

  const VideoThumbnail({
    super.key,
    this.thumbnailPath,
    this.onTap,
    this.size,
  });

  bool get _isNetwork {
    final path = thumbnailPath;
    return path != null && (path.startsWith('http://') || path.startsWith('https://'));
  }

  bool get _hasThumbnail => thumbnailPath != null && thumbnailPath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double dimension = size ?? 100.w;

    Widget background;
    if (!_hasThumbnail) {
      background = Container(color: Colors.black12);
    } else if (_isNetwork) {
      background = Image.network(
        thumbnailPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black12),
      );
    } else {
      background = Image.file(
        File(thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black12),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.w),
        child: SizedBox(
          width: dimension,
          height: dimension,
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              // Centered play button overlay.
              Center(
                child: Container(
                  key: const ValueKey('video_play_button'),
                  width: dimension * 0.34,
                  height: dimension * 0.34,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
