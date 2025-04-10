import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/child_details_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChildDetailsSheet extends StatefulWidget {
  const ChildDetailsSheet({
    super.key,
    required this.childDetailsModel,
  });

  final ChildDetailsModel childDetailsModel;

  static openSheet({required BuildContext context, required ChildDetailsModel childDetailsModel}) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: context.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => ChildDetailsSheet(childDetailsModel: childDetailsModel),
    );
  }

  @override
  State<ChildDetailsSheet> createState() => _ChildDetailsSheetState();
}

class _ChildDetailsSheetState extends State<ChildDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  height: 58.h,
                  width: 58.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: (validString(widget.childDetailsModel.avatar))
                      ? CommonImage(
                          imageUrl: widget.childDetailsModel.avatar,
                          fit: BoxFit.cover,
                        )
                      : SvgPicture.asset(
                          height: 58.h,
                          width: 58.h,
                          'assets/images/child_profile.svg',
                        ),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.childDetailsModel.name ?? '',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textColor,
                    ),
                  ),
                  Text(
                    widget.childDetailsModel.grade ?? '',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: context.colors.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          SizedBox(height: 30.h),
          Container(
            height: 1,
            // margin: EdgeInsets.symmetric(
            //   horizontal: 30.csw,
            // ),
            color: context.colors.disabled,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.registration).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (stringNotNullOrEmpty(widget.childDetailsModel.enroll_parent?.code)) ...[
                      Text(
                        widget.childDetailsModel.enroll_parent?.code ?? '',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: context.colors.textColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    Text(
                      widget.childDetailsModel.enroll_parent?.name ?? '',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            height: 1,
            // margin: EdgeInsets.symmetric(
            //   horizontal: 30.csw,
            // ),
            color: context.colors.disabled,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.responsible).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (stringNotNullOrEmpty(widget.childDetailsModel.responsible?.code)) ...[
                      Text(
                        widget.childDetailsModel.responsible?.code ?? '',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: context.colors.textColor,
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                    Text(
                      widget.childDetailsModel.responsible?.name ?? '',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            height: 1,
            // margin: EdgeInsets.symmetric(
            //   horizontal: 30.csw,
            // ),
            color: context.colors.disabled,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.grade).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.childDetailsModel.grade ?? '',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.series).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.childDetailsModel.series ?? '',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.gender).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.childDetailsModel.gender ?? '',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  (LocalizationKeys.birthday).tr(context) + ':',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.childDetailsModel.birthday ?? '',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
