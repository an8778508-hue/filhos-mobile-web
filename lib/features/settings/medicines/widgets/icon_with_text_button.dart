import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconWithTextButton extends StatelessWidget {
  final String iconPath;
  final String text;
  final Function() onTap;
  const IconWithTextButton({
    super.key,
    required this.iconPath,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical:  16.csh,horizontal: 5.w),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              height: 16.csh,
              width: 16.csh,
              color: context.colors.divider,
            ),
            SizedBox(
              width: 8.csw,
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w300,
                color: context.colors.divider,
              ),
            )
          ],
        ),
      ),
    );
  }
}
