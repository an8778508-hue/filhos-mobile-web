import 'package:dots_indicator/dots_indicator.dart';
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/choose_language/presentation/choose_language_screen.dart';
// LoginEntry routes to either the legacy Firebase login or the new
// server-driven login depending on Config.serverDrivenAuthEnabled (spec.md
// §Deviations item 1: "flag on Firebase, pass not delete").
import 'package:escola/features/server_driven_auth/presentation/login_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnBoardScreen extends StatefulWidget {
  const OnBoardScreen({super.key});

  @override
  State<OnBoardScreen> createState() => _OnBoardScreenState();
}

class _OnBoardScreenState extends State<OnBoardScreen> with SingleTickerProviderStateMixin {
  final controller = PageController();
  int index = 0;
  bool end = false;

  @override
  initState() {
    super.initState();
    end = Config.get.onBoards.length == 1;
  }

  @override
  Widget build(BuildContext context) {
    return ConfigListener(
      listenWhen: compareStates([(s) => s.onBoards]),
      listener: (context, config) {
        if (mounted) {
          setState(() {
            end = config.onBoards.length == 1;
          });
          if (!validList(config.onBoards)) {
            Navigator.pushAndRemoveUntil(
              context,
              LoginEntry.route(),
              (route) => false,
            );
          }
        }
      },
      child: ConfigSelector(
        selector: (config) => config.onBoards,
        builder: (context, onBoards) => Scaffold(
          backgroundColor: context.colors.background,
          body: Stack(
            children: [
              Column(
                children: <Widget>[
                  Expanded(
                    child: ConfigSelector(
                      selector: (config) => config.onBoards,
                      builder: (context, onBoards) => PageView.builder(
                        onPageChanged: (pageIndex) => setState(
                          () {
                            index = pageIndex;
                            if (pageIndex == Config.get.onBoards.length - 1) {
                              end = true;
                            }
                          },
                        ),
                        itemBuilder: (ctx, index) => SizedBox(
                          height: double.maxFinite,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
                            SizedBox(
                              height: 513.h,
                              width: double.maxFinite,
                              child: Stack(
                                children: [
                                  SizedBox.expand(
                                    child: ConfigSelector(
                                      selector: (config) => config.onBoards,
                                      builder: (context, onBoards) => CommonImage(
                                        imageUrl: onBoards.safeElementAt(index)?.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox.expand(
                                    child: Container(
                                      color: Colors.black12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10.h,
                            ),
                            const Spacer(),
                            Container(
                              margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                              child: ConfigSelector(
                                selector: (config) => config.onBoards,
                                builder: (context, onBoards) => Text(
                                  onBoards.safeElementAt(index)?.title ?? '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25.sp,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10.csh,
                            ),
                            Container(
                              margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                              child: ConfigSelector(
                                selector: (config) => config.onBoards,
                                builder: (context, onBoards) => Text(
                                  onBoards.safeElementAt(index)?.subTitle.tr(context) ?? '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: context.colors.textColor,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 10.h,
                            ),
                          ]),
                        ),
                        itemCount: onBoards.length,
                        controller: controller,
                      ),
                    ),
                  ),
                  if (Config.get.onBoards.isNotEmpty) ...[
                    DotsIndicator(
                      dotsCount: Config.get.onBoards.length,
                      position: index.toDouble(),
                      decorator: DotsDecorator(
                        size: Size(8.h, 8.h),
                        spacing: EdgeInsets.only(left: 10.w, right: 10.w),
                        activeSize: Size(8.h, 8.h),
                        color: context.colors.secondaryGrey,
                        // Inactive color
                        activeColor: context.colors.primary,
                      ),
                    ),
                    SizedBox(
                      height: 60.h,
                    ),
                  ],
                  ButtonWithIcon(
                    onPressed: () async {
                      if (end) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          LoginEntry.route(),
                          (route) => false,
                        );
                        // final prefs = await SharedPreferences.getInstance();
                        // prefs.setBool('seen', true);
                      } else {
                        controller.nextPage(
                          curve: Curves.fastLinearToSlowEaseIn,
                          duration: const Duration(milliseconds: 500),
                        );
                      }
                    },
                    firstIconBoxFit: BoxFit.cover,
                    textDirection: TextDirection.ltr,
                    hasBorder: false,
                    isTextExpanded: true,
                    marginWidth: 50.w,
                    marginHeight: 0.0,
                    borderRadius: 25.r,
                    textColor: context.colors.secondaryTextColor,
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 14.csw,
                      vertical: 7.5.csh,
                    ),
                    fontWeight: FontWeight.w500,
                    fontSize: 20.sp,
                    buttonBackgroundColor: context.colors.primaryDark,
                    textAlign: TextAlign.center,
                    text: (end ? LocalizationKeys.start_now : LocalizationKeys.next).tr(context),
                  ),
                  SizedBox(
                    height: 37.csh,
                  ),
                ],
              ),
              SafeArea(
                child: ConfigSelector(
                  selector: (config) => config.langs,
                  builder:(context, state) => Row(
                    children: <Widget>[
                      SizedBox(
                        width: 20.csw,
                      ),
                      if (Config.get.langs.isNotEmpty)
                        Builder(builder: (context) {
                          final lang = Config.get.langs.firstWhere((e) => e.code == UserBloc.get.state.language,
                              orElse: () => Config.get.langs.first);
                          return Container(
                            clipBehavior: Clip.antiAlias,
                            margin: EdgeInsets.symmetric(vertical: 8.csh),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (Config.get.langs.length >1) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChooseLanguageScreen()));
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.csw, vertical: 10.csh)
                                    .add(EdgeInsetsDirectional.only(end: 10.csw)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: CommonImage(
                                        imageUrl: lang.image,
                                        size: 20.csw,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5.csw,
                                    ),
                                    Text(
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.ltr,
                                      lang.title,
                                      style: TextStyle(
                                        color: lang.color,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      const Spacer(),
                      if (!end)
                        MaterialButton(
                          minWidth: 20.w,
                          onPressed: () async {
                            Navigator.pushAndRemoveUntil(
                              context,
                              LoginEntry.route(),
                              (route) => false,
                            );
                            // final prefs = await SharedPreferences.getInstance();
                            // prefs.setBool('seen', true);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                LocalizationKeys.skip.tr(context),
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
                      SizedBox(
                        width: 10.w,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
