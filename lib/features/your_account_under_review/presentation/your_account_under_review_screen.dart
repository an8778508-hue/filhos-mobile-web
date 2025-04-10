import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/background_services/bloc/background_services_bloc.dart';
import 'package:escola/features/login/presentation/login_screen.dart';
import 'package:escola/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class YourAccountUnderReviewScreen extends StatefulWidget {
  const YourAccountUnderReviewScreen({super.key});

  @override
  State<YourAccountUnderReviewScreen> createState() =>
      _YourAccountUnderReviewScreenState();
}

class _YourAccountUnderReviewScreenState
    extends State<YourAccountUnderReviewScreen> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    context.read<BackgroundServicesBloc>().add(CallServices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const LogoBackGround(iconColor: Color(0xff053E60)),
            Container(
              color: Colors.black26,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MyIcon(
                  'assets/icons/clockwise.svg',
                  size: 107.h,
                ),
                SizedBox(height: 25.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 60.w),
                  child: Text(
                    LocalizationKeys.your_account_is_under_review.tr(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 30.sp,
                      color: context.colors.secondaryTextColor,
                    ),
                  ),
                ),
                SizedBox(height: 200.h),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: MaterialButton(
                minWidth: 20.w,
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen(
                                hasBackButton: true,
                              )));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocalizationKeys.login_with_another_account.tr(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: context.colors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      width: 5.w,
                    ),
                    Icon(
                      Icons.keyboard_arrow_right_sharp,
                      color: context.colors.secondaryTextColor,
                      size: 20.h,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
