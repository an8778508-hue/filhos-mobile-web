import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconCardWidget extends StatelessWidget {
  final IconData icon;
  const IconCardWidget({
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51.csh,
      width: 51.csh,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: context.colors.primaryLighter,
      ),
      child: Center(
        child: Icon(
          icon,
          color: context.colors.primary,
          size: 23.h,
        ),
      ),
    );
  }
}
