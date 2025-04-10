import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_menu_item.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/diary_calendar.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MenuScreen extends StatefulWidget {
  final DateTime date;
  final int? childId;

  const MenuScreen({super.key, required this.date, required this.childId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Menu>? _menus;
  DateTime? _selectedDate;
  @override
  void initState() {
    _selectedDate = widget.date;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiaryBloc>(
      create: (context) => di<DiaryBloc>()..add(GetMenus(date: widget.date, childId: widget.childId)),
      child: Builder(builder: (context) {
        return BlocConsumer<DiaryBloc, DiaryState>(
          listener: (context, state) {
            if (state is MenusLoaded) {
              _menus = state.menus.safeFirstWhere((element) =>  (element.childModel.id.toString() == widget.childId.toString()) &&(validString(element.childModel.id.toString()) && validString(widget.childId.toString())))?.menus;
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: context.colors.secondaryScaffold,
              appBar: MyAppBar(
                title: LocalizationKeys.menu.tr(context),
                hasNotification: true,
              ),
              body: RefreshIndicator(
                onRefresh: () async => getMenu(context),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DiaryCalendar(
                        nextDaysDisabled: false,
                        currentDate: _selectedDate,
                        onPressed: (date) {
                          setState(() => _selectedDate = date);
                          context.read<DiaryBloc>().add(GetMenus(date: date, childId: widget.childId));
                        },
                      ),
                      if (state is MenusLoading) ...[
                        Container(margin: EdgeInsets.only(top: 100.h), child: const Center(child: Loading()))
                      ] else if (state is MenusError) ...[
                        Container(
                            margin: EdgeInsets.only(top: 100.h),
                            child: ErrorScreen(errorText: state.failure.message, onRetry: () => getMenu(context)))
                      ] else if (_menus != null) ...[
                        if (_menus!.isEmpty) ...[
                          Container(
                            margin: EdgeInsets.only(top: 100.h),
                            child: Center(
                              child: EmptyWidget(
                                title: LocalizationKeys.no_menu.tr(context),
                                icon: Assets.icons.menuIcon.path,
                              ),
                            ),
                          )
                        ] else ...[
                          Column(children: [
                            ...List.generate(
                              _menus!.length,
                              (index) {
                                final menu = _menus![index];
                                if (true) {
                                  return Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.w).copyWith(bottom: 10.h),
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.w),
                                    decoration:
                                        BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                        menu.title ?? "",
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w300,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                      SizedBox(height: 15.h),
                                      Container(color: context.colors.secondaryScaffold, height: 1.h),
                                      SizedBox(height: 15.h),
                                      if (validList(menu.items)) ...[
                                        ...List.generate(menu.items!.length, (index) {
                                          final item = menu.items![index];
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 10.h),
                                            child: Text(
                                              item ?? "",
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        })
                                      ] else ...[
                                        Container(
                                          margin: EdgeInsets.only(bottom: 10.h),
                                          child: Text(
                                            LocalizationKeys.no_menu.tr(context),
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ]
                                    ]),
                                  );
                                }
                              },
                            ),
                          ])
                        ]
                      ]
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void getMenu(BuildContext myContext) {
    if (_selectedDate == null) return;
    myContext.read<DiaryBloc>().add(GetMenus(date: _selectedDate!, childId: widget.childId));
  }
}
