import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ApprovedSheetWidget extends StatelessWidget {
  final String name;
  final String imageUrl;
  final DateTime? date;
  final bool isApproved;

  const ApprovedSheetWidget({
    required this.name,
    required this.imageUrl,
    required this.date,
    required this.isApproved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    print('ApprovedSheetWidget.build $name');
    return Container(
      width: double.maxFinite,
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
                color: Color(0x29000000),
                offset: Offset(0, 3),
                blurRadius: 6,
                spreadRadius: 0)
          ],
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r),topRight: Radius.circular(20.r)),
      color: context.colors.background,
        ),
      padding: EdgeInsets.symmetric(horizontal: 25.csw, vertical: 25.csh),
      margin: EdgeInsets.only( top: 25.csh),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Avatar(
            avatar: imageUrl,
          ),
          SizedBox(width: 17.csw),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApproved ? LocalizationKeys.approved_by.tr(context) : LocalizationKeys.rejected_by.tr(context),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                name,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                  height: 1.6,
                ),
              ),
              if (date != null)
                Text(
                  DateFormat('dd MMM yyyy  hh:mm a').format(date!),
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w300, color: context.colors.greyLight),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
