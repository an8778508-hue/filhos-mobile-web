import 'package:escola/core/components/icons/common_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyWidget extends StatelessWidget {
  final String icon;
  final String title;
  final double? size;
  final Color? iconColor;

  const EmptyWidget({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommonImage(imageUrl: icon, height: size??50.h,color: iconColor),
        SizedBox(height: 20.h),
        Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
