import 'dart:async';

import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/text/powered_by.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/choose_language/presentation/choose_language_screen.dart';
import 'package:escola/features/main/presentation/main_screen.dart';
import 'package:escola/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:escola/features/your_account_under_review/presentation/your_account_under_review_screen.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SplashBloc>(
      create: (BuildContext context) => di<SplashBloc>()..add(FetchSplashEvent()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (BuildContext context, SplashState state) {
          if (state is SplashFailure) {
            // Refresh from server failed (transient network/5xx). Surface the message,
            // but don't strand the user — route based on persisted UserBloc state so
            // they can still reach the app offline-first.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure.message)),
            );
            Timer(const Duration(seconds: 2), () {
              final persistedUser = UserBloc.get.state.user;
              if (persistedUser == null) {
                ChooseLanguageScreen.push(context);
              } else if (persistedUser.isApproval == true) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const YourAccountUnderReviewScreen()),
                  (route) => false,
                );
              }
            });
          }
          if (state is SplashSuccess) {
            Timer(const Duration(seconds: 2), () async {
              if (state.hasUser) {
                if (UserBloc.get.state.user?.isApproval == true) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const YourAccountUnderReviewScreen()),
                    (route) => false,
                  );
                }
              } else {
                ChooseLanguageScreen.push(context);
              }
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SizedBox(
            width: double.infinity,
            child: Center(
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
                            color: const Color(0xffF2F2F2)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.center,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // if (context.isProfessors) const ProfessorsContainer(),
                        // if (context.isProfessors) SizedBox(height: 100.h),
                        SizedBox(
                          child: ConfigSelector(
                            selector: (config) => config.logo,
                            builder:(context, logo) => CommonImage(
                              imageUrl: logo ?? Assets.icons.filhosLogo.path,
                              fallBackImagePath: Assets.icons.filhosLogo.path,
                              height: 260.h,
                            ),
                          ),
                        ),
                        if (context.isProfessors) SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: const Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: PoweredByWidget(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LogoBackGround extends StatelessWidget {
  final Color iconColor;
  const LogoBackGround({super.key, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-150.w, -10.h),
      child: Transform.scale(
        scale: 1.3,
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: CommonImage(
              imageUrl: Assets.images.defaultSplashBackground.path,
              fallBackImagePath: Assets.images.defaultSplashBackground.path,
              width: 600.h,
              height: 600.h,
              color: iconColor),
        ),
      ),
    );
  }
}
