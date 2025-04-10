import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String getDayByNumber(int day) {
  switch (day) {
    case 1:
      return 'الاثنين';
    case 2:
      return 'الثلاثاء';
    case 3:
      return 'الاربعاء';
    case 4:
      return 'الخميس';
    case 5:
      return 'الجمعة';
    case 6:
      return 'السبت';
    case 7:
      return 'الاحد';
  }
  return '';
}

DateTime? parseDateTime(String? src) {
  try {
    if (!validString(src)) {
      throw '$src';
    }
    src!;
    final srcInt = int.tryParse(src);
    if (srcInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(srcInt);
    }
    return DateTime.tryParse(src);
  } catch (e) {
    return null;
  }
}

// this is the format to be sent to API
String? formatDateTime(DateTime? src, {bool dateOnly = false, bool timeOnly = false}) {
  try {
    if (src == null) {
      throw '$src';
    }
    const date = 'yyyy-MM-dd';
    const time = 'hh:mm:ss';
    return DateFormat(dateOnly
            ? date
            : timeOnly
                ? time
                : '$date $time')
        .format(src);
  } catch (e) {
    return null;
  }
}

TimeOfDay? parseTime(String? src) {
  try {
    if (!validString(src)) {
      throw '$src';
    }
    src!;
    final dateTime = parseDateTime(src);
    if (dateTime == null) {
      throw '$dateTime';
    }
    final time = TimeOfDay.fromDateTime(dateTime);
    return time;
  } catch (e) {
    return null;
  }
}

// this is the format to be sent to API
String? formatTime(TimeOfDay? src) {
  try {
    if (src == null) {
      throw '$src';
    }
    return formatDateTime(DateTime(0, 0, 0, src.hour, src.minute), timeOnly: true);
  } catch (e) {
    return null;
  }
}
