import 'package:flutter/services.dart';

class NativeIOSAlarm {
  static const MethodChannel _channel =
      MethodChannel('com.example.alarm/method_channel');

  static Future<void> cancelAlarm(String id) async {
    await _channel.invokeMethod('cancelAlarm', {'id': id});
  }

  static Future<void> setAlarm(
      String id, DateTime dateTime, String title, String body) async {
    Duration timeZoneOffset = dateTime.timeZoneOffset;

    String timeZoneOffsetStr = timeZoneOffset.isNegative
        ? "-${timeZoneOffset.abs().inHours.toString().padLeft(2, '0')}:${(timeZoneOffset.abs().inMinutes % 60).toString().padLeft(2, '0')}"
        : "+${timeZoneOffset.inHours.toString().padLeft(2, '0')}:${(timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0')}";
    String dateStr = "${dateTime.toIso8601String()}$timeZoneOffsetStr";
    await _channel.invokeMethod(
        'setAlarm', {'id': id, 'date': dateStr, 'title': title, 'body': body});
  }
}
