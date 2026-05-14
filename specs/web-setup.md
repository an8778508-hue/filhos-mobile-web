---
name: web-setup
description: What the codebase already supports for web, what's stubbed, and the external work still required for a genuinely functional web build.
status: reference
---

# Web Setup

`flutter build web` and `flutter run -d chrome` now **compile and produce a runnable bundle** for both flavors. This document captures what works, what's stubbed, and the external (non-codebase) work required to make web fully functional.

## What works today

- ✅ `flutter build web --no-tree-shake-icons -t lib/main.dart` → produces a parents build
- ✅ `flutter build web --no-tree-shake-icons -t lib/main_professores.dart --output build/web_professores` → produces a teachers build
- ✅ Six new VS Code launch entries: parents/professores × {debug, profile, release} native, plus parents/professores web (Chrome). See [.vscode/launch.json](../.vscode/launch.json).
- ✅ The shared codebase compiles for web because:
  - `appinio_video_player_plus` was swapped for stock `video_player` ([lib/core/components/video/video_player_widget.dart](../lib/core/components/video/video_player_widget.dart)). The old package referenced `ui.platformViewRegistry` which moved out of `dart:ui` in Flutter 3.27+.
  - `app_tracking_transparency` is commented out in [pubspec.yaml](../pubspec.yaml); [lib/core/utils/tracking_permission.dart](../lib/core/utils/tracking_permission.dart) is now a graceful no-op.
  - `firebase_options.dart` already has a `web` `FirebaseOptions` entry.

## What's no-op or broken at runtime on web (compiles, doesn't work)

Most mobile-only Flutter plugins declare a web stub so the project compiles, but the plugin does nothing at runtime. These are the load-bearing features that are broken on web today:

| Plugin / feature | Web status | What that means |
|---|---|---|
| `firebase_messaging` push notifications | ❌ No FCM on web without VAPID key + service worker | No push, no token registration |
| `flutter_local_notifications` | ❌ Mostly no-op on web | No local notifications |
| `alarm` (medicine reminders) | ❌ No web | Medicine reminders silently fail |
| `record` (audio messages in chat) | ❌ No web on this version | Audio button is a no-op |
| `image_picker` from gallery/camera | ⚠️ Works (uses `<input type=file>`); camera limited | Mostly OK |
| `permission_handler` | ⚠️ Most permissions are no-op on web | `Permission.notification.request()` etc. silently return granted |
| `firebase_app_check` PlayIntegrity | ❌ Different on web (uses reCAPTCHA) | AppCheck won't engage; backend AppCheck enforcement will reject web requests until reCAPTCHA is wired |
| `google_sign_in` / `flutter_facebook_auth` / `sign_in_with_apple` | ⚠️ Need separate web OAuth setup | Won't work until web client IDs are configured |
| `firebase_auth` phone OTP | ⚠️ Uses reCAPTCHA on web — requires the reCAPTCHA enterprise site key in Firebase Console | Phone auth flow is different on web |
| `flutter_native_splash`, `flutter_launcher_icons` | ❌ Mobile build-time only | Native splash is a no-op on web; web has its own splash in `web/index.html` |
| `package_info_plus`, `device_info_plus` | ✅ Web shims exist | OK |
| `cloud_firestore` | ✅ Works on web | OK |

## External work required for full functionality

These are **outside the codebase** — you (or whoever owns the Firebase project, OAuth registrations, and backend) need to do them in the respective consoles.

### 1. Register a Firebase Web App

- Go to Firebase Console → project (currently configured as `disney-d2bd5` per [firebase_options.dart](../lib/firebase_options.dart) — note CLAUDE.md says the project should be `escola-cede2`; reconcile this before going further).
- Add a Web App; copy the generated config.
- Run `flutterfire configure --platforms=web` to regenerate [firebase_options.dart](../lib/firebase_options.dart) with the actual web project config.
- Note: there is already a `web` block in `firebase_options.dart` (line 68-76). Verify those values match the Firebase Web App config.

### 2. FCM web (push notifications)

- Generate a **VAPID key pair** in Firebase Console → Cloud Messaging → Web configuration.
- Save the VAPID public key; pass it to `messaging.getToken(vapidKey: '...')` (currently `LoginImpl.login` calls `messaging.getToken()` with no key — that fails silently on web).
- Add a **service worker** at [web/firebase-messaging-sw.js](../web/firebase-messaging-sw.js):

  ```javascript
  importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
  importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');
  firebase.initializeApp({ /* same config as web FirebaseOptions */ });
  const messaging = firebase.messaging();
  ```

