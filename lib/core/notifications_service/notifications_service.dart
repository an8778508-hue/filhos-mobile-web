import 'package:escola/core/config/cubit/cubit.dart';
import 'package:escola/core/notifications_service/local_notification_helper.dart';
import 'package:escola/core/notifications_service/notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  // to make sure that configuration is run only once
  static bool _notificationConfigured = false;

  NotificationService();

  Future<NotificationSettings> askPermission() async {
    Permission.notification.request();
    return await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// setup notification service to recieve notifcations
  void configureNotifications() async {
    if (!_notificationConfigured) {
      debugPrint("_notificationConfigured .....");

      await askPermission();

      subScribeToTopic();

      _setIOSConfiguration();

      _listentToForgoundNotification();

      _setBackgroundNotitications();

      _hanldeBackgroundMessageInteractions();

      _notificationConfigured = true;
    }
  }

  void subScribeToTopic() async {}

  void _setIOSConfiguration() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setBackgroundNotitications() {
    FirebaseMessaging.onBackgroundMessage(
      notificationBackgroundHandler,
    );
  }

  void _listentToForgoundNotification() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        configSilentNotificationListener(message);

        debugPrint("Foregeound Notification : ");

        debugPrint("message : ${message.toMap()}");

        debugPrint("Title : ${message.notification?.title}");

        debugPrint("Body : ${message.notification?.body}");

        debugPrint("data :${message.data}");

        LocalNotificationHelper.showLocalNotification(message);
      },
    );
  }

  /// hndle message interactions (termintated -background)
  Future<void> _hanldeBackgroundMessageInteractions() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleBankgroundPressed(initialMessage);
    }

    // handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBankgroundPressed);
  }

  void _handleBankgroundPressed(RemoteMessage message) {
    final data = message.data;
    debugPrint("background notification Pressed : $data");
    NotificationHelper.handleNotificationTap(data: data);
  }

  /// get device token from Firebase
  static Future<String?> getToken() async {
    try {
      String? deviceToken = await messaging.getToken();
      debugPrint("deviceToken : $deviceToken");
      return deviceToken;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      return null;
    }
  }
}
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  configSilentNotificationListener(message);

  debugPrint("Background Notification : ");

  debugPrint("Message :  ${message.toMap()}");

  debugPrint("Title : ${message.notification?.title}");

  debugPrint("Body : ${message.notification?.body}");

  debugPrint("Body : ${message.notification?.body}");

  debugPrint("Android :  ${message.notification?.android?.toMap()}");

  debugPrint("click action : ${message.notification?.android?.clickAction}");

  debugPrint("image url ios : ${message.notification?.apple?.imageUrl}");

  debugPrint("image url Android : ${message.notification?.android?.imageUrl}");

  debugPrint("data :${message.data}");
}
