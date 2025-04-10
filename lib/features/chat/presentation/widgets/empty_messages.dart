import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyMessages extends StatelessWidget {
  const EmptyMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Assets.icons.noChat.svg(
            width: 40.w,
            height: 40.h,
            colorFilter:
                ColorFilter.mode(context.colors.secondary, BlendMode.srcIn)),
        SizedBox(height: 8.h),
        Text(
          LocalizationKeys.no_messages_yet.tr(context),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.black, fontSize: 21.w, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Text(
          LocalizationKeys.you_dont_have_messages_yet.tr(context),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 20.w,
              fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
