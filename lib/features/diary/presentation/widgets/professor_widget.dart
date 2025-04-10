import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/models/gender.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/date_functions.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:intl/intl.dart';

class ProfessorWidget extends StatelessWidget {
  final Activity activity;
  const ProfessorWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.h),
      child: Row(
        crossAxisAlignment: (activity.fromDate != null && activity.toDate != null)
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Avatar(
            avatar: activity.professor?.avatar,
            size: 65.w,
            defaultAvatar: activity.professor?.gender == Gender.female
                ? Assets.icons.femaleProfessor.path
                : Assets.icons.maleProfessor.path,
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.professor?.name ?? "",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if ((activity.fromDate != null && activity.toDate != null) || activity.date != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.h),
                    decoration: BoxDecoration(
                      color: context.colors.scaffold,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      adjustDate(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String adjustDate() {
    if (activity.date != null) {
      return "${DateFormat('dd MMMM yyyy').format(activity.date!)} ${DateFunctions.formatTimeTo12HourFormat(activity.date)}";
    }
    return "${DateFormat('dd MMMM yyyy').format(activity.fromDate!)} De ${DateFunctions.formatTimeTo12HourFormat(activity.fromDate)} Para ${DateFunctions.formatTimeTo12HourFormat(activity.toDate)}";
  }
}
