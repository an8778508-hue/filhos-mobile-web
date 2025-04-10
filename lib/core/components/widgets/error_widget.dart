import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorScreen extends StatelessWidget {
  final String errorText;
  final Function()? onRetry;
  final bool showRetry;
  const ErrorScreen({
    super.key,
    required this.errorText,
    required this.onRetry,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 35.sp, color: Colors.red),
        SizedBox(height: 10.h),
        Text(
          errorText,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        if (showRetry) ...[
          SizedBox(height: 15.h),
          SizedBox(
            width: 220.w,
            child: CustomButton(
              textVerticalPadding: 10,
              title: LocalizationKeys.retry.tr(context),
              textAlign: TextAlign.center,
              onTap: onRetry,
            ),
          )
        ]
      ],
    );
  }
}
