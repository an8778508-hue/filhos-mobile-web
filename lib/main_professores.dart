import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/init_dependencies.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';

void main() async {
  await initDependencies();
  runApp(const AppFlavor(appType: AppType.professores, child: MyApp()));
}
