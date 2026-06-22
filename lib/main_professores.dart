import 'dart:io';

import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/init_dependencies.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// DEBUG ONLY: Bypasses expired/self-signed SSL certificates.
class _DebugHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  // dart:io HttpOverrides don't exist on web (dio uses the browser adapter
  // there), so only install the debug SSL bypass on native debug builds.
  // Parity with main.dart — without the !kIsWeb guard the professores web
  // build touches dart:io on startup.
  if (kDebugMode && !kIsWeb) {
    HttpOverrides.global = _DebugHttpOverrides();
  }
  AppFlavor.setCurrent(AppType.professores);
  await initDependencies();
  runApp(AppFlavor(appType: AppType.professores, child: const MyApp()));
}
