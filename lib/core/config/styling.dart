import 'package:escola/core/utils/color_utils.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';

class Styling {
  const Styling(this.json);

  final Map<String, dynamic> json;

  StylingColors get colors => StylingColors(validateMap(json['colors']));
}

class StylingColors {
  const StylingColors(this.json);

  final Map<String, dynamic> json;

  Color get primary => colorFromHex(validateString(json['primary']), DefaultColors.primary);

  Color get primaryDark => colorFromHex(validateString(json['primaryDark']), DefaultColors.primaryDark);

  Color get primaryLight => colorFromHex(validateString(json['primaryLight']), DefaultColors.primaryLight);

  Color get accent => colorFromHex(validateString(json['accent']), DefaultColors.accent);

  Color get accentLight => colorFromHex(validateString(json['accentLight']), DefaultColors.accentLight);

  Color get background => colorFromHex(validateString(json['background']), DefaultColors.background);

  Color get secondaryTextColor => colorFromHex(validateString(json['secondaryTextColor']), DefaultColors.secondaryTextColor);

  Color get textColor => colorFromHex(validateString(json['textColor']), DefaultColors.textColor);

  Color get labelColor => colorFromHex(validateString(json['labelColor']), DefaultColors.labelColor);

  Color get warmGray => colorFromHex(validateString(json['warmGray']), DefaultColors.warmGray);

  Color get disabled => colorFromHex(validateString(json['disabled']), DefaultColors.disabled);

  Color get divider => colorFromHex(validateString(json['divider']), DefaultColors.divider);

  Color get secondaryGrey => colorFromHex(validateString(json['secondaryGrey']), DefaultColors.secondaryGrey);

  Color get error => colorFromHex(validateString(json['error']), DefaultColors.error);

  Color get scaffold => colorFromHex(validateString(json['scaffold']), DefaultColors.scaffold);

  Color get secondary => colorFromHex(validateString(json['secondary']), DefaultColors.secondary);

  Color get secondaryVariant => colorFromHex(validateString(json['secondaryVariant']), DefaultColors.secondaryVariant);

  Color get success => colorFromHex(validateString(json['success']), DefaultColors.success);

  Color get successLight => colorFromHex(validateString(json['successLight']), DefaultColors.successLight);

  Color get greyLight => colorFromHex(validateString(json['greyLight']), DefaultColors.greyLight);

  Color get primaryLighter => getLightColorFromColor(primary, .1);

  Color get selectedButtonColor => colorFromHex(validateString(json['selectedButtonColor']), DefaultColors.selectedButtonColor);

  Color get greyDarker => colorFromHex(validateString(json['greyDarker']), DefaultColors.greyDarker);

  Color get greyDark => colorFromHex(validateString(json['greyDark']), DefaultColors.greyDark);

  Color get primaryBackground => colorFromHex(validateString(json['primaryBackground']), DefaultColors.primaryBackground);

  Color get secondaryScaffold => colorFromHex(validateString(json['secondaryScaffold']), DefaultColors.secondaryScaffold);

  Color get lightBackground => colorFromHex(validateString(json['lightBackground']), DefaultColors.lightBackground);

  Color get alert => colorFromHex(validateString(json['alert']), DefaultColors.alert);

  Color get primaryVeryLight => getLightColorFromColor(primary, .1);

  Color get greyLighter => colorFromHex(validateString(json['greyLighter']), DefaultColors.greyLighter);

  Color get accentDark => colorFromHex(validateString(json['accentDark']), DefaultColors.accentDark);

  Color get successLighter => colorFromHex(validateString(json['successLighter']), DefaultColors.successLighter);

  Color get inputBackground => colorFromHex(validateString(json['inputBackground']), DefaultColors.inputBackground);

  Color get errorLighter => colorFromHex(validateString(json['errorLighter']), DefaultColors.errorLighter);
}

