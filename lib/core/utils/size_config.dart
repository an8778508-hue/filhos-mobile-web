import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SizeConfig {
  static double? screenWidth;
  static double? screenHeight;

  static initSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }
}

double getRelativeHeight(double percentage) {
  return percentage * (SizeConfig.screenHeight ?? 0);
}

double getRelativeWidth(double percentage) {
  return percentage * (SizeConfig.screenWidth ?? 0);
}

double getHeightByNumber(double height) {
  return height.h;
  // return getRelativeHeight(height / (SizeConfig.screenHeight!.toDouble()));
}

double getWidthByNumber(double width) {
  return width.w;
  // return getRelativeWidth(width / (SizeConfig.screenWidth!.toDouble()));
}
