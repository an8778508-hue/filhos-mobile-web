import 'package:escola/core/config/config.dart';
import 'package:flutter/material.dart';

// AABAR Brand Chat Colors
abstract class ChatColors {
  static const contactNameColor = Color(0xff1E3A5F);  // Navy blue
  static const messageContentColor = Color(0xff3D5A80);  // Light navy
  static const messageDateColor = Color(0xffA9B1C3);
  static const userMessageBackgroundColor = Color(0xffFFF0E5);  // Light orange
  static Color get contactMessageBackgroundColor => Config.get.styling.colors.scaffold;

  static const actionIconsColor = Color(0xff818181);
  static const backgroundTextField = Color(0xfff7f7f7);
}
