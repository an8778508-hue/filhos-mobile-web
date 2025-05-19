import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DiaryCalendar extends StatefulWidget {
  final DateTime? currentDate;
  final Function(DateTime)? onPressed;
  final bool nextDaysDisabled;
  final bool isLoading;
  const DiaryCalendar({super.key, this.onPressed, this.currentDate, required this.nextDaysDisabled, this.isLoading = false});

  @override
  State<DiaryCalendar> createState() => _DiaryCalendarState();
}

class _DiaryCalendarState extends State<DiaryCalendar> {
  CalendarFormat calendarFormat = CalendarFormat.week;
  late DateTime _selectedDay;

  @override
  void initState() {
    _selectedDay = widget.currentDate ?? DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              color: context.colors.background,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(top: 16.w),
                    child: TableCalendar(
                      onPageChanged: (date) {},
                      locale: UserBloc.get.state.languageWithCode,
                      calendarBuilders: CalendarBuilders(
                        headerTitleBuilder: (context, date) {
                          return Text(
                            DateFormat('yyyy LLLL',UserBloc.get.state.languageWithCode).format(date),
                            style:
                                TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary, fontSize: 18.sp),
                          );
                        },
                        markerBuilder: (context, day, focusedDay) {
                          return null;
                        },
                      ),
                      calendarFormat: calendarFormat,
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      rowHeight: 45.h,
                      focusedDay: _selectedDay,
                      headerVisible: true,
                      daysOfWeekHeight: 30.h,
                      enabledDayPredicate: (day) {
                        if (widget.nextDaysDisabled) {
                          return day.isBefore(DateTime.now()) || isSameDay(day, DateTime.now());
                        }
                        return true;
                      },
                      selectedDayPredicate: (date) {
                        return isSameDay(_selectedDay, date);
                      },
                      availableCalendarFormats: calendarFormat == CalendarFormat.week
                          ? {CalendarFormat.week: LocalizationKeys.week.tr(context)}
                          : {CalendarFormat.month: LocalizationKeys.month.tr(context)},
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      // weekendDays: const [],
                      headerStyle: HeaderStyle(
                        headerPadding: EdgeInsets.zero,
                        titleTextFormatter: (date, locale) => DateFormat.yMMM(UserBloc.get.state.languageWithCode).format(date),
                        titleCentered: false,
                        headerMargin: EdgeInsets.only(bottom: 8.w),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: context.colors.primary,
                          size: 25.w,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: context.colors.primary,
                          size: 25.w,
                        ),
                        rightChevronPadding: EdgeInsets.zero,
                        leftChevronPadding: EdgeInsets.zero,
                        leftChevronMargin: EdgeInsets.zero,
                        rightChevronVisible: false,
                        rightChevronMargin: EdgeInsets.zero,
                        titleTextStyle:
                            TextStyle(fontWeight: FontWeight.w600, color: context.colors.primary, fontSize: 18.sp),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: context.colors.primaryLight,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        tablePadding: EdgeInsets.zero,
                        isTodayHighlighted: false,
                        cellPadding: EdgeInsets.all(0.w),
                        cellMargin: EdgeInsets.all(2.w),
                        outsideTextStyle: TextStyle(
                            fontWeight: FontWeight.normal, color: context.colors.primaryLight, fontSize: 18.sp),
                        selectedTextStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18.sp),
                        disabledTextStyle:
                            TextStyle(fontWeight: FontWeight.w600, color: context.colors.greyLight, fontSize: 18.sp),
                        defaultTextStyle:
                            TextStyle(fontWeight: FontWeight.w600, color: context.colors.primaryLight, fontSize: 18.sp),
                        selectedDecoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!widget.isLoading) { // Only process selection if not loading
                          setState(() => _selectedDay = selectedDay);
                          widget.onPressed?.call(selectedDay);
                        }
                        // setState(() => _selectedDay = selectedDay);
                        // widget.onPressed?.call(selectedDay);
                      },
                    ),
                  ),
                  SizedBox(height: 35.h),
                  Container(
                    height: 15.h,
                    color: context.colors.secondaryScaffold,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x29000000), offset: Offset(0, 3), blurRadius: 6, spreadRadius: 0)
                      ],
                      color: context.colors.background),
                  child: Icon(
                    calendarFormat == CalendarFormat.week ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: context.colors.primary,
                    size: 30.w,
                  ),
                ).splash(onPressed: () {
                  if (calendarFormat == CalendarFormat.week) {
                    setState(() {
                      calendarFormat = CalendarFormat.month;
                    });
                  } else {
                    setState(() {
                      calendarFormat = CalendarFormat.week;
                    });
                  }
                }),
              ),
            )
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          DateFormat('dd MMMM yyyy',UserBloc.get.state.languageWithCode).format(_selectedDay),
          style: TextStyle(
              fontWeight: FontWeight.w600, color: context.colors.primary, letterSpacing: 1.w, fontSize: 18.sp),
        ),
      ],
    );
  }
}
