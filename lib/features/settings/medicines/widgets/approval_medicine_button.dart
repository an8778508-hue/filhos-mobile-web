import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApprovalMedicinesButton extends StatelessWidget {
  final bool isApproveButton;
  final VoidCallback? onTap;

  const ApprovalMedicinesButton({
    required this.isApproveButton,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170.csh,
        height: 55.csh,
        decoration: BoxDecoration(
          color: isApproveButton ? context.colors.successLighter : context.colors.errorLighter,
          borderRadius: BorderRadius.all(
            Radius.circular(8.r),
          ),
        ),
        child: Center(
          child: Text(
            isApproveButton ? LocalizationKeys.approve.tr(context) : LocalizationKeys.decline.tr(context),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: isApproveButton ? context.colors.success : context.colors.error,
            ),
          ),
        ),
      ),
    );
  }
}
