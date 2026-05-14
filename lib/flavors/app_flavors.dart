import 'package:flutter/material.dart';

enum AppType { professores, parents }

class AppFlavor extends InheritedWidget {
  final AppType appType;
  @override
  final Widget child;

  /// Process-wide flavor singleton, set from the `main.dart` /
  /// `main_professores.dart` entry points BEFORE `runApp`. Available to code
  /// running outside the widget tree (background isolates, interceptors, the
  /// login flow before `UserBloc` has a user). Reading the flavor from
  /// `mainKey.currentContext` is fragile because the context can be null
  /// during early boot or in background isolates.
  static AppType? _current;
  static AppType get current => _current ?? AppType.parents;
  static void setCurrent(AppType type) => _current = type;

  AppFlavor({
    super.key,
    required this.appType,
    required this.child,
  }) : super(child: child) {
    _current = appType;
  }

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

/// Convenience for non-widget code. Prefer `UserBloc.get.state.user?.type`
/// for routing decisions made AFTER login (so a parent flavor build with a
/// teacher account, if that's ever possible, behaves correctly). Use these
/// flavor helpers only when there is no logged-in user yet (e.g. login).
bool get isProfessorsFlavor => AppFlavor.current == AppType.professores;
bool get isParentsFlavor => AppFlavor.current == AppType.parents;
