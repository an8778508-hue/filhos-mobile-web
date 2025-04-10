import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool showJustImage;
  const VideoPlayerWidget({super.key, required this.url, this.showJustImage = false});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController videoPlayerController;
  late CustomVideoPlayerController _customVideoPlayerController;

  @override
  void initState() {
    super.initState();
    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url), videoPlayerOptions: VideoPlayerOptions())
          ..initialize().then((value) => setState(() {}));
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

  @override
  void dispose() {
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.url);
    return !videoPlayerController.value.isInitialized
        ? const Center(child: CircularProgressIndicator())
        : AbsorbPointer(
            absorbing: widget.showJustImage,
            child: CustomVideoPlayer(customVideoPlayerController: _customVideoPlayerController));
  }
}
