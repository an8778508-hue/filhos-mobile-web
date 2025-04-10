import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'components/medicine_history.dart';
import 'components/medicine_reminders.dart';
import 'components/medicine_requests.dart';

class MedicinesProfessorsScreen extends StatefulWidget {
  const MedicinesProfessorsScreen({super.key});

  @override
  State<MedicinesProfessorsScreen> createState() => _MedicinesProfessorsScreenState();
}

class _MedicinesProfessorsScreenState extends State<MedicinesProfessorsScreen> with TickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      initialIndex: 0,
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: LocalizationKeys.medicines.tr(context),
      ),
      backgroundColor: context.colors.scaffold,
      body: BlocProvider<MedicinesProfessorsBloc>(
        create: (BuildContext context) => di<MedicinesProfessorsBloc>(),
        child: Builder(builder: (context) {
          return Column(
            children: [
              SizedBox(height: 17.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 17.csh, horizontal: 17.csw),
                margin: EdgeInsets.symmetric(horizontal: 17.csw),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: TabBar(
                  controller: tabController,
                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                  ),
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: context.colors.secondaryTextColor,
                  unselectedLabelColor: context.colors.textColor,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: context.colors.primary,
                  ),
                  tabs: [
                    Tab(
                      text: LocalizationKeys.reminders.tr(context),
                    ),
                    Tab(
                      text: LocalizationKeys.requstes.tr(context),
                    ),
                    Tab(
                      text: LocalizationKeys.history.tr(context),
                    ),
                  ],
                  onTap: (index) {
                    //
                  },
                ),
              ),
              // Container(
              //   decoration: BoxDecoration(
              //     color: context.colors.background,
              //     borderRadius: BorderRadius.circular(10.r),
              //   ),
              //   padding: EdgeInsets.symmetric(vertical: 16.csh, horizontal: 16.csw),
              //   margin: EdgeInsets.only(right: 15.csw, left: 15.csw, top: 29.csh, bottom: 20.csh),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //     children: [
              //       TabBarWidget(
              //         title: LocalizationKeys.reminders.tr(context),
              //       ),
              //       TabBarWidget(
              //         title: LocalizationKeys.requstes.tr(context),
              //       ),
              //       TabBarWidget(
              //         title: LocalizationKeys.history.tr(context),
              //       ),
              //     ],
              //   ),
              // ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    MedicinesRemindersPage(),
                    MedicinesRequestsPage(),
                    MedicinesHistoryPage(),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class TabBarWidget extends StatelessWidget {
  final String title;

  const TabBarWidget({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.csw),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 12.csh, horizontal: 20.csw),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: context.colors.secondaryTextColor,
        ),
      ),
    );
  }
}
