import 'package:flutter/material.dart';

String parseLang(String code){
  if (code.contains('_')) {
    return code.split('_').first;
  } else {
    return code;
  }
}
bool isRTL(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}