- Register the service worker in `web/index.html`.
- Wire a `kIsWeb` branch in [lib/features/login/data_sources/login_impl.dart](../lib/features/login/data_sources/login_impl.dart) so `getToken(vapidKey: ...)` is called on web; on native the `vapidKey` argument is ignored.

### 3. OAuth: Google / Facebook / Apple

- **Google**: Create a Web OAuth client in Google Cloud Console. Add the web origin (e.g., `https://app.criarte.filhos.app`) to authorized origins. Pass the web client ID to `GoogleSignIn(serverClientId: ..., clientId: webClientIdOnWeb)` via `kIsWeb`.
- **Facebook**: In Facebook Developer Portal, add a Web product to the app, add the web origin to Valid OAuth Redirect URIs. The `flutter_facebook_auth` web plugin will pick up the FB JS SDK config from `web/index.html` (`<script async defer src="https://connect.facebook.net/.../sdk.js"></script>`).
- **Apple**: Create a Service ID (separate from the iOS App ID) in Apple Developer Portal. Configure return URLs. The web flow uses Apple's JS SDK rather than the iOS native flow. `sign_in_with_apple` package documents the web wiring.

### 4. Firebase App Check (web)

- Switch web App Check to **reCAPTCHA v3** or **reCAPTCHA Enterprise** in Firebase Console.
- In [lib/init_dependencies.dart](../lib/init_dependencies.dart), add a `kIsWeb` branch for App Check:

  ```dart
  if (kReleaseMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      webProvider: ReCaptchaV3Provider('YOUR-RECAPTCHA-SITE-KEY'),
    );
  }
  ```

### 5. Backend CORS

- The REST API at `https://criarte.filhos.app/api/v1/` must allow CORS from the web origin (e.g., `https://app.criarte.filhos.app`). Coordinate with backend.
- Preflight requests (`OPTIONS`) must succeed for every endpoint the web app calls.
- If cookies are used for sessions, set `SameSite=None; Secure` and `credentials: 'include'` on Dio (`BaseOptions(extra: {'withCredentials': true})`) — note: this requires server-side `Access-Control-Allow-Credentials: true` and a non-wildcard origin.

### 6. Phone Auth reCAPTCHA

- Firebase Console → Authentication → Sign-in method → Phone → enable. Web uses an invisible reCAPTCHA challenge.
- Add reCAPTCHA Enterprise key (if using Enterprise) in the Firebase Console.
- The `firebase_auth` web plugin auto-handles this; no code changes needed beyond ensuring the user is in a foreground browser tab when the OTP flow runs.

## Codebase follow-ups to fully fix the "compile-only" lints

These are optional improvements that would make the web bundle smaller, faster, and more correct:

- [ ] Remove `--no-tree-shake-icons` after fixing every non-const `IconData(...)` call site. Run `flutter build web` (without the flag) to get the list. Likely a handful of widgets construct `IconData(codePoint)` from a variable.
- [ ] Add explicit `kIsWeb` guards in:
  - [lib/features/login/data_sources/login_impl.dart](../lib/features/login/data_sources/login_impl.dart) — `messaging.getToken(vapidKey: kIsWeb ? '...' : null)`
  - [lib/core/utils/alarm_manager/alarm_manager.dart](../lib/core/utils/alarm_manager/alarm_manager.dart) — short-circuit on web
  - [lib/features/chat/](../lib/features/chat/) — audio recording UI hidden on web
  - [lib/features/add_medicine/](../lib/features/add_medicine/) — alarm scheduling UI hidden on web
- [ ] Disable `flutter_native_splash` for web (already does this automatically — just confirm with `flutter pub run flutter_native_splash:create`).
- [ ] Wire `--dart-define=FLAVOR=parents|professores` into a runtime read for web (since web ignores `--flavor`). The launch entries pass this; add a Dart-side read.

## Quick reference: build commands

```powershell
# parents web build
flutter build web --no-tree-shake-icons -t lib/main.dart

# professores web build (to a separate output dir)
flutter build web --no-tree-shake-icons -t lib/main_professores.dart --output build/web_professores

# parents dev server (Chrome)
flutter run -d chrome --no-tree-shake-icons -t lib/main.dart

# professores dev server (Chrome)
flutter run -d chrome --no-tree-shake-icons -t lib/main_professores.dart
```

## Quick reference: VS Code

See [.vscode/launch.json](../.vscode/launch.json) — 8 configurations:

- `parents · debug (native)` / `· profile (native)` / `· release (native)`
- `professores · debug (native)` / `· profile (native)` / `· release (native)`
- `parents · web (Chrome)`
- `professores · web (Chrome)`
