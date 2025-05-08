import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/announcements_with_date_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/home/home_screen.dart';
import 'package:escola/features/settings/Announcements/bloc/Announcements_bloc.dart';
import 'package:escola/features/settings/announcements/bloc/announcements_event.dart';
import 'package:escola/features/settings/announcements/bloc/announcements_state.dart';
import 'package:escola/features/settings/announcements/widgets/announcements_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnnouncementsBloc>(
      lazy: false,
      create: (context) => di<AnnouncementsBloc>()..add(AnnouncementsFetchDataEvent()),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            top: false,
            child: Column(children: [
              MyAppBar(
                title: LocalizationKeys.announcements.tr(context),
                // addButton: true,
                // addFunction: () async {
                //   final bloc = BlocProvider.of<AnnouncementsBloc>(context);
                //   final res = await Navigator.of(context).push(
                //       MaterialPageRoute(builder: (context) => const AddFormScreen(type: AddFormType.announcement)));
                //   if (res != null) {
                //     bloc.add(AnnouncementsFetchDataEvent());
                //   }
                // },
                filterButton: false,
              ),
              BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
                builder: (context, state) {
                  switch (state) {
                    case AnnouncementsInitial():
                      return Container();
                    case AnnouncementsLoading():
                      return const Expanded(child: Center(child: Loading()));
                    case AnnouncementsError():
                      return Center(child: Text(state.failure.toString()));
                    case AnnouncementsFetchedSuccessfully():
                      final List<AnnouncementsWithDateModel> announcements = state.announcements;
                      if (announcements.isEmpty) {
                        return const EmptyAnnouncements();
                      }
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.csw,
                          ),
                          child: RefreshIndicator(
                            onRefresh: () async {
                              BlocProvider.of<AnnouncementsBloc>(context).add(AnnouncementsFetchDataEvent());
                            },
                            child: ListView.builder(
                              padding: EdgeInsets.only(top: 0.csh, bottom: 20.h),
                              itemBuilder: (context, index) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 30.csh,
                                  ),
                                  Text(
                                    DateFormat('EE dd MMM,yyyy').format(announcements[index].date!),
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontSize: 25.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 12.csh,
                                  ),
                                  Column(
                                    children: [
                                      for (var announcement in announcements[index].announcements)
                                        Padding(
                                          padding: EdgeInsets.only(top: 18.csh),
                                          child: AnnouncementsItem(
                                            announcement: announcement,
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                              itemCount: announcements.length,
                            ),
                          ),
                        ),
                      );
                    default:
                      return Container();
                  }
                },
              )
            ]),
          ),
        );
      }),
    );
  }
}

class EmptyAnnouncements extends StatelessWidget {
  const EmptyAnnouncements({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100.h,
        ),
        EmptyWidget(
          icon: assetsPath('announcements'),
          size: 70.h,
          title: LocalizationKeys.no_announcements.tr(context),
        ),
      ],
    );
  }
}
