import 'package:flutter/material.dart';

enum AppType { professores, parents }

class AppFlavor extends InheritedWidget {
  final AppType appType;
  @override
  final Widget child;

  const AppFlavor({
    super.key,
    required this.appType,
    required this.child,
  }) : super(child: child);

  static AppFlavor? get(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppFlavor>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}

extension Type on BuildContext {
  bool get isProfessors => AppFlavor.get(this)?.appType == AppType.professores;

  bool get isParents => AppFlavor.get(this)?.appType == AppType.parents;
}
