import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChildItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subTitle;
  final void Function()? onTap;

  const ChildItem({
    required this.imageUrl,
    required this.title,
    required this.subTitle,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 6.h,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 25.h,
        ),
        color: context.colors.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getWidthByNumber(20),
                ),
                child: Avatar(
                  avatar: imageUrl,
                  size: 50.w,
                  isChild: true,
                )),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textColor,
                    ),
                  ),
                  Text(
                    subTitle,
                    maxLines: 2,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w300,
                      color: context.colors.textColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getWidthByNumber(20),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 19.sp,
                color: context.colors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
