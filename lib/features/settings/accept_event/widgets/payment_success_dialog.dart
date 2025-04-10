import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<dynamic> showSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.colors.background,
        contentPadding: EdgeInsets.symmetric(vertical: 40.csh, horizontal: 20.csw),
        content: SizedBox(
          height: 220.csh,
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/icons/check_blue.svg',
                height: 115.csh,
                width: 115.csh,
              ),
              SizedBox(height: 35.csh),
              Text(
                LocalizationKeys.thank_you_your_payment_was_successfully_completed.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
