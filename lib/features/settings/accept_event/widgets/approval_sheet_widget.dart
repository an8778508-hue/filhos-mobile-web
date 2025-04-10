import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/settings/accept_event/widgets/approval_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ApprovalSheetWidget extends StatelessWidget {
  final DateTime? deadline;
  final Function()? onYes;
  final Function()? onNo;
  const ApprovalSheetWidget({
    required this.deadline,
    required this.onYes,
    required this.onNo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      color: context.colors.background,
      padding: EdgeInsets.symmetric(horizontal: 25.csw, vertical: 25.csh),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationKeys.deadline_for_approval.tr(context),
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400, color: context.colors.error),
          ),
          if (deadline != null)
            Text(
              DateFormat('dd MMM yyyy').format(deadline!),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.primary,
                height: 1.6,
              ),
            ),
          SizedBox(
            height: 20.csh,
          ),
          Row(
            children: [
              ApprovalButton(
                title: LocalizationKeys.yes.tr(context),
                onTap: onYes,
                color: context.colors.success,
              ),
              SizedBox(
                width: 15.csw,
              ),
              ApprovalButton(
                title: LocalizationKeys.no.tr(context),
                onTap: onNo,
                color: context.colors.error,
              ),
            ],
          )
        ],
      ),
    );
  }
}
