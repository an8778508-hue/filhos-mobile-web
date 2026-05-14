import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Network-URL video player.
///
/// Swapped from `appinio_video_player_plus` to the stock `video_player`
/// package on 2026-05-14 so `flutter build web` compiles (appinio's
/// `web_video_player/native_web_video_player.dart` referenced
/// `ui.platformViewRegistry` which was moved out of `dart:ui` in newer
/// Flutter versions).
///
/// This implementation drops the custom controls (settings button,
/// fullscreen button, duration overlays) that appinio provided. If those
/// are needed, layer a controls UI on top of `VideoPlayer(controller)`,
/// or pull in a maintained controls package (e.g. `chewie`).
class VideoPlayerWidget extends StatefulWidget {
  final String url;

  /// When true, suppresses controls (taps are absorbed). Kept for
  /// API-compat with the previous appinio-based widget.
  final bool showJustImage;

  const VideoPlayerWidget({super.key, required this.url, this.showJustImage = false});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri != null) {
      _controller = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(),
      )..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final aspect = controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio;
    final player = AspectRatio(
      aspectRatio: aspect,
      child: VideoPlayer(controller),
    );
    return AbsorbPointer(
      absorbing: widget.showJustImage,
      child: player,
    );
  }
}
