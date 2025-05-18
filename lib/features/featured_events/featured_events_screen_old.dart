import 'package:dots_indicator/dots_indicator.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/components/text/text_html.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/featured_events/bloc/featured_events_bloc.dart';
import 'package:escola/features/settings/accept_event/accept_events.dart';
import 'package:escola/features/settings/accept_event/widgets/icon_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/utils/funuctions/global_functions.dart';
import 'bloc/featured_events_state.dart';

class FeaturedEventsScreen extends StatefulWidget {
  const FeaturedEventsScreen({Key? key}) : super(key: key);

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
      insetPadding: EdgeInsets.all(20.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      clipBehavior: Clip.antiAlias,
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
          SizedBox(height: 5.h),
          Row(
            children: [
              SizedBox(width: 10.w),
              TextButton(
                onPressed: () async {
                  await nextPage();
                },
                child: Text(
                  LocalizationKeys.remind_later.tr(context),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  if (currentId != null) {
                    await BlocProvider.of<FeaturedEventsBloc>(context).cache(currentId!);
                    await nextPage();
                  }
                },
                child: Text(
                  LocalizationKeys.skip.tr(context),
                  style: TextStyle(
                    color: context.colors.greyDark,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
            ],
          ),
          Expanded(
            child: Column(
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (validString(item.imageUrl))
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0.w).add(EdgeInsets.only(bottom: 20.h)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => PhotoViewer(url: item.imageUrl, tag: item.imageUrl)));
                                  },
                                  child: CommonImage(
                                    imageUrl: item.imageUrl,
                                    height: 300.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0.w).add(EdgeInsets.only(bottom: 20.h)),
                            child: Row(
                              children: [
                                if (!(item.startDate == null && item.endDate == null))
                                  const IconCardWidget(
                                    icon: FontAwesomeIcons.solidCalendar,
                                  ),
                                SizedBox(width: 15.csh),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.startDate != null)
                                      Text(
                                        () {
                                          bool isSameDateDay = isSameDay(time1: item.startDate!, time2: item.endDate!);
                                          return isSameDateDay;
                                        }()
                                            ? DateFormat('dd MMM,yyyy').format(item.startDate!)
                                            : DateFormat('dd MMM,yyyy - hh:mm a').format(item.startDate!),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
                                      ),
                                    SizedBox(height: 5.csh),
                                    if (item.endDate != null)
                                      Text(
                                        () {
                                          bool isSameDateDay = isSameDay(time1: item.startDate!, time2: item.endDate!);
                                          return isSameDateDay;
                                        }()
                                            ? "${LocalizationKeys.from.tr(context)} ${DateFormat('hh:mm a').format(item.startDate!)} ${LocalizationKeys.to.tr(context)} ${DateFormat('hh:mm a').format(item.endDate!)}"
                                            : DateFormat('dd MMM,yyyy - hh:mm a').format(item.endDate!),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.greyLight,
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          if (validString(item.title))
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0.w).add(EdgeInsets.only(bottom: 20.h)),
                              child: CustomSelectableText(
                                item.title,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: context.colors.textColor,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (validString(item.description))
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0.w).add(EdgeInsets.only(bottom: 20.h)),
                                child: SingleChildScrollView(
                                  child: TextHtml(
                                    item.description,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: context.colors.greyDarker,
                                    ),
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
                        await BlocProvider.of<FeaturedEventsBloc>(context).cache(currentId!);
                        if (mounted) {
                          await Navigator.of(context).push(
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
          ),
        ],
      ),
    );
  }
}
