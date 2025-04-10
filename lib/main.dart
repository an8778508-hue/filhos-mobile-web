import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/init_dependencies.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';

void main() async {
  await initDependecies();
  runApp(const AppFlavor(appType: AppType.parents, child: MyApp()));
}
