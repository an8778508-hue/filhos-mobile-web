import 'package:escola/features/diary/widgets/video_attachment_picker.dart';
import 'package:escola/features/diary/widgets/video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('shows an upload progress indicator while isUploading is true',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        VideoAttachmentPicker(
          selectedVideoPath: '/tmp/picked_clip.mp4',
          isUploading: true,
          onVideoPicked: (_) {},
        ),
      ),
    );

    // A thumbnail of the picked video is shown ...
    expect(find.byType(VideoThumbnail), findsOneWidget);
    // ... with a progress indicator overlaid while uploading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the "Add video" affordance when nothing is selected',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        VideoAttachmentPicker(
          onVideoPicked: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('add_video_button')), findsOneWidget);
    expect(find.text('Add video'), findsOneWidget);
    // No progress indicator and no thumbnail before any pick/upload.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(VideoThumbnail), findsNothing);
  });

  testWidgets('not uploading: no progress indicator over the picked thumbnail',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        VideoAttachmentPicker(
          selectedVideoPath: '/tmp/picked_clip.mp4',
          isUploading: false,
          onVideoPicked: (_) {},
        ),
      ),
    );

    expect(find.byType(VideoThumbnail), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
