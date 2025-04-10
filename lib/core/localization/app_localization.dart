import 'dart:async';

import 'package:escola/core/utils/translations_utils.dart';
import 'package:flutter/material.dart';

import 'localization_helper.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  const AppLocalizations(this._translations);

  final Map<String, String> _translations;

  String translate(String key,[String? val]) => (_translations[key] ?? key).replaceAll('{}', val??'');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate(this.lang, this.translations);

  final String lang;
  final Map<String, dynamic> translations;

  @override
  bool isSupported(Locale locale) => LocalizationsHelper.getSupportedLocales().any((e) => e.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final translations = await downloadTranslationsFile(lang);
    return AppLocalizations(translations);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => old.lang != lang || old.translations != translations;
}
