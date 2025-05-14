import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/child_header.dart';
import 'package:escola/features/diary/presentation/widgets/diary_calendar.dart';
import 'package:escola/features/diary/presentation/widgets/diary_state_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

class ParentDiaryScreen extends StatelessWidget {
  final ChildModel? child;

  const ParentDiaryScreen({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondaryScaffold,
      body: BlocProvider<DiaryBloc>(
        create: (context) => di<DiaryBloc>()..add(GetDiaryActivities(childId: child?.id, date: getCurrentDate())),
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                MyAppBar(
                  title: LocalizationKeys.diary.tr(context),
                  hasNotification: true,
                ),
                if (child != null) ...[
                  Container(color: Colors.white, child: ChildHeader(child: child!)),
                ],
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<DiaryBloc>().add(GetDiaryActivities(childId: child?.id, date: getCurrentDate()));
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          DiaryCalendar(
                            nextDaysDisabled: true,
                            isLoading: context.select((DiaryBloc bloc) => bloc.state is DiaryActivitiesLoading),
                            onPressed: (selectedDay) {
                              if (selectedDay.isAfter(DateTime.now()) && !isSameDay(selectedDay, DateTime.now())) {
                                return;
                              }
                              context.read<DiaryBloc>().add(GetDiaryActivities(date: selectedDay, childId: child?.id));
                            },
                          ),
                          DiaryStateHandler(hasChild: child != null),
                          SizedBox(height: 15.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  DateTime getCurrentDate() {
    return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }
}
