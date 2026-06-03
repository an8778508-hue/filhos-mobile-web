import 'package:escola/core/config/config.dart';
import 'package:escola/features/login/presentation/login_screen.dart' as legacy;
import 'package:escola/features/server_driven_auth/presentation/login_screen.dart' as sda;
import 'package:flutter/material.dart';

/// Single entry point for "show me the login screen" anywhere in the app.
///
/// Reads `Config.get.serverDrivenAuthEnabled` (Firestore `config/*`, default
/// `false`) and routes to either the new server-driven `LoginScreen` or the
/// legacy Firebase phone-SMS `LoginScreen`. **Nothing is deleted** — the
/// legacy screen stays in the codebase and is the default behavior. See
/// spec.md §Deviations item 1.
class LoginEntry {
  /// Returns the screen widget directly — use this in builder callbacks.
  static Widget widget() {
    return Config.get.serverDrivenAuthEnabled
        ? const sda.LoginScreen()
        : const legacy.LoginScreen();
  }

  /// Returns a `MaterialPageRoute` wrapping the right LoginScreen — drop-in
  /// replacement for `MaterialPageRoute(builder: (_) => const LoginScreen())`.
  static MaterialPageRoute<dynamic> route() {
    return MaterialPageRoute(builder: (_) => widget());
  }
}
