import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final int notificationNumber;
  final bool hasNotifications;
  final Color notificationBackgroundColor;
  final Color? notificationTextColor, iconColor, textColor, lastIconColor;
  final void Function()? onTap;
  const SettingsItem({
    required this.iconPath,
    required this.title,
    this.iconColor,
    this.textColor,
    this.lastIconColor,
    this.notificationNumber = 0,
    this.hasNotifications = false,
    this.notificationBackgroundColor = Colors.red,
    required this.onTap,
    super.key,
    this.notificationTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: getHeightByNumber(0.3),
        ),
        height: getHeightByNumber(71),
        width: double.infinity,
        color: context.colors.background,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: getWidthByNumber(20)),
              child: SizedBox(
                width: getWidthByNumber(25),
                child: CommonImage(
                  imageUrl: iconPath,
                  color: iconColor ?? context.colors.primaryDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? context.colors.textColor,
                ),
              ),
            ),
            if (hasNotifications)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getWidthByNumber(18.w),
                  vertical: getHeightByNumber(6.w),
                ),
                decoration: BoxDecoration(
                  color: notificationBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  notificationNumber.toString(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: notificationTextColor ?? context.colors.textColor,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getWidthByNumber(20),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 19.sp,
                color: lastIconColor ?? context.colors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
