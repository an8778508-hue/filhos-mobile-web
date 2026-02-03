import 'dart:convert';

import 'package:flutter/foundation.dart';

String getPrettyJSONString(jsonObject) {
  var encoder = const JsonEncoder.withIndent("\t\t");
  return encoder.convert(jsonObject);
}

T printR<T>(String tag, T object) {
  if (kDebugMode) {
    print('$tag $object');
  }
  return object;
}
