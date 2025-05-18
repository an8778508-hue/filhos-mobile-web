import 'package:dotted_border/dotted_border.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UploadImage extends StatelessWidget {
  const UploadImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        //TODO: Implementar o upload de image
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 25.csw, vertical: 10.csh),
        height: 64.csh,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: context.colors.greyLight,
            strokeWidth: 1.0,
            dashPattern: const [10, 10],
            radius: const Radius.circular(10),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  LocalizationKeys.upload_image.tr(context),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primaryLight,
                  ),
                ),
                SizedBox(
                  width: 20.csw,
                ),
                SvgPicture.asset(
                  'assets/icons/upload_image.svg',
                  height: 28.csh,
                  width: 28.csw,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
