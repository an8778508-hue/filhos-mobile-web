import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MedicineHeaderWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subTitle;
  const MedicineHeaderWidget({
    required this.imageUrl,
    required this.title,
    required this.subTitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      padding: EdgeInsets.symmetric(horizontal: 16.csw, vertical: 20.csh),
      child: Row(
        children: [
          Container(
            width: 60.csh,
            height: 60.csh,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(validString(imageUrl)
                    ? imageUrl
                    //TODO: add default image
                    : 'https://drive.google.com/file/d/17LjfxdKAVrs7VAYVWAxJ0V_6KX_X2ZG_/view?usp=sharing'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            width: 17.csw,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
                SizedBox(
                  height: 5.h,
                ),
                Text(
                  subTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w300,
                    color: context.colors.textColor,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
