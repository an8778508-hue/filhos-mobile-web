import 'dart:async';

abstract class NotificationsEvents {
  const NotificationsEvents();
}

class FetchNotifications extends NotificationsEvents {
  final bool silent;

  const FetchNotifications({this.silent = false});
}
class FetchMoreNotifications extends NotificationsEvents {
  final bool silent;

  const FetchMoreNotifications({this.silent = false});
}

class ReloadNotificationsEvent extends NotificationsEvents {
  final bool silent;
  final Completer? completer;

  const ReloadNotificationsEvent({
    this.silent = false,
    this.completer,
  });
}

class ViewNotification extends NotificationsEvents {
  final String id;

  const ViewNotification(this.id);
}
