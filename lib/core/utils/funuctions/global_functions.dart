import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';

String assetsPath(String iconName) => 'assets/icons/$iconName.svg';

String assetsImagePath(String iconName) => 'assets/images/$iconName.png';

bool isBrazilCountry(String? code) => code == AppConstants.brazilCountryCode;

Size getTextSize(BuildContext context, String text, TextStyle style, BoxConstraints constraints) {
  final span = TextSpan(
    text: text,
    style: style,
  );
  final tp = TextPainter(
    text: span,
    textDirection: Directionality.of(context),
  );
  tp.layout(maxWidth: constraints.maxWidth);
  return tp.size;
}

String? removeHtml(String data) {
  data = data.replaceAll("</p><p>", " ");
  final document = parse(data);
  final parsedString = parse(document.body?.text).documentElement?.text;
  return parsedString;
}

enum Elevation {
  k0,
  k1,
  k2,
  k3,
  k4,
  k6,
  k8,
  k9,
  k12,
  k16,
  k24,
}

List<BoxShadow>? getElevation(Elevation elevation, [Color? color]) =>
    kElevationToShadow[int.tryParse(elevation.name.replaceFirst('k', '')) ?? 0]
        ?.map((e) => BoxShadow(
              spreadRadius: e.spreadRadius,
              offset: e.offset.translate(0, -5),
              blurStyle: e.blurStyle,
              blurRadius: e.blurRadius,
              color: color ?? Colors.black.withOpacity(0.075),
            ))
        .toList();

String simplifyNumber(BuildContext context, int numberInt) {
  const million = 1000000;
  const thousand = 1000;
  if (numberInt > million) {
    final number = numberInt / million;
    String numberString = '$number';
    if(number % 100 == 0){
      numberString = number.toStringAsFixed(2);
    }
    if(number % 10 == 0){
      numberString = number.toStringAsFixed(1);
    }
    return '$numberString ${LocalizationKeys.million.tr(context)}';
  }
  if (numberInt > thousand) {
    final number = numberInt / thousand;
    String numberString = '$number';
    if(number % 100 == 0){
      numberString = number.toStringAsFixed(2);
    }
    if(number % 10 == 0){
      numberString = number.toStringAsFixed(1);
    }
    return '$numberString ${LocalizationKeys.thousand.tr(context)}';
  }

  return '$numberInt';
}

bool isSameDay({required DateTime time1, required DateTime time2}) {
  return time1.year == time2.year && time1.month == time2.month && time1.day == time2.day;
}