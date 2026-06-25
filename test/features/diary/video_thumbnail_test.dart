import 'package:escola/features/diary/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('VideoThumbnail shows a thumbnail image with a visible play button',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _wrap(
        VideoThumbnail(
          thumbnailPath: 'https://example.com/clip-thumb.jpg',
          size: 120,
          onTap: () => tapped = true,
        ),
      ),
    );

    // A thumbnail image is rendered (network path -> Image widget).
    expect(find.byType(Image), findsOneWidget);

    // The centered play button overlay is present and visible.
    final playButton = find.byKey(const ValueKey('video_play_button'));
    expect(playButton, findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Tapping the thumbnail triggers the play callback.
    await tester.tap(find.byType(VideoThumbnail));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('VideoThumbnail still shows the play button without a thumbnail',
      (tester) async {
    await tester.pumpWidget(_wrap(const VideoThumbnail(size: 120)));

    // No image, but the play affordance is still shown.
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });
}
