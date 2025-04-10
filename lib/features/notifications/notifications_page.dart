import 'dart:async';

import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/notifications_service/notification_helper.dart';
import 'package:escola/core/utils/date_formats.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/loading_type.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/notifications/bloc/notifications_bloc.dart';
import 'package:escola/features/notifications/bloc/notifications_events.dart';
import 'package:escola/features/notifications/bloc/notifications_state.dart';
import 'package:escola/features/notifications/models/notification_model.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum NotificationType { all, notRead }

class _NotificationsPageState extends State<NotificationsPage> with AutomaticKeepAliveClientMixin {
  late final ValueNotifier<NotificationType> notificationType;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    notificationType = ValueNotifier(NotificationType.all);
  }

  @override
  void dispose() {
    notificationType.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (context) => di<NotificationsBloc>()..add(const FetchNotifications()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<NotificationsBloc, NotificationsState>(
            listenWhen: (p, c) => p.notificationsListState.error != c.notificationsListState.error,
            listener: (context, state) {
              if (validString(state.notificationsListState.error)) {
                Snack.show(context, state.viewNotificationsState.error!.message, false);
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            scrollSetListener(context);

            return Scaffold(
              backgroundColor: context.colors.scaffold,
              appBar: MyAppBar(
                title: LocalizationKeys.notifications.tr(context),
                hasNotification: false,
              ),
              body: Center(
                child: ValueListenableBuilder(
                  valueListenable: notificationType,
                  builder: (context, value, child) => BlocSelector<NotificationsBloc, NotificationsState, bool>(
                    selector: (state) =>
                        state.notificationsListState.loading == LoadingType.loading ||
                        state.viewNotificationsState.loading,
                    builder: (context, loading) => loading
                        ? const Center(
                            child: Loading(),
                          )
                        : IndexedStack(
                            index: 0,
                            children: [
                              RefreshIndicator(
                                onRefresh: () async {
                                  Completer<void> completer = Completer();
                                  BlocProvider.of<NotificationsBloc>(context)
                                      .add(ReloadNotificationsEvent(completer: completer));
                                  return await completer.future;
                                },
                                child: CustomScrollView(
                                  controller: scrollController,
                                  slivers: [
                                    BlocSelector<NotificationsBloc, NotificationsState, List<NotificationModel>>(
                                      selector: (state) => state.notificationsListState.notifications,
                                      builder: (context, notifications) => NotificationsList(
                                        notifications: notifications,
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: BlocSelector<NotificationsBloc, NotificationsState, bool>(
                                        selector: (state) =>
                                            state.notificationsListState.loading == LoadingType.loadingMore,
                                        builder: (context, loading) => !loading
                                            ? const SizedBox()
                                            : Container(
                                                alignment: Alignment.center,
                                                margin: EdgeInsets.symmetric(vertical: 10.h),
                                                child: const Loading(),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  scrollSetListener(BuildContext context) {
    scrollController.addListener(() {
      double maxHeight = scrollController.position.maxScrollExtent;
      double currentScroll = scrollController.position.pixels;
      double delta = (MediaQuery.of(context).size.height) * 0.25;
      if (maxHeight - currentScroll <= delta) {
        BlocProvider.of<NotificationsBloc>(context).add(const FetchMoreNotifications());
      }
    });
  }
}

class NotificationsList extends StatelessWidget {
  const NotificationsList({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return notifications.isEmpty
        ? SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 4),
              child: const NoNotifications(),
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0) SizedBox(height: 5.h),
                  NotificationItem(
                    notification: notifications[index],
                  ),
                ],
              ),
              childCount: notifications.length,
            ),
          );
  }
}

class NoNotifications extends StatelessWidget {
  const NoNotifications({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Assets.icons.notificationBell.svg(width: 150.w, height: 150.w),
        SizedBox(height: 20.h),
        Text(
          (LocalizationKeys.no_notifications).tr(context),
          style: TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 26.sp,
            color: context.colors.textColor,
          ),
        ),
      ],
    );
  }
}

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    Key? key,
    required this.notification,
  }) : super(key: key);

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NotificationHelper.handleNotificationTap(data: notification.toJson());
        // BlocProvider.of<NotificationsBloc>(context).add(ViewNotification(notification.id));
      },
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: 19.w, top: 28.h, bottom: 28.h),
          child: Row(
            children: [
              SizedBox(width: 20.w),
              // if (validString(notification.image))
              Padding(
                padding: EdgeInsetsDirectional.only(end: 13.w),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colors.secondaryGrey,
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          color: context.colors.background,
                          child: Icon(
                            Icons.notifications,
                            size: 26.w,
                            color: context.colors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validString(notification.title))
                      Padding(
                        padding: EdgeInsets.only(bottom: 7.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            if (notification.date != null)
                              Text(
                                CustomDateFormats.formatDayMonthYear(notification.date!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 16.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (validString(notification.body))
                      Padding(
                        padding: EdgeInsets.only(bottom: 7.h),
                        child: Text(
                          notification.body,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
