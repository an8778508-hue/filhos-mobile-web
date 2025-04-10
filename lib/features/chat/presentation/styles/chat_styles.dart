import 'package:escola/core/config/config.dart';
import 'package:flutter/material.dart';

abstract class ChatColors {
  static const contactNameColor = Color(0xff283b6a);
  static const messageContentColor = Color(0xff687697);
  static const messageDateColor = Color(0xffA9B1C3);
  static const userMessageBackgroundColor = Color(0xfffcdd13);
  static Color get contactMessageBackgroundColor => Config.get.styling.colors.scaffold;

  static const actionIconsColor = Color(0xff818181);
  static const backgroundTextField = Color(0xfff7f7f7);
}
