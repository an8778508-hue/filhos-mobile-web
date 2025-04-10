import 'package:escola/core/config/styling.dart';
import 'package:escola/core/theme/custom_theme.dart';
import 'package:flutter/material.dart';

extension GetColor on BuildContext {
  StylingColors get colors => MyTheme.of(this).colors;
}
