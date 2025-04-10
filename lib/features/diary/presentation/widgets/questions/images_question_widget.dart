import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/video/video_player_widget.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class ImagesQuestionWidget extends StatelessWidget {
  final ImagesQuestion question;
  final QuestionCategory? questionCategory;
  const ImagesQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    final int imagesLength = questionCategory?.answer?.length ?? 0;
    final int maxLength = imagesLength > 3 ? 3 : imagesLength;
    final bool lengthExcceed = imagesLength > 3;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question?.title != null) ...[
            Row(
              children: [
                Text(
                  question!.title!,
                    textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 20.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                maxLength,
                (index) {
                  final image = questionCategory?.answer?[index];
                  final ext = image?.split('.').last ?? "";
                  final fileIsImage = isImage(ext);
                  final fileIsVideo = isVideo(ext);
                  final isLast = index == maxLength - 1;
                  if (image == null) return const SizedBox();
                  return GestureDetector(
                    onTap: () {
                      if (fileIsImage || fileIsVideo) {
                        WidgetFunctions.navigateTo(context, MediaGallery(media: (questionCategory?.answer ?? []).cast()));
                      } else {
                        openFile(image);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.w,
                          margin: EdgeInsetsDirectional.only(end: 8.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.w),
                            border: !fileIsImage ? Border.all(color: Colors.grey.withOpacity(0.8), width: 1.w) : null,
                          ),
                          child: fileIsImage
                              ? CommonImage(imageUrl: image, fit: BoxFit.cover)
                              : fileIsVideo
                                  ? VideoPlayerWidget(
                                      url: image,
                                      showJustImage: true,
                                    )
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
                                    ),
                        ),
                        if (lengthExcceed && isLast) ...[
                          Positioned.fill(
                            child: Container(
                              margin: EdgeInsetsDirectional.only(end: 8.w),
                              width: 88.w,
                              height: 88.w,
                              color: Colors.black26,
                              child: Center(
                                child: Text(
                                  "+${imagesLength - 3}",
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  void openFile(url) {
    try {
      launchUrl(Uri.parse(url));
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
