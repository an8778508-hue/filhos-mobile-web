import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/diary/presentation/widgets/menu_screen.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:escola/core/utils/extensions/colors_ext.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.date,
    required this.childId,
  });

  final DateTime date;
  final int? childId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        WidgetFunctions.navigateTo(context, MenuScreen(date: date, childId: childId));
      },
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: context.colors.lightBackground,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          children: [
            CommonImage(imageUrl: Assets.icons.menuIcon.path, size: 15.w),
            SizedBox(width: 10.w),
            Text(
              LocalizationKeys.menu.tr(context),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.arrow_forward_ios,
              color: context.colors.primary,
              size: 12.w,
            )
          ],
        ),
      ),
    );
  }
}
