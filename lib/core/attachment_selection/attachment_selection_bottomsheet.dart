import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_row/separated_row.dart';

import 'attachment_src.dart';

class AttachmentSelectionBottomSheet extends StatelessWidget {
  final bool imageAndVideoOption;
  const AttachmentSelectionBottomSheet({super.key, this.imageAndVideoOption = false});
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 40.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              LocalizationKeys.pick_file_source.tr(context),
              style: TextStyle(
                color: context.colors.textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0.w) + EdgeInsets.only(bottom: 10.h),
            child: SeparatedRow(
              separatorBuilder: (context, index) => SizedBox(width: 10.w),
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildItem(
                  selected: true,
                  context: context,
                  title:
                      imageAndVideoOption ? LocalizationKeys.image.tr(context) : LocalizationKeys.gallery.tr(context),
                  icon: Icons.folder_copy_outlined,
                  callback: () =>
                      Navigator.of(context).pop(imageAndVideoOption ? AttachmentSrc.image : AttachmentSrc.gallery),
                ),
                _buildItem(
                  selected: true,
                  context: context,
                  title: imageAndVideoOption ? LocalizationKeys.video.tr(context) : LocalizationKeys.camera.tr(context),
                  icon: Icons.camera_alt_outlined,
                  callback: () =>
                      Navigator.of(context).pop(imageAndVideoOption ? AttachmentSrc.video : AttachmentSrc.camera),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required VoidCallback callback,
    required String title,
    required IconData icon,
    required bool selected,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: callback,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.r)),
              border: Border.all(color: selected ? context.colors.primary : context.colors.disabled),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 40.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: selected ? context.colors.primary : context.colors.disabled,
                  size: 48.sp,
                ),
                SizedBox(height: 20.h),
                Text(
                  title,
                  maxLines: null,
                  style: TextStyle(
                    color: selected ? context.colors.primary : context.colors.disabled,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
