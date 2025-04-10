import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnnouncementsContainerWidget extends StatelessWidget {
  final Function()? onTap;
  final bool isPdf;
  const AnnouncementsContainerWidget({
    required this.onTap,
    required this.isPdf,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 11.csw, vertical: 10.csh),
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: context.colors.greyLighter,
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                    height: 50.csh,
                    width: 51.csw,
                    decoration: BoxDecoration(
                      color: isPdf ? context.colors.successLighter : context.colors.accentLight,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Image.asset(
                      isPdf ? 'assets/images/pdf.png' : 'assets/images/image.png',
                      height: 20.csh,
                      width: 20.csw,
                    )),
                SizedBox(
                  width: 11.csw,
                ),
                Text(
                  isPdf
                      ?"PDF"
                      : LocalizationKeys.image.tr(context),
                  style: TextStyle(
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
