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
  if (kDebugMode) {
    HttpOverrides.global = _DebugHttpOverrides();
  }
  AppFlavor.setCurrent(AppType.professores);
  await initDependencies();
  runApp(AppFlavor(appType: AppType.professores, child: const MyApp()));
}
