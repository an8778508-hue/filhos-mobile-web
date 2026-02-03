import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/menu_screen.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

class ChildrenMenusScreen extends StatelessWidget {
  const ChildrenMenusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: MyAppBar(
        title: LocalizationKeys.menus.tr(context),
      ),
      body: const ChildrenMenus(isScreen: true),
    );
  }
}

class ChildrenMenus extends StatelessWidget {
  const ChildrenMenus({super.key, this.isScreen = false});

  final bool isScreen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      di<DiaryBloc>()
        ..add(const GetMenus()),
      child: BlocBuilder<DiaryBloc, DiaryState>(
        builder: (context, DiaryState state) {
          final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
          if (state is MenusLoading) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0.h),
              child: const Center(
                child: Loading(),
              ),
            );
          }
          if (state is MenusLoaded) {
          final childrenMenus = state.menus;
            if (!validList(childrenMenus)) {
              return SizedBox();

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0.h),
                child: Center(
                  child: EmptyWidget(
                    icon: Assets.icons.child.path,
                    title: LocalizationKeys.no_children.tr(context),
                    iconColor: context.colors.primary,
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 47.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    LocalizationKeys.menus.tr(context),
                    style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                DefaultTabController(
                  length: childrenMenus.length,
                  child: Builder(
                    builder: (context) {
                      final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
                      return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 17.w),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow:isScreen?null: getElevation(Elevation.k24, Colors.black.withOpacity(.05)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                                    color: context.colors.greyLighter,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 15.h),
                                      TabBar(
                                        indicatorWeight: 4.h,
                                        indicatorColor: context.colors.primaryDark,
                                        indicatorSize: TabBarIndicatorSize.label,
                                        isScrollable: childrenMenus.length > 3,
                                        onTap: (value) {
                                          DefaultTabController
                                              .of(context)
                                              .index = value;
                                        },
                                        tabs: [
                                          for (int i = 0; i < childrenMenus.length; i++)
                                            Tab(
                                              height:  isTablet?
                                                  MediaQuery
                                                      .sizeOf(context)
                                                      .height * .18
                                                  : MediaQuery
                                                  .sizeOf(context)
                                                  .height * .14,
                                              child: Container(
                                                color: Colors.transparent,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(bottom: 8.0.h),
                                                      child: SizedBox(
                                                        width: 60.w,
                                                        height: 60.w,
                                                        child: Avatar(
                                                          isChild: true,
                                                          backgroundColor: Colors.white,
                                                          avatar: childrenMenus[i].childModel.avatar,
                                                          ignoreGesutre: true,
                                                        ),
                                                      ),
                                                    ),
                                                    if (validString(childrenMenus[i].childModel.name))
                                                      Padding(
                                                        padding: EdgeInsets.only(bottom: 14.0.h),
                                                        child: SizedBox(
                                                          child: Text(
                                                            getFirstName(childrenMenus[i].childModel.name!),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                              color: context.colors.textColor,
                                                              fontSize: 16.sp,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
                                    color: context.colors.background,
                                  ),
                                  child: ListenableBuilder(
                                    listenable: DefaultTabController.of(context),
                                    builder: (context, child) =>
                                        ChildMenuPage(
                                          key: ValueKey(childrenMenus[DefaultTabController
                                              .of(context)
                                              .index].childModel.id),
                                          child: childrenMenus[DefaultTabController
                                              .of(context)
                                              .index].childModel,
                                          menus: childrenMenus[DefaultTabController
                                              .of(context)
                                              .index].menus,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                    },
                  ),
                ),
              ],
            );
          }
          return SizedBox();
        },
      ),
    );
  }
}

class ChildMenuPage extends StatelessWidget {
  const ChildMenuPage({
    super.key,
    required this.child,
    required this.menus,
  });

  final ChildModel child;
  final List<Menu> menus;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        switch (state) {
          case MenusLoaded():
            return menus.isEmpty
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0.h),
              child: Center(
                child: EmptyWidget(
                  icon: assetsPath('food_icon'),
                  title: LocalizationKeys.no_menu.tr(context),
                  iconColor: context.colors.primary,
                ),
              ),
            )
                : ChildMenuBody(
              child: child,
              menus: menus,
            );

          case MenusError():
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0.h),
              child: Center(
                child: ErrorScreen(
                    errorText: state.failure.message,
                    onRetry: () {
                      context.read<DiaryBloc>().add(GetMenus(
                      ));
                    }),
              ),
            );
          default:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0.h),
              child: const Center(
                child: Loading(),
              ),
            );
        }
      },
    );
  }
}

class ChildMenuBody extends StatefulWidget {
  const ChildMenuBody({
    super.key,
    required this.child,
    required this.menus,
  });

  final ChildModel child;
  final List<Menu> menus;

  @override
  State<ChildMenuBody> createState() => _ChildMenuBodyState();
}

class _ChildMenuBodyState extends State<ChildMenuBody> {
  bool seeAll = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        List<Menu> menus = widget.menus;

        menus = menus.where((menu) => validString(menu.title) && validList(menu.items)).toList();
        if (!seeAll) {
          if (menus.length > 2) {
            menus = menus.sublist(0, 2);
          }
        }

        if (!validList(menus)) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0.h),
            child: Center(
              child: EmptyWidget(
                icon: assetsPath('food_icon'),
                title: LocalizationKeys.no_menu.tr(context),
                iconColor: context.colors.primary,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            SeparatedColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              separatorBuilder: (context, index) =>
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                    color: context.colors.greyLighter,
                    height: 1.h,
                    width: double.infinity,
                  ),
              children: [
                ...menus.map((menu) {
                  var items = menu.items!.where((item) => validString(item)).toList();
                  bool hasMoreItems = false;
                  if (!seeAll) {
                    if (items.length > 2) {
                      items = items.sublist(0, 2);
                      hasMoreItems = true;
                    }
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: SeparatedColumn(
                      separatorBuilder: (context, index) => SizedBox(height: index == 0 ? 14.h : 10.h),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.title!.toUpperCase(),
                          style: TextStyle(
                            color: context.colors.primaryDark,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        for (int i = 0; i < items.length; i++)
                          Text(
                            items[i]!,
                            style: TextStyle(
                              color: context.colors.textColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (hasMoreItems)
                          Text(
                            '...',
                            style: TextStyle(
                              color: context.colors.textColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            // if (!seeAll)
            Container(
              margin: EdgeInsets.symmetric(vertical: 20.h),
              color: context.colors.greyLighter,
              height: 1.h,
              width: double.infinity,
            ),
            // if (!seeAll)
            Center(
              child: InkWell(
                onTap: () {
                  WidgetFunctions.navigateTo(context, MenuScreen(date: DateTime.now(), childId: widget.child.id));
                },
                child: Padding(
                  padding: EdgeInsets.all(8.0.h),
                  child: Text(
                    (seeAll ? LocalizationKeys.read_less : LocalizationKeys.read_more).tr(context),
                    style: TextStyle(
                      color: context.colors.textColor,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }
}
