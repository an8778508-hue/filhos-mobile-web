import 'package:dots_indicator/dots_indicator.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/featured_events/bloc/featured_events_bloc.dart';
import 'package:escola/features/settings/accept_event/accept_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bloc/featured_events_state.dart';

class FeaturedEventsScreen extends StatefulWidget {
  const FeaturedEventsScreen({super.key});

  static open(BuildContext context) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const FeaturedEventsScreen(),
        ),
      );

  @override
  State<FeaturedEventsScreen> createState() => _FeaturedEventsScreenState();
}

class _FeaturedEventsScreenState extends State<FeaturedEventsScreen> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: BlocSelector<FeaturedEventsBloc, FeaturedEventsState, bool>(
        selector: (state) => state.eventsState.loading,
        builder: (context, loading) => loading
            ? const Center(
                child: LoadingOverlay(),
              )
            : BlocSelector<FeaturedEventsBloc, FeaturedEventsState, List<EventModel>>(
                selector: (state) => state.eventsState.data,
                builder: (context, data) => FeaturedEventsBody(data: data),
              ),
      ),
    );
  }
}

class FeaturedEventsBody extends StatefulWidget {
  const FeaturedEventsBody({
    super.key,
    required this.data,
  });

  final List<EventModel> data;

  @override
  State<FeaturedEventsBody> createState() => _FeaturedEventsBodyState();
}

class _FeaturedEventsBodyState extends State<FeaturedEventsBody> {
  late final PageController pageController;

  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  List<EventModel> get data => widget.data;

  String? get currentId {
    final id = data.safeElementAt(currentPage)?.id;
    if (id != null) {
      return id;
    }
    return null;
  }

  Future nextPage() async {
    if (pageController.hasClients) {
      if (currentPage >= data.length - 1) {
        Navigator.of(context).pop();
      } else {
        await pageController.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (value) {
                currentPage = value;
                if (mounted) {
                  setState(() {});
                }
              },
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                print('_FeaturedEventsBodyState.build ${validateString(item.imageUrl, assetsPath('default_logo'))}');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0.0.w).add(EdgeInsets.only(bottom: 40.h)),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => PhotoViewer(url: item.imageUrl, tag: item.imageUrl)));
                          },
                          child: SizedBox(
                            height: 500.h,
                            child: Stack(
                              children: [
                                  Positioned.fill(
                                  child: Padding(
                                    padding:  EdgeInsets.all(validString(item.imageUrl)?0:100.h),
                                    child: CommonImage(
                                      imageUrl: validateString(item.imageUrl, assetsPath('default_logo')),
                                      height: 500.h,
                                      width: double.infinity,
                                      fit: validString(item.imageUrl) ? BoxFit.cover : BoxFit.contain,
                                    ),
                                  ),
                                ),
                                  Positioned.fill(
                                  child: Container(
                                    color: Colors.black12,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 5.h),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 10.w),
                                      Container(
                                        clipBehavior: Clip.antiAlias,
                                        margin: EdgeInsets.symmetric(vertical: 8.csh),
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await nextPage();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 15.csw, vertical: 10.csh),
                                            child: Text(
                                              LocalizationKeys.remind_later.tr(context),
                                              textAlign: TextAlign.center,
                                              textDirection: TextDirection.ltr,
                                              style: TextStyle(
                                                color: context.colors.secondaryTextColor,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      MaterialButton(
                                        minWidth: 20.w,
                                        onPressed: () async {
                                          if (currentId != null) {
                                            await BlocProvider.of<FeaturedEventsBloc>(context).cache(currentId!);
                                            await nextPage();
                                          }
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (validString(item.title))
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0.w).add(EdgeInsets.only(bottom: 10.h)),
                        child: CustomSelectableText(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25.sp,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    if (validString(removeHtml(item.description)))
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0.w).add(EdgeInsets.only(bottom: 20.h)),
                          child: Text(
                            removeHtml(item.description)!,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: context.colors.textColor,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (data.length > 1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0.w).add(EdgeInsets.only(bottom: 20.h)),
              child: DotsIndicator(
                dotsCount: data.length,
                position: currentPage.toDouble(),
                decorator: DotsDecorator(
                  size: Size(8.h, 8.h),
                  spacing: EdgeInsets.only(left: 10.w, right: 10.w),
                  activeSize: Size(8.h, 8.h),
                  color: context.colors.secondaryGrey,
                  // Inactive color
                  activeColor: context.colors.primary,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0.w).add(EdgeInsets.only(bottom: 20.h)),
            child: InkWell(
              onTap: () async {
                if (currentId != null) {
                  final nav = Navigator.of(context);
                  await BlocProvider.of<FeaturedEventsBloc>(context).cache(currentId!);
                  if (mounted) {
                    await nav.push(
                      MaterialPageRoute(
                        builder: (context) => AcceptEventScreen(eventId: currentId!),
                      ),
                    );
                    if (currentId != null) {
                      await nextPage();
                    }
                  }
                }
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  LocalizationKeys.details.tr(context),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
