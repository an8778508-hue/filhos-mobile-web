import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/login/presentation/login_screen.dart';
import 'package:escola/features/onboard/presentation/onboard_screen.dart';
import 'package:escola/my_app.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  static push(BuildContext context){
    if (Config.get.langs.length >1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChooseLanguageScreen()),
            (route) => false,
      );
    }else{
      if (context.isProfessors) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        if (validList(Config.get.onBoards)) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const OnBoardScreen()));
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
        }
      }
    }
  }

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) => requestTrackingPermission());
    super.initState();
  }

  Future<void> requestTrackingPermission() async {
    final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined && mounted && Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.fromSettings) MyAppBar(hasNotification: false, color: Colors.transparent),
            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Transform.translate(
                      offset: Offset(-20.w, 50.h),
                      child: Transform.scale(
                        scale: 0.9,
                        child: CommonImage(
                            imageUrl: Assets.images.defaultSplashBackground.path,
                            fallBackImagePath: Assets.images.defaultSplashBackground.path,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            color: const Color(0xff053E60)),
                      ),
                    ),
                  ),

                  // LogoBackGround(iconColor: Color(0xff053E60)),
                  ConfigSelector(
                    selector: (config) => config.langs,
                    builder: (context, state) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (int index = 0; index < Config.get.langs.length; index++)
                          Column(
                            children: [
                              ButtonWithIcon(
                                textDirection: TextDirection.ltr,
                                marginWidth: 50.w,
                                marginHeight: 0.0,
                                borderRadius: 25.r,
                                hasBorder: false,
                                isTextExpanded: true,
                                buttonBackgroundColor: Config.get.langs[index].color,
                                textAlign: TextAlign.center,
                                fontWeight: FontWeight.w300,
                                fontSize: 18.sp,
                                firstIconBoxFit: BoxFit.cover,
                                firstIconPathRadius: 100.r,
                                textColor: Config.get.langs[index].textColor,
                                firstIconPath: Config.get.langs[index].image,
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 0.csw, vertical: 7.5.csh),
                                firstIconHeight: 25.csw,
                                firstIconWidth: 25.csw,
                                onPressed: () async {
                                  UserBloc.get.selectLang(Config.get.langs[index].code,Config.get.langs[index].codeWithLocale);
                                  if (widget.fromSettings) {
                                    Navigator.pop(context);
                                    return;
                                  }
                                  if (mounted) {
                                    if (context.isProfessors) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    } else {
                                      if (validList(Config.get.onBoards)) {
                                        Navigator.push(
                                            context, MaterialPageRoute(builder: (_) => const OnBoardScreen()));
                                      } else {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          (route) => false,
                                        );
                                      }
                                    }
                                  }
                                },
                                text: Config.get.langs[index].title,
                              ),
                              SizedBox(
                                height: 29.h,
                              ),
                            ],
                          ),
                        SizedBox(
                          height: 19.csh,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
