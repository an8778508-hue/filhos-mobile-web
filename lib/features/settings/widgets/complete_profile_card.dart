import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/features/settings/edit_profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompleteProfileCard extends StatefulWidget {
  final double percentage;

  const CompleteProfileCard({super.key, required this.percentage});

  @override
  State<CompleteProfileCard> createState() => _CompleteProfileCardState();
}

class _CompleteProfileCardState extends State<CompleteProfileCard> {
  late final ValueNotifier<double> percent ;

  @override
  void initState() {
    percent = ValueNotifier(widget.percentage);
    super.initState();
  }

  @override
  void dispose() {
    percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 18.csh, horizontal: 50.csw),
      margin: EdgeInsets.only(bottom: 10.csw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalizationKeys.profile.tr(context),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: getHeightByNumber(12),
          ),
          Text(
            LocalizationKeys.you_are_almost_done_50_complete_the_profile.tr(context,percent.value.toStringAsFixed(0)),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(
            height: getHeightByNumber(22),
          ),
          Container(
            height: getHeightByNumber(10),
            width: getWidthByNumber(260),
            decoration: BoxDecoration(
              color: context.colors.scaffold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  height: getHeightByNumber(7),
                  width: ((percent.value / 100) * getWidthByNumber(260)),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(
            height: getHeightByNumber(22),
          ),
          MaterialButton(
            minWidth: double.infinity,
            color: context.colors.primary,
            textColor: context.colors.background,
            padding: EdgeInsets.symmetric(vertical: 10.csh, horizontal: 20.csw),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: Text(
              LocalizationKeys.complete_profile.tr(context),
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        ],
      ),
    );
  }
}