// abstract class DefaultColors {
//   static const Color primary = Color(0xff2b5f7f);
//   static const Color primaryLight = Color(0xff6C80A0);
//   static const Color primaryBackground = Color(0xffebf6fc);
//   static const Color primaryDark = Color(0xff0d496d);
//   static const Color selectedButtonColor = Color(0xffc3dff1);
//   static const Color secondary = Color(0xff2393d2);
//   static const Color secondaryVariant = Color(0xff0048F3);
//   static const Color accent = Color(0xffffc501);
//   static const Color accentDark = Color(0xffD39401);
//   static const Color background = Color(0xffffffff);
//   static const Color lightBackground = Color(0xffe7f0f6);
//   static const Color disabled = Color(0xffdfe2e6);
//   static const Color divider = Color(0xff8f8f8f);
//   static const Color error = Color(0xffe35462);
//   static const Color errorLighter = Color(0xffFFDBDB);
//   static const Color alert = Color(0xffFF4444);
//   static const Color scaffold = Color(0xfff8f8f8);
//   static const Color secondaryScaffold = Color(0xfff5f5f5);
//   static const Color success = Color(0xff42a648);
//   static const Color successLight = Color(0xff53d468);
//   static const Color successLighter = Color(0xffE5F9D4);
//   static const Color accentLight = Color(0xfffff5d2);
//   static const Color greyLight = Color(0xffa2a6b2);
//   static const Color greyLighter = Color(0xffF2F4F6);
//   static const Color greyDarker = Color(0xff6e7482);
//   static const Color greyDark = Color(0xff828282);
//   static const Color orangeLight = Color(0xffFFFADB);
//   static const Color inputBackground = Color(0xfff9f9f9);
//   static const Color secondaryTextColor = Color(0xffffffff);
//   static const Color textColor = Color(0xff000000);
//   static const Color labelColor = Color(0xff6b6b6b);
//   static const Color warmGray = Color(0xff949494);
//   static const Color secondaryGrey = Color(0xffe8e8e8);
// }

abstract class DefaultColors {
  static const Color primary = Color(0xffff9c00);
  static const Color primaryLight = Color(0xffffe8c4);
  static const Color primaryBackground = Color(0xfffff5e5);
  static const Color primaryDark = Color(0xffff9c00);
  static const Color selectedButtonColor = Color(0xfffff5e5);
  static const Color secondary = Color(0xffff9c00);
  static const Color secondaryVariant = Color(0xffff9c00);
  static const Color accent = Color(0xffffc501);
  static const Color accentDark = Color(0xffD39401);
  static const Color background = Color(0xffffffff);
  static const Color lightBackground = Color(0xfffff5e5);
  static const Color disabled = Color(0xffdfe2e6);
  static const Color divider = Color(0xff8f8f8f);
  static const Color error = Color(0xffe35462);
  static const Color errorLighter = Color(0xffFFDBDB);
  static const Color alert = Color(0xffff9c00);
  static const Color scaffold = Color(0xfff8f8f8);
  static const Color secondaryScaffold = Color(0xfff5f5f5);
  static const Color success = Color(0xff42a648);
  static const Color successLight = Color(0xff53d468);
  static const Color successLighter = Color(0xffE5F9D4);
  static const Color accentLight = Color(0xfffff5d2);
  static const Color greyLight = Color(0xffa2a6b2);
  static const Color greyLighter = Color(0xffF2F4F6);
  static const Color greyDarker = Color(0xff6e7482);
  static const Color greyDark = Color(0xff828282);
  static const Color orangeLight = Color(0xffFFFADB);
  static const Color inputBackground = Color(0xfff9f9f9);
  static const Color secondaryTextColor = Color(0xffffffff);
  static const Color textColor = Color(0xff000000);
  static const Color labelColor = Color(0xff6b6b6b);
  static const Color warmGray = Color(0xff949494);
  static const Color secondaryGrey = Color(0xffe8e8e8);
}
