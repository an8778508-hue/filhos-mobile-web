import 'package:flutter/material.dart';

String parseLang(String code){
  if (code.contains('_')) {
    return code.split('_').first;
  } else {
    return code;
  }
}

/// Resolves the initial app language from the device/platform locale.
///
/// When the device locale is Arabic (languageCode == 'ar'), the app defaults to
/// Arabic ('ar' / 'ar_EG'). For every other device locale the app keeps the
/// historical Portuguese default ('pt' / 'pt_BR'). Returns a record of
/// (language, languageWithCode).
({String language, String languageWithCode}) resolveInitialLanguage(String deviceLocale) {
  if (parseLang(deviceLocale).toLowerCase() == 'ar') {
    return (language: 'ar', languageWithCode: 'ar_EG');
  }
  return (language: 'pt', languageWithCode: 'pt_BR');
}
bool isRTL(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}