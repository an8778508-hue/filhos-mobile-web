import 'package:escola/core/config/config.dart';
import 'package:escola/core/utils/color_utils.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';

class LangsModel {
  const LangsModel(this.json);

  final Map<String, dynamic> json;

  String get codeWithLocale => validateString(json['code']);

  String get code {
    final String code = json['code'];
    if (code.contains('_')) {
      final languageCode = code.split('_')[0]; // Output: "en"
      return languageCode;
    }

    return validateString(json['code']);
  }

  String get title => validateString(json['name']);

  Color get color => colorFromHex(validateString(json['color']), Config.get.styling.colors.primaryLight);

  Color get textColor => colorFromHex(validateString(json['textColor']), Config.get.styling.colors.secondaryTextColor);

  String get image => validateString(json['image']);
}
