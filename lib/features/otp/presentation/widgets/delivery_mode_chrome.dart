import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/otp/models/otp_delivery_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeliveryModeChrome extends StatelessWidget {
  const DeliveryModeChrome({
    super.key,
    required this.mode,
    this.phone,
    this.phoneCode,
    this.maskedEmail,
  });

  final OTPDeliveryMode mode;
  final String? phone;
  final String? phoneCode;
  final String? maskedEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            mode == OTPDeliveryMode.sms
                ? LocalizationKeys.phone_verification.tr(context)
                : LocalizationKeys.email_otp_verify_title.tr(context),
            style: TextStyle(
              fontSize: 25.sp,
              color: context.colors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            mode == OTPDeliveryMode.sms
                ? LocalizationKeys.enter_otp_that_sent_to.tr(context)
                : LocalizationKeys.email_otp_verify_subline
                    .tr(context)
                    .replaceAll('{maskedEmail}', maskedEmail ?? ''),
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        if (mode == OTPDeliveryMode.sms && phone != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${phoneCode ?? ''}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: context.colors.textColor,
                    height: 1.2.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  phone!,
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: context.colors.textColor,
                    height: 1.2.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
            ),
          ),
        if (mode == OTPDeliveryMode.email && maskedEmail != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 20.sp, color: context.colors.textColor),
                SizedBox(width: 8.w),
                Text(
                  maskedEmail!,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: context.colors.textColor,
                    height: 1.2.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
