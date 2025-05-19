import 'package:appinio_video_player_plus/appinio_video_player_plus.dart';
import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool showJustImage;

  const VideoPlayerWidget({super.key, required this.url, this.showJustImage = false});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  CustomVideoPlayerController? _customVideoPlayerController;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    CachedVideoPlayerPlusController? videoPlayerController;
    if (uri != null) {
      videoPlayerController = CachedVideoPlayerPlusController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(),
      )..initialize().then((value) => setState(() {}));
    }
    if (videoPlayerController != null) {
      _customVideoPlayerController = CustomVideoPlayerController(
          context: context,
          videoPlayerController: videoPlayerController,
          customVideoPlayerSettings: CustomVideoPlayerSettings(
            customAspectRatio: 16 / 9,
            showDurationPlayed: !widget.showJustImage,
            settingsButtonAvailable: !widget.showJustImage,
            showDurationRemaining: !widget.showJustImage,
            showFullscreenButton: !widget.showJustImage,
          ));
    }
  }

  @override
  void dispose() {
    _customVideoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _customVideoPlayerController?.videoPlayerController.value.isInitialized == true
        ? AbsorbPointer(absorbing: widget.showJustImage, child: CustomVideoPlayer(customVideoPlayerController: _customVideoPlayerController!))
        : const Center(child: CircularProgressIndicator());
  }
}
