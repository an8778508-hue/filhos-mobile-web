import 'package:escola/core/config/styling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_theme/flutter_custom_theme.dart';

class MyTheme extends CustomThemeData {
  static MyTheme of(BuildContext context) => CustomThemes.of(context)!;

  const MyTheme({
    required this.colors,
  });

  final StylingColors colors;
}
