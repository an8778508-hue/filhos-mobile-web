import 'dart:convert';

import 'package:escola/core/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lang_utils.dart';
import 'valid_data.dart';

Future<Map<String, String>> downloadTranslationsFile(String code) async {
  try {
    final String selectedLang = parseLang(code);

    final Map<String, dynamic> remoteJson = Config.get.translations;
    final String localSrc = await rootBundle.loadString('assets/langs/$selectedLang.json');
    Map<String, dynamic> localJson = {};
    if (validString(localSrc)) {
      localJson = jsonDecode(localSrc);
    }

    final Map<String, String> json = {};
    for (final r in remoteJson.entries) {
      json[r.key] = r.value;
    }
    for (final l in localJson.entries) {
      if (!json.containsKey(l.key)) {
        json[l.key] = l.value;
      }
    }

    debugPrint('LANGUAGE IS $selectedLang');

    if (!validMap(json)) {
      return {};
    }
    return json;
  } catch (e) {
    debugPrint(e.toString());
    return {};
  }
}
