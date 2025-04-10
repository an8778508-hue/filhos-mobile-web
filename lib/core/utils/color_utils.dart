import 'package:flutter/material.dart';

Color colorFromHex(String? src, [Color defaultColor = Colors.black]) {
  if (src == null) return defaultColor;

  String hex = src;

  if (hex.startsWith('#')) {
    hex = hex.replaceFirst('#', '');
  }

  switch (hex.length) {
    case 1:
      // input 'a'
      // output 'ffaaaaaa'
      final c = hex[0];
      hex = 'ff$c$c$c$c$c$c';
      break;
    case 2:
      // input 'e6'
      // output 'ffe6e6e6'
      final c1 = hex[0];
      final c2 = hex[1];
      hex = 'ff$c1$c2$c1$c2$c1$c2';
      break;
    case 3:
      // input 'e26'
      // output 'ffee2266'
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      hex = 'ff$r$r$g$g$b$b';
      break;
    case 4:
      // input '9e26'
      // output '99ee2266'
      final a = hex[0];
      final r = hex[1];
      final g = hex[2];
      final b = hex[3];
      hex = '$a$a$r$r$g$g$b$b';
      break;
    case 5:
      // input 'abe26'
      // output 'abee2266'
      final a1 = hex[0];
      final a2 = hex[1];
      final r = hex[2];
      final g = hex[3];
      final b = hex[4];
      hex = '$a1$a2$r$r$g$g$b$b';
      break;
    case 6:
      // input 'e6e6e6'
      // output 'ffe6e6e6'
      final r1 = hex[0];
      final r2 = hex[1];
      final g1 = hex[2];
      final g2 = hex[3];
      final b1 = hex[4];
      final b2 = hex[5];
      hex = 'ff$r1$r2$g1$g2$b1$b2';
      break;
    case 7:
      // input 'be6e6e6'
      // output 'bbe6e6e6'
      final a = hex[0];
      final r1 = hex[1];
      final r2 = hex[2];
      final g1 = hex[3];
      final g2 = hex[4];
      final b1 = hex[5];
      final b2 = hex[6];
      hex = '$a$a$r1$r2$g1$g2$b1$b2';
      break;
    case 8:
      // input 'abe6e6e6'
      // output 'abe6e6e6'
      final a1 = hex[0];
      final a2 = hex[1];
      final r1 = hex[2];
      final r2 = hex[3];
      final g1 = hex[4];
      final g2 = hex[5];
      final b1 = hex[6];
      final b2 = hex[7];
      hex = '$a1$a2$r1$r2$g1$g2$b1$b2';
      break;
    default:
      return defaultColor;
  }

  final code = int.tryParse(hex, radix: 16);

  if (code == null) {
    return defaultColor;
  }

  try {
    return Color(code);
  } catch (e) {
    return defaultColor;
  }
}

Color getLightColorFromColor(Color color, double val) => HSVColor.fromColor(color).withValue(1).withSaturation(val).toColor();
