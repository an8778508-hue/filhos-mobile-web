import 'dart:io';

import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/components/text/powered_by.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/about/bloc/about_bloc.dart';
import 'package:escola/features/settings/about/bloc/about_events.dart';
import 'package:escola/features/settings/about/bloc/about_states.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      extendBodyBehindAppBar: true,
      appBar: MyAppBar(
        title: LocalizationKeys.about.tr(context),
        hasNotification: true,
        color: Colors.transparent,
      ),
      body: BlocProvider<AboutBloc>(
        create: (BuildContext context) => di<AboutBloc>()..add(const FetchAbout()),
        child: Builder(
          builder: (context) {
            return BlocSelector<AboutBloc, AboutStates, AboutState>(
              selector: (state) => state.aboutState,
              builder: (context, state) {
                final about = state.data;
                final loading = state.loading;
                if (loading) {
                  return SafeArea(
                    child: Container(
                      color: context.colors.background,
                      child: Center(
                          child: LoadingOverlay(
                      )),
                    ),
                  );
                }
                return Stack(
                  children: [
                    SizedBox.expand(
                      child: Column(
                        children: [
                          Container(
                            height: 400.h,
                            width: double.maxFinite,
                            color: context.colors.primary,
                          ),
                          Expanded(
                            child: Container(
                              width: double.maxFinite,
                              color: context.colors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox.expand(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 140.h,
                            ),
                            GestureDetector(
                              onTap: () {
                                try {
                                  launchUrl(Uri.parse(Config.appUrl));
                                } on Exception catch (e) {
                                  debugPrint(e.toString());
                                }
                              },
                              child: SizedBox(
                                height: 90.h,
                                width: 210.w,
                                child: CommonImage(
                                  imageUrl: assetsPath('filhos_logo_white'),
                                  fallBackImagePath: Assets.icons.defaultHorizontalLogo.path,
                                  height: 90.h,
                                  width: 210.w,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40.h,
                            ),
                            Text(
                              'V ${validateString(state.version)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.secondaryTextColor,
                                fontSize: 24.sp,
                                height: 1,
                              ),
                            ),
                            SizedBox(
                              height: 10.h,
                            ),
                            if (!state.canUpdate)
                              Text(
                                LocalizationKeys.your_app_version_is_up_to_date.tr(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                  color: context.colors.secondaryTextColor,
                                  height: 1,
                                ),
                              ),
                            SizedBox(
                              height: 25.h,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
                              margin: EdgeInsets.symmetric(horizontal: 18.w),
                              decoration: BoxDecoration(
                                color: context.colors.primaryBackground,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomSelectableText(
                                    LocalizationKeys.about_filhos_title.tr(context),
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textColor,
                                      fontSize: 20.sp,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15.h,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomSelectableText(
                                          LocalizationKeys.about_filhos_description.tr(context),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: context.colors.textColor,
                                            fontSize: 16.sp,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 16.h,
                            ),
                            if (validString(about?.email) || validString(about?.phone))
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
                                margin: EdgeInsets.symmetric(horizontal: 18.w),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryBackground,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      LocalizationKeys.contact_us.tr(context),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.textColor,
                                        fontSize: 20.sp,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15.h,
                                    ),
                                    if (validString(about?.email))
                                      Row(
                                        children: [
                                          CommonImage(
                                            imageUrl: assetsPath('email'),
                                            height: 20.h,
                                            width: 20.h,
                                          ),
                                          SizedBox(
                                            width: 16.w,
                                          ),
                                          Text(
                                            '${LocalizationKeys.email.tr(context)}: ',
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: context.colors.textColor,
                                              fontSize: 16.sp,
                                              height: 1.25,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomSelectableText(
                                              validateString(about?.email),
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                color: context.colors.textColor,
                                                fontSize: 16.sp,
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(
                                      height: 15.h,
                                    ),
                                    if (validString(about?.phone))
                                      Row(
                                        children: [
                                          CommonImage(
                                            imageUrl: assetsPath('phone'),
                                            height: 20.h,
                                            width: 20.h,
                                          ),
                                          SizedBox(
                                            width: 16.w,
                                          ),
                                          Text(
                                            '${LocalizationKeys.phone.tr(context)}: ',
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: context.colors.textColor,
                                              fontSize: 16.sp,
                                              height: 1.25,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomSelectableText(
                                              validateString(about?.phone),
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                color: context.colors.textColor,
                                                fontSize: 16.sp,
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              height: 16.h,
                            ),
                            ButtonWithIcon(
                              textDirection: TextDirection.ltr,
                              marginWidth: 20.w,
                              marginHeight: 0.0,
                              borderRadius: 10.r,
                              hasBorder: false,
                              isTextExpanded: true,
                              textAlign: TextAlign.center,
                              buttonBackgroundColor: context.colors.primaryBackground,
                              borderColor: context.colors.greyLight,
                              borderWidth: 1.w,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              elevation: 0,
                              firstIconPathRadius: 100.r,
                              textColor: context.colors.primary,
                              firstIconPath: assetsPath('share'),
                              firstIconColor: context.colors.textColor,
                              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                              firstIconHeight: 20.h,
                              firstIconWidth: 20.h,
                              onPressed: () async {
                                try {
                                  final appUrl =
                                      Platform.isIOS ? Config.get.appInfo.iosUrl : Config.get.appInfo.androidUrl;

                                  Share.share(appUrl, subject: Config.get.appInfo.appName);
                                } on Exception catch (e) {
                                  print('_AboutScreenState.build error: $e');
                                }
                              },
                              text: LocalizationKeys.share.tr(context),
                            ),
                            SizedBox(
                              height: 10.h,
                            ),
                            ButtonWithIcon(
                              textDirection: TextDirection.ltr,
                              marginWidth: 20.w,
                              marginHeight: 0.0,
                              borderRadius: 10.r,
                              hasBorder: false,
                              isTextExpanded: true,
                              textAlign: TextAlign.center,
                              buttonBackgroundColor: context.colors.primaryBackground,
                              borderColor: context.colors.greyLight,
                              borderWidth: 1.w,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              elevation: 0,
                              firstIconPathRadius: 100.r,
                              textColor: context.colors.primary,
                              firstIconPath: assetsPath('fav'),
                              firstIconColor: context.colors.textColor,
                              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                              firstIconHeight: 20.h,
                              firstIconWidth: 20.h,
                              onPressed: () async {
                                launchStore();
                              },
                              text: LocalizationKeys.rate.tr(context),
                            ),
                            SizedBox(
                              height: 30.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: SafeArea(child: PoweredByWidget()),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void launchStore() async {
    final packageName = (await PackageInfo.fromPlatform()).packageName;
    if (Platform.isAndroid) {
      launchUrl(
        Uri.parse("market://details?id=$packageName"),
        mode: LaunchMode.externalApplication,
      );
    } else {
      launchUrl(
        (Uri.parse("https://apps.apple.com/app/id${Config.get.appInfo.appStoreId}")),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
