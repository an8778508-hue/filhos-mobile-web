import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies the Egyptian-Arabic translation bundle (`assets/langs/ar.json`) is
/// complete: every value is a non-empty String that contains at least one
/// Arabic-script character (U+0600..U+06FF), and that ar.json is at least as
/// complete as en.json (no English key is missing an Arabic translation).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Matches any character in the Arabic Unicode block (U+0600..U+06FF).
  final arabicScript = RegExp('[؀-ۿ]');

  Map<String, dynamic> loadJson(String relativePath) {
    final file = File(relativePath);
    expect(file.existsSync(), isTrue, reason: '$relativePath must exist');
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('every ar.json value is a non-empty Arabic string', () {
    final ar = loadJson('assets/langs/ar.json');

    expect(ar, isNotEmpty);

    ar.forEach((key, value) {
      expect(value, isA<String>(), reason: 'Value for "$key" must be a String');
      final str = value as String;
      expect(str.trim(), isNotEmpty,
          reason: 'Value for "$key" must be a non-empty string');
      expect(arabicScript.hasMatch(str), isTrue,
          reason: 'Value for "$key" must contain Arabic script: "$str"');
    });
  });

  test('ar.json contains an Arabic translation for every en.json key', () {
    final ar = loadJson('assets/langs/ar.json');
    final en = loadJson('assets/langs/en.json');

    final missing = en.keys.where((k) => !ar.containsKey(k)).toList();
    expect(missing, isEmpty,
        reason: 'ar.json is missing keys present in en.json: $missing');
  });
}
