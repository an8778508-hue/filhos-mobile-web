import 'dart:async';

import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/widgets/user_builder.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/home/bloc/home_bloc.dart';
import 'package:escola/features/home/widgets/event_item.dart';
import 'package:escola/features/home/widgets/home_cards_list.dart';
import 'package:escola/features/home/widgets/home_child_item.dart';
import 'package:escola/features/home/widgets/home_sections_item.dart';
import 'package:escola/features/search/presentation/search_screen.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/children_menus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getAlarms(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        getAlarms(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      lazy: false,
      create: (context) => di<HomeBloc>()..add(HomeFetchDataEvent()),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: context.colors.scaffold,
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              switch (state) {
                case HomeInitial():
                  return Container();
                case HomeLoading():
                  return const Center(child: Loading());
                case HomeError():
                  return Center(
                    child: ErrorScreen(
                        errorText: state.failure.message,
                        onRetry: () {
                          context.read<HomeBloc>().add(HomeFetchDataEvent());
                        }),
                  );

                case HomeFetchedSuccessfully():
                  final events = state.homeModel.events;
                  final children = state.homeModel.children;

                  return SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        UserSelector(
                          selector: (state) => state.user,
                          builder: (context, user) {
                            final user = UserBloc.get.state.user;
                            final String? name = user?.name;
                            final String hello = LocalizationKeys.hello.tr(context);
                            final title = stringNotNullOrEmpty(name) ? '$hello\n${name!}' : hello;
                            return MyAppBar(
                              title: title,
                              isHome: true,
                              image: user?.image,
                              color: context.colors.primaryDark,
                              actionWidget: context.isProfessors
                                  ? IconButton(
                                      onPressed: () {
                                        WidgetFunctions.navigateTo(context, const SearchScreen());
                                      },
                                      icon: Icon(
                                        Icons.search,
                                        size: 24.h,
                                        color: context.colors.background,
                                      ),
                                    )
                                  : null,
                              hasAvatar: true,
                              hasNotification: true,
                            );
                          },
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              Completer<void> completer = Completer();
                              BlocProvider.of<HomeBloc>(context).add(ReloadHomeFetchDataEvent(completer: completer));
                              return await completer.future;
                            },
                            child: SingleChildScrollView(
                              padding: EdgeInsets.zero,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (context.isParents) const HomeCardsList(),
                                if (context.isParents)
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ChildrenMenus(),
                                    ],
                                  ),
                                if (events.isNotEmpty) ...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 19.csw, vertical: 30.csh),
                                    child: Text(
                                      LocalizationKeys.events.tr(context),
                                      style: TextStyle(
                                        fontSize: 25.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 410.csh,
                                    width: double.maxFinite,
                                    child: ListView.separated(
                                      separatorBuilder: (context, index) => SizedBox(
                                        width: 13.csw,
                                      ),
                                      padding: EdgeInsetsDirectional.symmetric(horizontal: 18.w),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: events.length,
                                      itemBuilder: (context, index) => EventItem(
                                        width: 353.csw,
                                        eventModel: events[index],
                                      ),
                                    ),
                                  ),
                                ],
                                // else ...[
                                //   EmptyWidget(
                                //       title: LocalizationKeys.no_events.tr(context), icon: Assets.icons.event.path),
                                // ],
                                if (context.isParents) ...[
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 30.csh),
                                    child: Text(
                                      LocalizationKeys.my_children.tr(context),
                                      style: TextStyle(
                                        fontSize: 25.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (children.isNotEmpty) ...[
                                    Container(
                                      margin: EdgeInsets.only(left: 6.csw),
                                      height: 278.csh,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: children.length,
                                        itemBuilder: (context, index) => HomeChildItem(child: children[index]),
                                      ),
                                    ),
                                  ] else ...[
                                    EmptyWidget(
                                        title: LocalizationKeys.no_children.tr(context), icon: Assets.icons.child.path),
                                  ],
                                ],
                                if (context.isProfessors)
                                  ConfigSelector(
                                    selector: (config) => config.homeSections,
                                    builder: (context, sections) => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sections.isNotEmpty) ...[
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 30.csh),
                                            child: Text(
                                              LocalizationKeys.sections.tr(context),
                                              style: TextStyle(
                                                fontSize: 25.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(horizontal: 18.csw),
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                mainAxisSpacing: 25.h,
                                                crossAxisSpacing: 14.w,
                                                childAspectRatio: 190 / 230,
                                              ),
                                              scrollDirection: Axis.vertical,
                                              itemCount: sections.length,
                                              itemBuilder: (context, index) =>
                                                  HomeSectionsItem(sectionModel: sections[index]),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                SizedBox(
                                  height: 30.csh,
                                )
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
              }
            },
          ),
        );
      }),
    );
  }
}
