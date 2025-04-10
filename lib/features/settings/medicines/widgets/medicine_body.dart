import 'package:dartz/dartz.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/components/auto_scroller.dart';
import 'package:escola/core/components/loading/loading_linear.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/media_gallery.dart';
import 'package:escola/features/settings/medicines/models/medicine_body_model.dart';
import 'package:escola/features/settings/medicines/widgets/approval_medicine_button.dart';
import 'package:escola/features/settings/medicines/widgets/icon_with_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

class MedicineBody extends StatelessWidget {
  final String title;
  final String dose;
  final String note;
  final List<String> imageUrl;
  final VoidCallback onEdit;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback onDelete;
  final bool loading;
  final String status;
  final String? reason;
  final MedicineBodyModel model;

  const MedicineBody({
    required this.title,
    required this.dose,
    required this.note,
    required this.imageUrl,
    required this.model,
    super.key,
    required this.status,
    required this.reason,
    required this.onEdit,
    required this.onDelete,
    this.onApprove,
    this.onDecline,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 10.csh),
      margin: EdgeInsets.only(bottom: 1.csh),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CustomSelectableText(
                    //   title,
                    //   textAlign: TextAlign.start,
                    //   style: TextStyle(
                    //     fontSize: 18.sp,
                    //     color: context.colors.textColor,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // const SizedBox(
                    //   height: 6,
                    // ),
                    // CustomSelectableText(
                    //   dose,
                    //   style: TextStyle(
                    //     fontSize: 14.sp,
                    //     fontWeight: FontWeight.w300,
                    //     color: context.colors.textColor,
                    //   ),
                    // ),
                  ],
                ),
              ),
              if (validList(imageUrl))
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SizedBox(
                      height: 55.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrl.length,
                        separatorBuilder: (context, index) => SizedBox(width: 10.w),
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                insetPadding: EdgeInsets.zero,
                                child: MediaGallery(
                                  media: imageUrl,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 55.csh,
                            height: 55.csh,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(imageUrl[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.csw, vertical: 4.csh),
            child: Builder(builder: (context) {
              final style1 = TextStyle(
                fontSize: 16.sp,
                color: context.colors.textColor,
                fontWeight: FontWeight.w400,
              );
              final style2 = TextStyle(
                fontSize: 20.sp,
                color: context.colors.textColor,
                fontWeight: FontWeight.bold,
              );
              String times = model.time.firstOrNull??'';
              if (times.contains(',')) {
                times = times.split(',').map((e) => e.trim().tr(context)).join(', ');
              } else {
                times = times.tr(context);
              }
              final data = [
                Tuple2(LocalizationKeys.medicine_name.tr(context), model.name),
                Tuple2(LocalizationKeys.dose.tr(context), '${model.potion} ${model.doseType.title.tr(context)}'),
                Tuple2(LocalizationKeys.instructions.tr(context), model.instructions.title.tr(context)),
                Tuple2(LocalizationKeys.number_of_doses.tr(context), times),
                Tuple2(LocalizationKeys.period_of_time.tr(context), '${model.period_of_time} ${model.day.title.tr(context)}'),
                Tuple2(LocalizationKeys.starting_date.tr(context),model.startingDate == null ?'':DateFormat('dd MMM,yyyy').format(model.startingDate!) ),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 1,
                  crossAxisSpacing: 20.w,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data[index].value1,
                      style: style1,
                    ),
                    AutoScroller(
                      height: 30.h,
                      child: CustomSelectableText(
                        data[index].value2,
                        style: style2,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(
            height: 0,
          ),
          if (validString(note))
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 16.csh),
              decoration: BoxDecoration(
                color: context.colors.scaffold,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: CustomSelectableText(
                note,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w300,
                  color: context.colors.greyDark,
                ),
              ),
            ),
          if (context.isParents)
            SeparatedRow(
              crossAxisAlignment: CrossAxisAlignment.start,
              separatorBuilder: (context, index) => SizedBox(
                width: 25.csw,
              ),
              children: [
                IconWithTextButton(
                  iconPath: 'assets/icons/delete.svg',
                  text: LocalizationKeys.delete.tr(context),
                  onTap: () {
                    onDelete.call();
                  },
                ),
                if (status == 'pending')
                  IconWithTextButton(
                    iconPath: 'assets/icons/edit.svg',
                    text: LocalizationKeys.edit.tr(context),
                    onTap: () {
                      onEdit.call();
                    },
                  ),
                if (status == '1')
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16.csh,
                          color: context.colors.success,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          LocalizationKeys.approved.tr(context),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w300,
                            color: context.colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (status == '2')
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.close,
                            size: 16.csh,
                            color: context.colors.error,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: SeparatedColumn(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              separatorBuilder: (context, index) => SizedBox(height: 2.h),
                              children: [
                                Text(
                                  LocalizationKeys.rejected.tr(context),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w300,
                                    color: context.colors.error,
                                  ),
                                ),
                                if (validString(reason))
                                  Text(
                                    '$reason',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          if (context.isProfessors)
            Padding(
              padding: EdgeInsets.only(top: 20.csh),
              child: loading
                  ? const LoadingLinear()
                  : Row(
                      children: [
                        Expanded(
                          child: ApprovalMedicinesButton(
                            onTap: onApprove,
                            isApproveButton: true,
                          ),
                        ),
                        SizedBox(
                          width: 20.csw,
                        ),
                        Expanded(
                          child: ApprovalMedicinesButton(
                            onTap: onDecline,
                            isApproveButton: false,
                          ),
                        ),
                      ],
                    ),
            )
        ],
      ),
    );
  }
}
