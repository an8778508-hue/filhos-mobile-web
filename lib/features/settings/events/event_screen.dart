import 'dart:async';

import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/sheets/filter_sheet.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/event_bus.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/home/widgets/event_item.dart';
import 'package:escola/features/settings/events/bloc/events_bloc.dart';
import 'package:escola/features/settings/events/bloc/events_event.dart';
import 'package:escola/features/settings/events/widgets/event_review_button.dart';
import 'package:escola/features/settings/events/widgets/events_calendar.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'bloc/events_state.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool eventWithImage = true;
  final ValueNotifier<FilterModel> filterModelNotifier = ValueNotifier(FilterModel());
  final ValueNotifier<DateTime> dateTime = ValueNotifier(DateTime.now());

  StreamSubscription? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EventsBloc>(
      lazy: false,
      create: (context) => di<EventsBloc>()
        ..add(FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value))
        ..add(FetchDataEvent(filterModel: filterModelNotifier.value)),
      child: Builder(builder: (context) {
        _sub = eventBus.on().listen((event) {
          if (event is EventAcceptedOrRejected || event is EventAdded) {
            BlocProvider.of<EventsBloc>(context)
              ..add(FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value))
              ..add(FetchDataEvent(filterModel: filterModelNotifier.value));
          }
        });
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            top: false,
            child: Column(children: [
              MyAppBar(
                title: LocalizationKeys.events.tr(context),
                // addButton: context.isProfessors,
                // addFunction: () {
                //   Navigator.of(context)
                //       .push(MaterialPageRoute(builder: (context) => const AddFormScreen(type: AddFormType.event)));
                // },
                filterButton: false,
                filterFunction: () async {
                  final bloc = BlocProvider.of<EventsBloc>(context);
                  final filterModelResponse = await FilterSheet.openSheet(context, filterModelNotifier.value);
                  if (filterModelResponse != null && filterModelResponse is FilterModel) {
                    filterModelNotifier.value = filterModelResponse;
                    if (eventWithImage) {
                      bloc.add(
                        FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value),
                      );
                    } else {
                      bloc.add(FetchDataEvent(filterModel: filterModelNotifier.value));
                    }
                  }
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final bloc = BlocProvider.of<EventsBloc>(context);
                    if (eventWithImage) {
                      bloc.add(
                        FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value),
                      );
                    } else {
                      bloc.add(FetchDataEvent(filterModel: filterModelNotifier.value));
                    }
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        ValueListenableBuilder(
                          valueListenable: filterModelNotifier,
                          builder: (context, filterModel, child) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (validString(filterModel.teacher?.name))
                                  FilterTag(
                                    tag: filterModel.teacher?.name ?? '',
                                    onRemove: () {
                                      filterModelNotifier.value = filterModelNotifier.value.removeTeacher();
                                      _onRemove(context);
                                    },
                                  ),
                                if (validString(filterModel.levels?.name))
                                  FilterTag(
                                    tag: filterModel.levels?.name ?? '',
                                    onRemove: () {
                                      filterModelNotifier.value = filterModelNotifier.value.removeLevel();
                                      _onRemove(context);
                                    },
                                  ),
                                if (validString(filterModel.parentOrChild?.name))
                                  FilterTag(
                                    tag: filterModel.parentOrChild?.name ?? '',
                                    onRemove: () {
                                      filterModelNotifier.value = filterModelNotifier.value.removeParent();
                                      _onRemove(context);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (eventWithImage)
                          ValueListenableBuilder(
                            valueListenable: BlocProvider.of<EventsBloc>(context).professorEvents,
                            builder: (context, value, child) => ValueListenableBuilder(
                              valueListenable: dateTime,
                              builder: (context, value, child) => EventsCalendar(
                                initial: value,
                                isLoading: context.select((EventsBloc bloc) => bloc.state is EventsLoadingState),
                                onPressed: (DateTime date) {
                                  dateTime.value = date;
                                  BlocProvider.of<EventsBloc>(context).add(
                                    FetchDayEvent(date: date, filterModel: filterModelNotifier.value),
                                  );
                                },
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(top: 30.csh, right: 18.csw, left: 18.csw, bottom: 30.h),
                          child: Row(
                            children: [
                              EventReviewButton(
                                enabled: eventWithImage,
                                icon: 'calendar',
                                onTap: () {
                                  setState(() {
                                    eventWithImage = true;
                                  });
                                  BlocProvider.of<EventsBloc>(context)
                                      .add(FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value));
                                },
                              ),
                              SizedBox(
                                width: 15.csw,
                              ),
                              EventReviewButton(
                                enabled: !eventWithImage,
                                icon: 'tab_2',
                                onTap: () {
                                  setState(() {
                                    eventWithImage = false;
                                  });
                                  BlocProvider.of<EventsBloc>(context)
                                      .add(FetchDataEvent(filterModel: filterModelNotifier.value));
                                },
                              ),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            switch (eventWithImage) {
                              case true:
                                return ValueListenableBuilder(
                                  valueListenable: BlocProvider.of<EventsBloc>(context).singleDayEventsFailure,
                                  builder: (context, failure, child) => validString(failure?.message)
                                      ? getFailureWidget(failure!)
                                      : ValueListenableBuilder(
                                          valueListenable: BlocProvider.of<EventsBloc>(context).singleDayEventsLoading,
                                          builder: (context, loading, child) => Column(
                                            children: [
                                              if (loading)
                                                Container(
                                                  margin: EdgeInsets.only(top: 30.h),
                                                  child: const Center(child: Loading()),
                                                ),
                                              if (!loading)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.csw,
                                                  ),
                                                  child: ValueListenableBuilder(
                                                    valueListenable:
                                                        BlocProvider.of<EventsBloc>(context).singleDayEvents,
                                                    builder: (context, events, child) => Column(
                                                      children: [
                                                        if (events.isNotEmpty)
                                                          ListView.builder(
                                                            shrinkWrap: true,
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            padding: EdgeInsets.only(
                                                              top: 0.csh,
                                                              bottom: 20.h,
                                                            ),
                                                            itemBuilder: (context, index) => Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                SizedBox(
                                                                  height: 12.csh,
                                                                ),
                                                                EventItem(
                                                                  eventModel: events[index],
                                                                  withImage: eventWithImage,
                                                                ),
                                                              ],
                                                            ),
                                                            itemCount: events.length,
                                                          ),
                                                        if (events.isEmpty)
                                                          Column(
                                                            children: [
                                                              SizedBox(
                                                                height: 100.h,
                                                              ),
                                                              Center(
                                                                child: EmptyWidget(
                                                                    title: LocalizationKeys.no_events.tr(context),
                                                                    icon: Assets.icons.event.path),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                );
                              case false:
                                return ValueListenableBuilder(
                                  valueListenable: BlocProvider.of<EventsBloc>(context).professorEventsFailure,
                                  builder: (context, failure, child) => validString(failure?.message)
                                      ? getFailureWidget(failure!)
                                      : ValueListenableBuilder(
                                          valueListenable: BlocProvider.of<EventsBloc>(context).professorEventsLoading,
                                          builder: (context, loading, child) => Column(
                                            children: [
                                              if (loading)
                                                Container(
                                                  margin: EdgeInsets.only(top: 30.h),
                                                  child: const Center(child: Loading()),
                                                ),
                                              if (!loading)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.csw,
                                                  ),
                                                  child: ValueListenableBuilder(
                                                    valueListenable:
                                                        BlocProvider.of<EventsBloc>(context).professorEvents,
                                                    builder: (context, events, child) => Column(
                                                      children: [
                                                        if (events.isNotEmpty)
                                                          ListView.builder(
                                                            shrinkWrap: true,
                                                            physics: const NeverScrollableScrollPhysics(),
                                                            padding: EdgeInsets.only(
                                                              top: 0.csh,
                                                              bottom: 20.h,
                                                            ),
                                                            itemBuilder: (context, index) => Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                SizedBox(
                                                                  height: 30.csh,
                                                                ),
                                                                Text(
                                                                  DateFormat('EE dd MMM,yyyy')
                                                                      .format(events[index].date!),
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
                                                                    for (var event in events[index].events)
                                                                      Padding(
                                                                        padding: EdgeInsets.only(top: 18.csh),
                                                                        child: EventItem(
                                                                          eventModel: event,
                                                                          withImage: eventWithImage,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                            itemCount: events.length,
                                                          ),
                                                        if (events.isEmpty)
                                                          Column(
                                                            children: [
                                                              SizedBox(
                                                                height: 100.h,
                                                              ),
                                                              Center(
                                                                child: EmptyWidget(
                                                                    title: LocalizationKeys.no_events.tr(context),
                                                                    icon: Assets.icons.event.path),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  getFailureWidget(Failure failure) {
    return Builder(
      builder: (context) => Row(
        children: [
          Expanded(
            child: ErrorScreen(
                errorText: failure.message,
                onRetry: () {
                  final bloc = BlocProvider.of<EventsBloc>(context);
                  if (eventWithImage) {
                    bloc.add(
                      FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value),
                    );
                  } else {
                    bloc.add(FetchDataEvent(filterModel: filterModelNotifier.value));
                  }
                }),
          ),
        ],
      ),
    );
  }

  void _onRemove(BuildContext context) {
    final bloc = BlocProvider.of<EventsBloc>(context);
    if (eventWithImage) {
      bloc.add(
        FetchDayEvent(date: dateTime.value, filterModel: filterModelNotifier.value),
      );
    } else {
      bloc.add(FetchDataEvent(filterModel: filterModelNotifier.value));
    }
  }
}

class FilterTag extends StatelessWidget {
  const FilterTag({Key? key, required this.tag, required this.onRemove}) : super(key: key);
  final String tag;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onRemove.call();
      },
      child: Chip(
        backgroundColor: context.colors.primary,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: context.colors.secondaryTextColor),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 8.w),
              child: Icon(
                Icons.close,
                color: context.colors.secondaryTextColor,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
