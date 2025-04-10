import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:escola/features/home/models/section_model.dart';
import 'package:escola/features/settings/announcements/announcements_screen.dart';
import 'package:escola/features/settings/edit_profile/edit_profile_screen.dart';
import 'package:escola/features/settings/events/event_screen.dart';
import 'package:escola/features/settings/medicines/medicine_screen.dart';
import 'package:escola/features/settings/medicines_professors/medicine_professors_screen.dart';
import 'package:escola/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSectionsItem extends StatelessWidget {
  final SectionModel sectionModel;

  const HomeSectionsItem({
    required this.sectionModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('HomeSectionsItem.build ${sectionModel.to}');
        switch (sectionModel.to) {
          case 'timeline':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryScreen()));
            break;
          case 'chats':
            goToContactsScreen(context);
            break;
          case 'events':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
            break;
          case 'announcements':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
            break;
          case 'medicines':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicinesProfessorsScreen()));
            break;
          case 'authorizations':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryScreen(filterAttendance: true)));
            break;
          case 'multimedia':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryScreen(filterMedia: true)));
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10.csw,
            right: 10.csw,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 75.csh,
                width: 75.csh,
                child: CommonImage(imageUrl: sectionModel.icon),
              ),
              SizedBox(
                height: 14.csh,
              ),
              Text(
                sectionModel.title.tr(context),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textColor,
                ),
              ),
              SizedBox(
                height: 30.csh,
              ),
              Container(
                padding: EdgeInsets.all(7.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: context.colors.secondaryGrey,
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_right_sharp,
                  color: context.colors.secondaryGrey,
                  size: 20.h,
                ),
              ),
              SizedBox(
                height: 8.csh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
