import 'package:flutter/material.dart';

abstract class WidgetFunctions {
  ///  navigatre to pages
  static Future<T> navigateTo<T>(BuildContext context, Widget widget) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: widget.runtimeType.toString()),
        builder: (context) => widget,
      ),
    );
  }
}
