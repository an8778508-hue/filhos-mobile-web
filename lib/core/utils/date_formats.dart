import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateFormats {
  static String formatDayMonthYearHourMin(DateTime date) => DateFormat('dd-MM-yyyy hh:mm a').format(date);

  static String formatDayMonthYear(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  static String formatDayMonthYear2(DateTime date) => DateFormat('EEEE dd MMMM yyyy').format(date);

  static String formatHourMin(BuildContext context, TimeOfDay time) => time.format(context);
}
