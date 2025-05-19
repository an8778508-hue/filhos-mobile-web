import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/models/announcements_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/settings/announcements/widgets/announcements_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementsItem extends StatelessWidget {
  final AnnouncementsModel announcement;

  const AnnouncementsItem({
    required this.announcement,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(15.r),
        ),
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if(announcement.image != null)
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 15.w),
                  child: Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.r),
                        bottomLeft: Radius.circular(15.r),
                        bottomRight: Radius.circular(15.r),
                        topRight: Radius.circular(15.r),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(announcement.image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal:announcement.image != null ? 5.w : 26.csw, vertical: 20.csh),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width/1.8,
                        child: CustomSelectableText(
                          announcement.title,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 13.csh,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width/1.8,
                        child: Text(
                          announcement.content,
                          maxLines: 3,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 16.sp,
                            color: context.colors.greyDarker,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 17.csh,
                      ),
                      if (announcement.date != null)
                        Text(
                          DateFormat('dd-MM-yyyy hh:mm a').format(announcement.date!),
                          maxLines: 2,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 13.sp,
                            color: context.colors.greyDark,
                          ),
                        ),
                      if (announcement.tags != null && announcement.tags!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.csh),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: announcement.tags!.map((tag) {
                              return Chip(
                                label: Text(
                                  tag?.name ?? '',
                                  style: TextStyle(fontSize: 14.sp, color: context.colors.primary),
                                ),
                                backgroundColor: context.colors.primaryBackground,
                              );
                            }).toList(),
                          ),
                        ),
                      // loop into attachments
                      if (announcement.attachments.isNotEmpty)
                        SizedBox(
                          height: 10.h,
                        ),
                      if (announcement.attachments.isNotEmpty)
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => SizedBox(
                            height: 20.csh,
                          ),
                          itemBuilder: (context, index) {
                            bool isPdf = (announcement.attachments[index].toString().contains("pdf"));
                            return AnnouncementsContainerWidget(
                              isPdf:isPdf ,
                              onTap: () {
                                try {
                                  final image = announcement.attachments[index].toString();
                                  if (isPdf) {
                                    launchUrl(Uri.parse(image),mode: LaunchMode.externalApplication);
                                  }else{
                                    Navigator.push(context, MaterialPageRoute(builder: (_) =>PhotoViewer(url: image, tag: '')));
                                  }
                                } on Exception catch (e) {
                                  print('PoweredByWidget.build');
                                  print(e);
                                }
                              },
                            );
                          },
                          itemCount: announcement.attachments.length,
                          shrinkWrap: true,
                        ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
