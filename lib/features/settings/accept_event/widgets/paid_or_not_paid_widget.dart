import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PaidOrNotPaidWidget extends StatelessWidget {
  final bool isPaid;
  final DateTime? date;
  const PaidOrNotPaidWidget({
    required this.isPaid,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40.csh,
          width: 102.csw,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: isPaid ? context.colors.success.withOpacity(0.15) : context.colors.error.withOpacity(0.15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isPaid)
                Icon(
                  FontAwesomeIcons.check,
                  color: context.colors.success,
                  size: 18.sp,
                ),
              if (isPaid)
                SizedBox(
                  width: 6.csw,
                ),
              Text(
                isPaid ? LocalizationKeys.paid.tr(context) : LocalizationKeys.not_paid.tr(context),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: isPaid ? context.colors.success : context.colors.error,
                ),
              ),
            ],
          ),
        ),
        if (isPaid)
          SizedBox(
            height: 3.csh,
          ),
        if (isPaid && date != null)
          Text(
            DateFormat('dd MMM yyyy hh:mm a').format(date!),
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: context.colors.greyLight),
          ),
      ],
    );
  }
}
