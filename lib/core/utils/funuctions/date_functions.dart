import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

abstract class DateFunctions {
  //09:00 AM
  static String formatTimeTo12HourFormat(DateTime? dateTime) {
    dateTime = dateTime ?? DateTime.now();
    String format = DateFormat.jm().format(dateTime);
    if (format.split(":")[0].length == 1) {
      return "0$format";
    }
    return format;
  }

  //2020-12-31 12:59 PM
  static String formatDate(DateTime? dateTime) {
    dateTime = dateTime ?? DateTime.now();
    String format = DateFormat("yyyy-MM-dd hh:mm a").format(dateTime);
    if (format.split(":")[0].length == 1) {
      return "0$format";
    }
    return format;
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Thu 12:59 PM if not today, if today retrn 12:59 PM
  static String formatDayMonthYearHourMin(DateTime? dateTime) {
    if (dateTime != null && isSameDay(dateTime, DateTime.now())) {
      return formatTimeTo12HourFormat(dateTime);
    }
    dateTime = dateTime ?? DateTime.now();
    String format = DateFormat("EEE hh:mm a").format(dateTime);
    if (format.split(":")[0].length == 1) {
      return "0$format";
    }
    return format;
  }
  static String formatDetailedTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    debugPrint('dateTimeeeeeeeeeeeeeeeeeeeee $dateTime');
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    // Use different formats based on date (today, yesterday, other)
    if (messageDate == today) {
      return DateFormat('h:mm a').format(localDateTime);  // Today: just time
    } else {
      return DateFormat('MMM d, h:mm a').format(localDateTime);  // Other: date and time
    }
  }

}
