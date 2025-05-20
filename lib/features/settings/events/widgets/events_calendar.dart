import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_generic_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/features/settings/events/bloc/events_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsCalendar extends StatefulWidget {
  final Function(DateTime)? onPressed;
  final DateTime? initial;
  final bool isLoading;
  const EventsCalendar({super.key, this.onPressed, this.initial, this.isLoading = false});

  @override
  State<EventsCalendar> createState() => _EventsCalendarState();
}

class _EventsCalendarState extends State<EventsCalendar> {
  CalendarFormat calendarFormat = CalendarFormat.week;
  late DateTime _selectedDay;
  @override
  void initState() {
    _selectedDay = widget.initial ??DateTime.now();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final professorEvents = context.watch<EventsBloc>().professorEvents.value;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              color: context.colors.background,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w)
                        .copyWith(top: 16.w),
                    child: TableCalendar<EventGenericModel>(
                      locale: UserBloc.get.state.languageWithCode,
                      onPageChanged: (date) {},
                      calendarBuilders: CalendarBuilders(
                        singleMarkerBuilder: (context, day, event) {
                          return Container(
                            width: 13.w,
                            height: 13.w,
                            alignment: AlignmentDirectional.topEnd,
                            margin: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: context.colors.alert,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.colors.background,width: 2),
                            ),
                          );
                        },
                        headerTitleBuilder: (context, date) {
                          return Text(
                            DateFormat('yyyy LLLL').format(date),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: context.colors.primary,
                                fontSize: 18.sp),
                          );
                        },
                      ),
                      calendarFormat: calendarFormat,
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      rowHeight: 45.h,
                      focusedDay: _selectedDay,
                      headerVisible: true,
                      daysOfWeekHeight: 30.h,
                      selectedDayPredicate: (date) {
                        return isSameDay(_selectedDay, date);
                      },
                      availableCalendarFormats:
                          calendarFormat == CalendarFormat.week
                              ? {
                                  CalendarFormat.week:
                                      LocalizationKeys.week.tr(context)
                                }
                              : {
                                  CalendarFormat.month:
                                      LocalizationKeys.month.tr(context)
                                },
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      // weekendDays: const [],
                      eventLoader: (day) {
                        final List<EventGenericModel> events = [];
                        for (var event in professorEvents) {
                          if (isSameDay(event.date!, day)) {
                            if (!events.any((element) => isSameDay(element.date, day))) {
                              events.add(event);
                            }
                          }
                        }
                        return events;
                      },
                      headerStyle: HeaderStyle(
                        titleTextFormatter: (date, locale) =>
                            DateFormat.yMMM(locale).format(date),
                        titleCentered: false,
                        headerMargin: EdgeInsets.only(bottom: 20.h),
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
                        rightChevronMargin: EdgeInsets.zero,
                        titleTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                            fontSize: 18.sp),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: context.colors.greyLight,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        markersAutoAligned: false,
                        markersAlignment: AlignmentDirectional.topEnd,
                        tablePadding: EdgeInsets.zero,
                        isTodayHighlighted: false,
                        cellPadding: EdgeInsets.all(0.w),
                        cellMargin: EdgeInsets.all(2.w),
                        outsideTextStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: context.colors.greyLight.withOpacity(0.25),
                            fontSize: 16.sp),
                        selectedTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16.sp),
                        disabledTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                            fontSize: 16.sp),
                        defaultTextStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.greyLight,
                            fontSize: 16.sp),
                        selectedDecoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        // if (selectedDay.isAfter(DateTime.now()) && !isSameDay(selectedDay, DateTime.now())) {
                        //   return;
                        // }
                        // setState(() => _selectedDay = selectedDay);
                        // widget.onPressed?.call(selectedDay);
                        if (!widget.isLoading) { // Only process selection if not loading
                          setState(() => _selectedDay = selectedDay);
                          widget.onPressed?.call(selectedDay);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 35.h),
                  Container(
                    height: 15.h,
                    color: Theme.of(context).scaffoldBackgroundColor,
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
                        BoxShadow(
                            color: Color(0x29000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                            spreadRadius: 0)
                      ],
                      color: context.colors.primaryVeryLight),
                  child: Icon(
                    calendarFormat == CalendarFormat.week
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
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
      ],
    );
  }
}
