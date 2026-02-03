import 'package:escola/core/config/config.dart';
import 'package:flutter/material.dart';

abstract class MainTheme {
  static ThemeData get lightTheme {
    var theme = ThemeData(
      useMaterial3: false,
      fontFamily: 'Gabarito',
      scaffoldBackgroundColor: Config.get.styling.colors.scaffold,
      primaryColor: Config.get.styling.colors.primary,
      // textTheme: GoogleFonts.openSansTextTheme(),
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: Config.get.styling.colors.primary,
        onPrimary: Config.get.styling.colors.secondaryTextColor,
        secondary: Config.get.styling.colors.secondary,
        onSecondary: Config.get.styling.colors.secondaryTextColor,
        error: Config.get.styling.colors.error,
        onError: Config.get.styling.colors.secondaryTextColor,
        surface: Config.get.styling.colors.background,
        onSurface: Config.get.styling.colors.textColor,
      ),
      appBarTheme: AppBarTheme(
        color: Config.get.styling.colors.primary,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
    );
    return theme;
  }
}
