import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashlyticsRepository {
  Future sendCrashReport(
    error,
    StackTrace stackTrace, {
    String? info,
    bool isFatal = false,
  });
}

class CrashlyticsHelper extends CrashlyticsRepository {
  @override
  Future sendCrashReport(
    error,
    StackTrace stackTrace, {
    String? info,
    bool isFatal = false,
  }) async {
    if (!kDebugMode) {
      // implement cradhlytics
      await FirebaseCrashlytics.instance
          .recordError(error, stackTrace, reason: info, fatal: isFatal);
    } else {
      log("$info $error $stackTrace");
    }
  }
}
