import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/lang_utils.dart';

class PoweredByWidget extends StatelessWidget {
  const PoweredByWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        try {
          launchUrl(Uri.parse(Config.appUrl));
        } on Exception catch (e) {
          debugPrint(e.toString());
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${LocalizationKeys.powerd_by.tr(context)} ',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.colors.greyDarker,
                fontSize: 14.sp,
                height: 1.25,
              ),
            ),
            SizedBox(
              height: 35.h,
              width: 35.h,
              child: Image.asset(
                assetsImagePath('filhos_logo'),
                height: 35.h,
                width: 35.h,
              ),
            ),
            Text(
           isRTL(context)? 'تطبيق فالوس'   :' Filhos.app',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.colors.greyDarker,
                fontSize: 14.sp,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
