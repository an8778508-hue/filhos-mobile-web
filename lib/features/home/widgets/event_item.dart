import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/accept_event/accept_events.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class EventItem extends StatelessWidget {
  final EventModel eventModel;

  final double? height;
  final double? width;
  final bool withImage;

  const EventItem({
    required this.eventModel,
    this.height,
    this.width,
    this.withImage = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) => AcceptEventScreen(
                  eventId: eventModel.id,
                )),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(20.r),
        ),
        width: width ?? double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (withImage)
              Stack(
                children: [
                  SizedBox(
                    height: 223.csh,
                    width: double.maxFinite,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.csh),
                        topRight: Radius.circular(15.csh),
                      ),
                      child: Padding(
                        padding:
                            validString(eventModel.imageUrl) ? EdgeInsets.zero : EdgeInsets.symmetric(vertical: 40.h),
                        child: CommonImage(
                          imageUrl: validateString(eventModel.imageUrl, assetsPath('Logo')),
                          fit: validString(eventModel.imageUrl) ? BoxFit.cover : BoxFit.contain,
                          height: 223.csh,
                          width: double.maxFinite,
                        ),
                      ),
                    ),
                  ),
                  if ((eventModel.requireApproval && (context.isProfessors && eventModel.teacherAllowActions)) ||
                      (eventModel.requireApproval && context.isParents))
                    Positioned(
                      left: 27.w,
                      bottom: 0,
                      child: Container(
                        width: 177.w,
                        height: 33.h,
                        color: context.colors.alert,
                        child: Center(
                          child: Text(
                            LocalizationKeys.require_approval.tr(context),
                            style: TextStyle(
                              color: context.colors.background,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 26.csw),
              child: SizedBox(
                height: withImage? 180.h:200.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15.csh,
                    ),
                    if (eventModel.requireApproval && !withImage)
                      Container(
                        width: 177.w,
                        margin: EdgeInsets.only(bottom: 10.csh),
                        padding: EdgeInsets.symmetric(vertical: 5.csh),
                        decoration: BoxDecoration(
                          color: context.colors.alert,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            LocalizationKeys.require_approval.tr(context),
                            style: TextStyle(
                              color: context.colors.secondaryTextColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      eventModel.title ?? '',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 8.csh,
                    ),
                    Expanded(
                      child: Text(
                        eventModel.description ?? '',
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 16.sp,
                          color: context.colors.greyDarker,
                        ),
                        maxLines: withImage ? 3:2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // SizedBox(
                    //   height: 80.h,
                    //   child: Fader(
                    //     height: 0,
                    //     cut: true,
                    //     child: TextHtml(
                    //       eventModel.description,
                    //       style: TextStyle(
                    //         overflow: TextOverflow.ellipsis,
                    //         fontSize: 16.sp,
                    //         color: context.colors.greyDarker,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(
                    //   height: 80.h,
                    //   child: Padding(
                    //     padding: EdgeInsets.zero,
                    //     child: Text(
                    //       eventModel.description ?? '',
                    //       style: TextStyle(
                    //         fontSize: 16.sp,
                    //         color: context.colors.greyDarker,
                    //       ),
                    //       maxLines: 3,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //   ),
                    // ),
                    SizedBox(
                      height: 13.csh,
                    ),
                    if (eventModel.startDate != null)
                      Text(
                        DateFormat('dd-MM-yyyy hh:mm a').format(eventModel.startDate!),
                        maxLines: 2,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 13.sp,
                          color: context.colors.greyDark,
                        ),
                      ),
                    SizedBox(
                      height: 5.h,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
