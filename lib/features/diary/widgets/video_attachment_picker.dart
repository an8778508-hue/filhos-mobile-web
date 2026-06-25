import 'package:escola/core/attachment_selection/attachment_selection.dart';
import 'package:escola/features/diary/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Self-contained "pick a video" affordance for the diary add form.
///
/// Renders, beside the existing image picker:
///  * an "Add video" button (uses the core [pickVideo]),
///  * a [VideoThumbnail] preview of the picked video (with play overlay), and
///  * an upload progress indicator while [isUploading] is true.
///
/// Kept minimal and stateless about networking — the parent owns the selected
/// path and the upload lifecycle. This is to avoid entangling the large,
/// existing diary form while still wiring the new capability in.
class VideoAttachmentPicker extends StatelessWidget {
  /// Local path of the currently-selected video, if any.
  final String? selectedVideoPath;

  /// Called with the picked local video path (or null if the user cancels).
  final ValueChanged<String?> onVideoPicked;

  /// Called when the user removes the selected video.
  final VoidCallback? onRemove;

  /// When true an upload progress indicator is shown over the thumbnail.
  final bool isUploading;

  /// Optional upload progress (0.0–1.0). When null an indeterminate spinner is
  /// shown; otherwise a determinate [CircularProgressIndicator] is used.
  final double? uploadProgress;

  const VideoAttachmentPicker({
    super.key,
    required this.onVideoPicked,
    this.selectedVideoPath,
    this.onRemove,
    this.isUploading = false,
    this.uploadProgress,
  });

  bool get _hasVideo => selectedVideoPath != null && selectedVideoPath!.isNotEmpty;

  Future<void> _pick(BuildContext context) async {
    final paths = await pickVideo(context);
    onVideoPicked(paths.isNotEmpty ? paths.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasVideo)
          Stack(
            children: [
              VideoThumbnail(thumbnailPath: selectedVideoPath),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: uploadProgress,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (!isUploading && onRemove != null)
                PositionedDirectional(
                  top: 4.w,
                  end: 4.w,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      key: const ValueKey('remove_video_button'),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 18.w),
                    ),
                  ),
                ),
            ],
          )
        else
          OutlinedButton.icon(
            key: const ValueKey('add_video_button'),
            onPressed: isUploading ? null : () => _pick(context),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Add video'),
          ),
        if (isUploading && !_hasVideo) ...[
          SizedBox(height: 8.w),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
