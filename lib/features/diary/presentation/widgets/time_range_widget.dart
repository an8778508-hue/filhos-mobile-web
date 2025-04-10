import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/date_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTimeRangeText extends StatelessWidget {
  final DateTime? fromTime;
  final DateTime? toTime;

  const CustomTimeRangeText({super.key, required this.fromTime, required this.toTime});

  @override
  Widget build(BuildContext context) {
    final fromText = DateFunctions.formatTimeTo12HourFormat(fromTime);
    final toText = DateFunctions.formatTimeTo12HourFormat(toTime);

    return Row(
      children: [
        Text(
          "${LocalizationKeys.from.tr(context)} ",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: context.colors.greyLight,
          ),
        ),
        Text(
          fromText,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: context.colors.textColor,
          ),
        ),
        Text(
          "  :  ",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: context.colors.textColor,
          ),
        ),
        Text(
          " ${LocalizationKeys.to.tr(context)} ",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: context.colors.greyLight,
          ),
        ),
        Text(
          toText,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: context.colors.textColor,
          ),
        ),
      ],
    );
  }
}
