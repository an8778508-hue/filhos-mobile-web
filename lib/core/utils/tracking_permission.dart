import 'dart:io';

import 'package:flutter/foundation.dart';

/// App Tracking Transparency. Apple Guideline 5.1.2:
/// - The user must understand WHY the app would track them before the
///   system prompt fires; calling this on the language picker (first cold
///   start) is a known rejection vector.
/// - Apps that never re-prompt returning users (who already passed the
///   language picker) will sit at `notDetermined` forever and be
///   non-compliant if they ever wire an IDFA-using SDK.
///
/// This helper:
///   - No-ops on non-iOS.
///   - Only prompts when status is `notDetermined`, so it is safe to call
///     repeatedly on every cold start.
///   - Is invoked from `MainScreen.initState` (post-login, post-approval),
///     where the user has already seen the privacy policy / terms.
///
/// NOTE: The `app_tracking_transparency` package is currently commented out
/// in `pubspec.yaml`. This helper is a no-op until that dependency is
/// restored. Restore by:
///   1. Uncommenting `app_tracking_transparency: ^2.0.6+1` in pubspec.yaml
///   2. Running `flutter pub get`
///   3. Re-adding the original implementation (see git history)
/// Today the app does not ship any IDFA-using SDK, so compliance is not at
/// risk — but the moment one is added (e.g., a third-party analytics SDK
/// that reads the IDFA), this must be restored.
Future<void> ensureTrackingPermission() async {
  if (!Platform.isIOS) return;
  if (kDebugMode) {
    debugPrint('ATT helper is a no-op (app_tracking_transparency commented out in pubspec)');
  }
}
