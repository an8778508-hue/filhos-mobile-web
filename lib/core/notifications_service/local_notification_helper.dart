import 'dart:convert';
import 'dart:io';

import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/notifications_service/notification_helper.dart';
import 'package:escola/core/utils/lang_utils.dart';
import 'package:escola/my_app.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flash/flash.dart';
import 'package:flash/flash_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:escola/flavors/app_flavors.dart';

import '../user/bloc/user_bloc.dart';

class LocalNotificationHelper {
  /// display local notification
  static showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;

      AndroidNotification? android = message.notification?.android;

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      String? imageUrl = getImageUrl(message);

      final picturePath = await downloadAndSavePicture(imageUrl, 'picture');

      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initializationSettingsIOS = DarwinInitializationSettings();

      const initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

      flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleForgroundMessageInteraction(details.payload);
        },
      );

      final DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        attachments: picturePath == null ? null : [DarwinNotificationAttachment(picturePath)],
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        icon: android?.smallIcon,
        importance: channel.importance,
        priority: Priority.high,
        styleInformation:
            _buildBigPictureStyleInformation(notification?.title ?? "", notification?.body ?? "", picturePath, true),
      );

      // Default to Arabic
      bool isEnglish = false;
      String? title= notification?.title;
      String? body= notification?.body;
      final data = message.data;

// Get language preference from UserBloc
      final userLanguage = UserBloc.get.state.language;
      isEnglish = userLanguage == 'en';

      debugPrint("Language from UserBloc: $userLanguage, isEnglish: $isEnglish");

// Use localized data if available, fallback to notification
      title = isEnglish ? data['title_en'] ?? notification?.title : data['title_ar'] ?? notification?.title;
      body = isEnglish ? data['body_en'] ?? notification?.body : data['body_ar'] ?? notification?.body;
      // final context = navigatorKey.currentContext;
     // if(context != null){
     //   bool isEnglish = (isRTL(context)==false);
     //
     //
     //   debugPrint("isEnglissssssssssssssssh : $isEnglish");
     //   final data = message.data;
     //    title = isEnglish ? data['title_en'] : data['title_ar'];
     //   body = isEnglish ? data['body_en'] : data['body_ar'];
     //
     // }
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          title,
         body,
          NotificationDetails(android: androidDetails, iOS: iOSPlatformChannelSpecifics),
          payload: json.encode(message.data),
        );
      }
    } catch (e) {
      debugPrint("error : $e");
    }
  }

  static String? getImageUrl(RemoteMessage message) {
    if (Platform.isIOS && message.notification?.apple != null) {
      return message.notification?.apple?.imageUrl ?? message.data['imageUrl'];
    }
    if (Platform.isAndroid && message.notification?.android != null) {
      return message.notification?.android?.imageUrl ?? message.data['imageUrl'];
    }
    return null;
  }

  static BigPictureStyleInformation? _buildBigPictureStyleInformation(
    String title,
    String body,
    String? picturePath,
    bool showBigPicture,
  ) {
    if (picturePath == null) return null;
    final FilePathAndroidBitmap filePath = FilePathAndroidBitmap(picturePath);
    return BigPictureStyleInformation(
      showBigPicture ? filePath : const FilePathAndroidBitmap("empty"),
      largeIcon: filePath,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
  }

  static void _handleForgroundMessageInteraction(String? payload) {
    debugPrint("forground notification pressed");
    if (payload != null) {
      final data = json.decode(payload);
      if (data != null && data is Map<String, dynamic>) {
        NotificationHelper.handleNotificationTap(data: data);
      }
    }
  }

  static Future<String?> downloadAndSavePicture(String? url, String fileName) async {
    if (url == null) return null;
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static showFlashWhenNotificationAppear(String title, String body) async {
    final String appIcon = navigatorKey.currentContext!.isParents
        ? Assets.appIcon.appIconParents.path
        : Assets.appIcon.appIconProfessors2A.path;

    navigatorKey.currentContext!.showFlash<bool>(
      barrierDismissible: true,
      duration: const Duration(seconds: 3),
      builder: (context, controller) => FlashBar(
        controller: controller,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        forwardAnimationCurve: Curves.easeInCirc,
        reverseAnimationCurve: Curves.bounceIn,
        position: FlashPosition.top,
        shouldIconPulse: false,
        backgroundColor: Colors.white,
        behavior: FlashBehavior.floating,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        margin: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        icon: CommonImage(
          imageUrl: appIcon,
          size: 30.w,
        ),
        title: Text(title, style: TextStyle(fontSize: 17.w)),
        content: Text(body, style: TextStyle(fontSize: 14.w)),
      ),
    );
  }
}
