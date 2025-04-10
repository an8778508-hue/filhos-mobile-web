import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectAllImages extends StatelessWidget {
  final bool allSelected;
  final Function onTap;
  const SelectAllImages({super.key, required this.allSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                !allSelected ? Icons.circle_outlined : Icons.check_circle,
                color: !allSelected ? Colors.grey : context.colors.primary,
                size: 25.w,
              ),
              SizedBox(width: 8.w),
              Text(
                LocalizationKeys.select_all.tr(context),
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 17.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
