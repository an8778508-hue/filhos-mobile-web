import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/video/video_player_widget.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MediaGalleryItem extends StatelessWidget {
  final String media;
  final bool isSelected;
  final Function onSelected;
  final Function onZoomed;

  const MediaGalleryItem(
      {super.key, required this.media, required this.isSelected, required this.onSelected, required this.onZoomed});

  @override
  Widget build(BuildContext context) {
    final ext = media.split('.').last;
    final fileIsVideo = isVideo(ext);
    return SizedBox(
      height: 300.h,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: context.colors.background,
                border: Border(bottom: BorderSide(color: context.colors.secondaryScaffold, width: 20.h))),
            child: Stack(
              children: [
                Positioned.fill(
                    child: fileIsVideo
                        ? VideoPlayerWidget(url: media)
                        : CommonImage(
                            imageUrl: media,
                            fit: BoxFit.cover,
                          )),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(),
                    child: Container(
                      margin: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.transparent : Colors.white,
                        border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.black, width: isSelected ? 0.w : 1.4.w),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle,
                        color: isSelected ? context.colors.successLight : Colors.white,
                        size: isSelected ? 32.w : 28.w,
                      ),
                    ),
                  ),
                ),
                if (!fileIsVideo)
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onZoomed(),
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                          top: 20.h,
                          bottom: 15.h,
                          start: 20.w,
                          end: 15.w,
                        ),
                        padding: EdgeInsets.all(5.h),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.background,
                          border: Border.all(color: Colors.transparent, width: 1.4.w),
                        ),
                        child: Icon(
                          Icons.zoom_out_map,
                          color: context.colors.primary,
                          size: 25.w,
                        ),
                      ),
                    ),
                  ),
                // Align(
                //   alignment: AlignmentDirectional.bottomStart,
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 10.0.w, vertical: 15.h),
                //     child: const Reactions(count: 3),
                //   ),
                // ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
