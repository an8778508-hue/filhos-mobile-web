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
    // The bundled per-language file (assets/langs/<lang>.json) wins. It is
    // correct for the *selected* language, whereas the remote `translations`
    // map is a single, language-agnostic map — applying it first forced e.g.
    // English strings ("Password", "Skip", "Keep me logged in") onto an Arabic
    // UI, producing the mixed-language bug. Remote now only fills keys the
    // bundled file doesn't define (so it can still add/override unknown keys).
    for (final l in localJson.entries) {
      json[l.key] = '${l.value}';
    }
    for (final r in remoteJson.entries) {
      if (!json.containsKey(r.key)) {
        json[r.key] = '${r.value}';
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
