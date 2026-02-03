import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfessorsContainer extends StatelessWidget {
  const ProfessorsContainer({super.key, this.paddingHorizontal, this.paddingVertical, this.fontSize});

  final double? paddingHorizontal ;
  final double? paddingVertical ;
  final double? fontSize ;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal??50.w, vertical: paddingVertical??10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35.r),
        color: context.colors.primaryBackground,
      ),
      child: Text(
        LocalizationKeys.professors.tr(context),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: fontSize??33.sp,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
