import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/medicines_professors/models/medicine_prescription_model.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

class MedicinePrescriptionItem extends StatelessWidget {
  const MedicinePrescriptionItem({
    super.key,
    required this.model,
    this.checked,
    this.error,
    this.loading = false,
  });

  final PrescriptionModel model;
  final bool? checked;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final doctor = model.doctor;
    DateTime? dateTime;
    try {
      dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(model.time);
    } catch (e) {
      debugPrint("FAILED_PARSING_DATE ${model.time} $e");
    }
    final date = dateTime == null ? null : DateFormat('dd/MM/yyyy').format(dateTime);
    final time = dateTime == null ? null : DateFormat('HH:mm').format(dateTime);
    return Container(
      color: context.colors.primaryVeryLight,
      padding: EdgeInsetsDirectional.only(
        start: 20.w,
        end: 20.w,
        top: 20.h,
        bottom: 7.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (validString(error))
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                error!,
                style: TextStyle(
                  color: context.colors.error,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: 20.0.h),
            child: SeparatedRow(
              separatorBuilder: (context, index) => SizedBox(width: 10.w),
              children: [
                if (checked != null)
                  SizedBox(
                    width: 30.w,
                    height: 30.w,
                    child: loading
                        ? Padding(
                            padding: EdgeInsets.all(4.0.w),
                            child: const Loading(),
                          )
                        : (checked == true ? Assets.icons.checked : Assets.icons.unchecked).svg(),
                  ),
                if (validString(model.medicineBodyModel.name))
                  Text(
                    model.medicineBodyModel.name,
                    style: TextStyle(
                      color: context.colors.textColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (validString(date) || validString(time))
            Padding(
              padding: EdgeInsets.only(bottom: 20.0.h),
              child: SeparatedRow(
                separatorBuilder: (context, index) => SizedBox(width: 11.w),
                children: [
                  if (validString(time))
                    Text(
                      time!,
                      style: TextStyle(
                        color: context.colors.textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (validString(date))
                    Container(
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
                      child: Text(
                        date!,
                        style: TextStyle(
                          color: context.colors.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (doctor != null)
            Container(
              color: context.colors.disabled,
              height: 1,
              margin: EdgeInsets.only(bottom: 11.h),
            ),
          if (doctor != null)
            SeparatedRow(
              separatorBuilder: (context, index) => SizedBox(width: 16.w),
              children: [
                if (validString(doctor.avatar))
                  Avatar(
                    avatar: doctor.avatar,
                    size: 40.w,
                  ),
                if (validString(doctor.name) || validString(doctor.phone))
                  SeparatedColumn(
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (validString(doctor.name))
                        Text(
                          doctor.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13.sp,
                            color: context.colors.textColor,
                          ),
                        ),
                      if (validString(doctor.phone))
                        Text(
                          doctor.phone,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            color: context.colors.textColor,
                          ),
                        ),
                    ],
                  )
              ],
            ),
        ],
      ),
    );
  }
}
