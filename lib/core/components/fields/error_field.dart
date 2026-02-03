import 'package:escola/core/components/text/text.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorField extends StatelessWidget {
  const ErrorField({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: Container()),
        Center(
          child: Container(
            // margin: EdgeInsets.symmetric(horizontal: getRelativeWidth(0.14)),
            padding: EdgeInsets.all(10.sp),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(5.r),
              // border: Border.all(color: kAlertColor, width: 1.sp),
            ),
            child: CommonBoldText(
              value: (text).toString().trim(),
              maxLines: null,
              fontWeight: FontWeight.w600,
              size: 14.sp,
              textColor: context.colors.error,
              align: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
}
