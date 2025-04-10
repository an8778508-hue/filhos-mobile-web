import 'package:escola/core/config/config.dart';
import 'package:escola/core/localization/app_localization.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class LocalizationsHelper {
  static Iterable<Locale> getSupportedLocales() =>
      Config.get.langs.where((e) => validString(e.code)).map((e) {
        if(e.code.contains('_')){
          final languageCode = e.code.split('_')[0]; // Output: "en"
          return Locale(languageCode);
        }
        return Locale(e.code);
      });

  static List<LocalizationsDelegate<dynamic>> getTranslationDelegates(String lang, Map<String, dynamic> translations) => [
        AppLocalizationsDelegate(lang, translations),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static Locale? localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale?.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }

// static Locale? localeListResolutionCallback(List<Locale>? locales, Iterable<Locale> supportedLocales) {
//   for (var supportedLocale in supportedLocales) {
//     if (supportedLocale.languageCode == locale?.languageCode) {
//       return supportedLocale;
//     }
//   }
//   return supportedLocales.first;
// }
}
