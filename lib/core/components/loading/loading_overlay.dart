import 'package:escola/core/components/icons/AppLogo.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: context.colors.background.withOpacity(0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogoIcon(
              height: 220.h,
              width: 220.h,
            ),
            SizedBox(height: 50.h),
            Loading(size: 40.h),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}
