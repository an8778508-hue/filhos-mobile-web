import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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
Future<void> ensureTrackingPermission() async {
  if (!Platform.isIOS) return;
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // Small delay so the system prompt isn't stacked on top of an animating
      // transition; otherwise the UIAlert can be dismissed before the user
      // even sees it.
      await Future.delayed(const Duration(milliseconds: 500));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    debugPrint('ATT request failed: $e');
  }
}
