import 'dart:async';

import 'package:escola/core/config/cubit/cubit.dart';
import 'package:escola/core/notifications_service/local_notification_helper.dart';
import 'package:escola/core/notifications_service/notification_helper.dart';
import 'package:escola/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Callback invoked when FCM rotates the device token (reinstall, restore,
/// GMS update, 270-day rotation). Wired in `init_dependencies.dart` to
/// `UserBloc.updateDeviceToken`.
typedef FcmTokenRefreshHandler = void Function(String token);

class NotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  // to make sure that configuration is run only once
  static bool _notificationConfigured = false;
  static StreamSubscription<String>? _tokenRefreshSub;

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
  void configureNotifications({FcmTokenRefreshHandler? onTokenRefresh}) async {
    if (!_notificationConfigured) {
      debugPrint("_notificationConfigured .....");

      await askPermission();

      subScribeToTopic();

      _setIOSConfiguration();

      _listentToForgoundNotification();

      _setBackgroundNotitications();

      _hanldeBackgroundMessageInteractions();

      // FCM can rotate the token at any time. Without resyncing, the server
      // keeps pushing to a dead token and the user silently stops receiving
      // notifications until they reinstall.
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
        debugPrint('FCM token refreshed: $token');
        onTokenRefresh?.call(token);
      });

      _notificationConfigured = true;
    }
  }

  /// Call on logout / account-delete so the next user on this device does
  /// not inherit pushes targeted at the previous account (LGPD cross-account
  /// leak). Best-effort: failure to delete the token is non-fatal.
  static Future<void> clearToken() async {
    try {
      await messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM deleteToken failed: $e');
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

/// Runs in a separate background isolate on Android. Two requirements:
///   1. `@pragma('vm:entry-point')` so AOT release builds don't tree-shake it.
///   2. Firebase MUST be re-initialized — the main-isolate init does not carry
///      over. Without this, any Firestore/Firebase call inside the handler
///      throws and the push is silently dropped.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase background init failed: $e');
  }

  configSilentNotificationListener(message);

  debugPrint("Background Notification: ${message.data}");
}
