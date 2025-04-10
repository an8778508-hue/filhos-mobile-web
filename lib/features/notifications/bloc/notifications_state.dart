import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/utils/loading_type.dart';
import 'package:escola/features/notifications/models/notification_model.dart';

class NotificationsState {
  final NotificationsListState notificationsListState;
  final ViewNotificationState viewNotificationsState;

  const NotificationsState({
    this.notificationsListState = const NotificationsListState(),
    this.viewNotificationsState = const ViewNotificationState(),
  });

  NotificationsState copyWith({
    NotificationsListState? notificationsListState,
    ViewNotificationState? viewNotificationsState,
  }) =>
      NotificationsState(
        notificationsListState:
            notificationsListState ?? this.notificationsListState,
        viewNotificationsState:
            viewNotificationsState ?? this.viewNotificationsState,
      );

  NotificationsState setNotificationsListState(
          NotificationsListState Function(NotificationsListState s) setter) =>
      copyWith(
        notificationsListState: setter(notificationsListState),
      );

  NotificationsState setViewNotificationState(
          ViewNotificationState Function(ViewNotificationState s) setter) =>
      copyWith(
        viewNotificationsState: setter(viewNotificationsState),
      );
}

class NotificationsListState {
  final List<NotificationModel> notifications;
  final LoadingType? loading;
  final Failure? error;

  const NotificationsListState({
    this.notifications = const [],
    this.loading,
    this.error,
  });

  NotificationsListState get fetching => const NotificationsListState(
        loading: LoadingType.loading,
      );

  NotificationsListState get reloading => NotificationsListState(
        loading: LoadingType.reloading,
        notifications: notifications,
      );
  NotificationsListState get loadingMore => NotificationsListState(
        loading: LoadingType.loadingMore,
        notifications: notifications,
      );

  // NotificationsListState view(String id) => NotificationsListState(
  //       notifications: [...notifications.map((e) => e.id == id ? e.copyWith(viewed: true) : e)],
  //     );

  NotificationsListState success(List<NotificationModel> notifications) =>
      NotificationsListState(
        notifications: notifications,
      );
  NotificationsListState successMore(List<NotificationModel> notifications) =>
      NotificationsListState(
        notifications: [...this.notifications, ...notifications],
      );

  NotificationsListState failed(Failure error) => NotificationsListState(
        notifications: notifications,
        error: error,
      );
}

class ViewNotificationState {
  final String? id;
  final bool success;
  final bool loading;
  final Failure? error;

  const ViewNotificationState({
    this.id,
    this.success = false,
    this.loading = false,
    this.error,
  });

  ViewNotificationState viewing(String id) => ViewNotificationState(
        id: id,
        loading: true,
      );

  ViewNotificationState viewed(String id) => ViewNotificationState(
        id: id,
        success: true,
      );

  ViewNotificationState failed(String id, Failure error) =>
      ViewNotificationState(
        id: id,
        error: error,
      );
}
