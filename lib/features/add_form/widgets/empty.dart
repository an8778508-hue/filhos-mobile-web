import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyAddForm extends StatelessWidget {
  const EmptyAddForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        height: 80.csh,
      ),
      SvgPicture.asset(
        'assets/icons/support.svg',
        height: 114.csh,
        width: 114.csw,
      ),
      SizedBox(
        height: 40.csh,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Text(
                LocalizationKeys.server_error.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primaryLight,
                ),
              ),
            ),
            SizedBox(
              height: 18.csh,
            ),
          ],
        ),
      ),
    ]);
  }
}
