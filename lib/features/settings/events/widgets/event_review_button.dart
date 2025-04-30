import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventReviewButton extends StatelessWidget {
  final bool enabled;
  final String icon;
  final Function() onTap;
  const EventReviewButton({
    required this.enabled,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 51.h,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            color: enabled ? context.colors.primaryVeryLight : context.colors.background,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: enabled ? context.colors.primary : context.colors.background,
              width: 2.csw,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 33.h,
                width: 33.h,
                child: MyIcon(
                  'assets/icons/$icon.svg',
                  size: 33.h,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
