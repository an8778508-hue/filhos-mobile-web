import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FieldTitle extends StatelessWidget {
  const FieldTitle({super.key, required this.textKey, this.externalButtonKey, this.onTap});
  final String textKey;
  final String? externalButtonKey;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                (textKey).tr(context),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  color: context.colors.textColor,
                  height: 1,
                ),
              ),
            ),
            if (externalButtonKey != null)
              InkWell(
                onTap: () {
                  onTap?.call();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20.sp,
                    ),
                    SizedBox(
                      width: 5.w,
                    ),
                    Text(
                      (externalButtonKey!).tr(context),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        fontSize: 16.sp,
                        color: context.colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(
          height: 15.h,
        ),
      ],
    );
  }
}
