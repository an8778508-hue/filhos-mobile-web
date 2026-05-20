# Development Guide — Criarte (Filhos / Escola)

Build, run, and debug the app on both flavors. Read this first if you've just cloned the repo or switched branches.

For architecture / conventions, read [../CLAUDE.md](../CLAUDE.md). For shell-target reference, the [../Makefile](../Makefile) is authoritative.

---

## 0. Quick-reference cheat sheet

| Task | Makefile (recommended) | Raw flutter (always works) |
|---|---|---|
| Install deps | `make deps` | `flutter pub get` |
| Codegen (assets.gen.dart) | `make codegen` | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Full first-time setup | `make setup` | `flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs` |
| Run parents (debug) | `make run-parents` | `flutter run -t lib/main.dart --flavor parents` |
| Run teachers (debug) | `make run-professors` | `flutter run -t lib/main_professores.dart --flavor professores` |
| Run parents on web (Chrome) | — | `flutter run -t lib/main.dart -d chrome --web-port 5173` |
| Build parents APK (release) | `make build-parents-apk` | `flutter build apk -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| Build teachers APK (release) | `make build-professors-apk` | `flutter build apk -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons` |
| Build parents AAB (Play Store) | `make build-parents-aab` | `flutter build appbundle -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| Build teachers AAB | `make build-professors-aab` | `flutter build appbundle -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons` |
| Build parents iOS (macOS only) | `make build-parents-ios` | `flutter build ios -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| Analyze | `make analyze` | `flutter analyze` |
| Format | `make format` | `dart format lib/` |
| Clean | `make clean` | `flutter clean && rm -rf .dart_tool build` |
| Update launcher icons (parents) | — | `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml` |
| Update launcher icons (teachers) | — | `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml` |
| Update splash (parents) | — | `flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml` |
| Update splash (teachers) | — | `flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml` |

> **Why `--no-tree-shake-icons`**: the app uses dynamic `IconData` from server-driven config in `my_icon.dart`. Tree-shaking icons drops them at build time and the app renders blanks. The Makefile bakes this flag in.

> **Windows note**: `make` isn't preinstalled. Either install it (Chocolatey: `choco install make` / Git Bash includes it / WSL has it) or use the raw `flutter` commands. Both produce identical results.

---

## 1. Prerequisites

### Required

| Tool | Version | How to install |
|---|---|---|
| **Flutter** | **3.29.3 exactly** (pinned in [.fvmrc](../.fvmrc)) | Best: install [FVM](https://fvm.app), then `fvm use 3.29.3`. Alternative: install Flutter 3.29.3 directly and put it on PATH. |
| Dart SDK | Bundled with Flutter — `>=3.0.5 <4.0.0` | Comes with Flutter |
| Git | any modern | OS package manager |

### For Android development

| Tool | Notes |
|---|---|
| **Android Studio** (or JetBrains IntelliJ) | Provides the Android SDK, emulator, Gradle |
| **Android SDK 34** | Install via Android Studio → SDK Manager |
| **JDK 17** | Required by Gradle 8.x. Comes with recent Android Studio; otherwise install separately |
| Java env vars | `JAVA_HOME` pointing at JDK 17 (Windows: System → Environment Variables) |

### For iOS development (macOS only)

| Tool | Notes |
|---|---|
| **Xcode 15+** | Mac App Store |
| **CocoaPods** | `sudo gem install cocoapods` then `cd ios && pod install` |
| Xcode command-line tools | `xcode-select --install` |

### For web development

Chrome (or Edge) — already installed on most dev machines. The repo's web platform files (`web/index.html`, `web/manifest.json`) are checked in.

### Recommended (not strictly required)

- **VS Code** with the Dart + Flutter extensions, OR Android Studio with the Flutter plugin
- **fvm** (Flutter Version Management) — keeps you pinned to 3.29.3 even if your global Flutter is a different version

---

## 2. First-time setup

After cloning the repo:

```powershell
# Windows PowerShell (from repo root):
git clone <repo-url>
cd filhos-mobile

# 1. Pin Flutter version (FVM)
fvm use 3.29.3

# 2. Install dependencies
fvm flutter pub get
# OR: make deps

# 3. Generate code (assets.gen.dart and any *.g.dart files)
fvm dart run build_runner build --delete-conflicting-outputs
# OR: make codegen

# 4. (iOS only, macOS) Install CocoaPods
cd ios; pod install; cd ..
# OR: make ios-pods
```

```bash
# macOS / Linux equivalent:
git clone <repo-url>
cd filhos-mobile
fvm use 3.29.3
make setup   # runs deps + codegen
cd ios && pod install && cd ..   # macOS only
```

### Verify the setup

```powershell
fvm flutter doctor -v
```

Expected: green checks for Flutter, Android toolchain (if doing Android), Xcode (if doing iOS), Chrome (for web). Any red items are blockers — fix before proceeding.

### Firebase configuration files

The repo includes:
- [`android/app/google-services.json`](../android/app/google-services.json) (committed)
- iOS plist files in `ios/<flavor>/GoogleService-Info.plist` (per flavor)
- [`lib/firebase_options.dart`](../lib/firebase_options.dart) (committed; FlutterFire-generated)

These connect to the `escola-cede2` Firebase project. **Do not** regenerate `firebase_options.dart` against a different Firebase project — it'd break auth + Firestore. If you're forking, use `flutterfire configure` against your own project.

---

## 3. Run in debug mode

### Pick a device / emulator first

```powershell
fvm flutter devices
```

Sample output:
```
Found 3 connected devices:
  Windows (desktop) • windows • windows-x64    • Microsoft Windows [Version 10...]
  Chrome (web)      • chrome  • web-javascript • Google Chrome
  Edge (web)        • edge    • web-javascript • Microsoft Edge
```

If no Android/iOS device shows up:
- Android: open Android Studio → AVD Manager → start an emulator (or plug in a phone with USB debugging on)
- iOS: open Xcode → start a Simulator (macOS only)

### Parents flavor (Android / iOS)

```powershell
# Makefile (recommended)
make run-parents

# Or raw flutter
fvm flutter run -t lib/main.dart --flavor parents

# Target a specific device:
fvm flutter run -t lib/main.dart --flavor parents -d <device-id>
```

### Teachers flavor (Android / iOS)

```powershell
make run-professors

# Or:
fvm flutter run -t lib/main_professores.dart --flavor professores
```

### Either flavor on web (Chrome)

`--flavor` is **not supported** on Flutter web. The flavor is set inside `main.dart` / `main_professores.dart` itself (via `AppFlavor.setCurrent(...)`), so just target the entry point:

```powershell
# Parents on web:
fvm flutter run -t lib/main.dart -d chrome --web-port 5173

# Teachers on web:
fvm flutter run -t lib/main_professores.dart -d chrome --web-port 5173
```

The `--web-port` flag pins the dev server to a known port; without it Flutter picks a random one. Use any free port.

### Hot reload / hot restart while running

| Keypress | What it does |
|---|---|
| `r` | Hot reload — re-apply Dart changes without restarting state |
| `R` | Hot restart — restart the app, reset all in-memory state |
| `p` | Toggle widget paint borders (visual debugging) |
| `o` | Toggle platform (Android ↔ iOS rendering) |
| `q` | Quit |
| `d` | Detach (leave app running, terminate the `flutter run` process) |
| `h` | Show all available interactive commands |

> **When hot reload isn't enough**: changes to `main()`, BLoC constructors, native code, or `pubspec.yaml` require a full restart (`R`) or a stop-and-rerun.

---

## 4. Build release artifacts

### Android — APK (testing / sideloading)

```powershell
make build-parents-apk
# → build/app/outputs/flutter-apk/app-parents-release.apk

make build-professors-apk
# → build/app/outputs/flutter-apk/app-professores-release.apk
```

### Android — App Bundle (Play Store upload)

```powershell
make build-parents-aab
# → build/app/outputs/bundle/parentsRelease/app-parents-release.aab

make build-professors-aab
# → build/app/outputs/bundle/professoresRelease/app-professores-release.aab
```

### iOS (macOS only)

```bash
make build-parents-ios
make build-professors-ios

# Then open ios/Runner.xcworkspace in Xcode → Product → Archive
```

### Build signing

Android release builds require the signing keystore. Coordinate with the maintainer for keystore + `key.properties` setup (do NOT commit either). See [docs/SECURITY-INCIDENT-KEYSTORE.md](SECURITY-INCIDENT-KEYSTORE.md) for prior context on keystore handling.

iOS release requires an Apple Developer account configured in Xcode. The signing identity / provisioning profile is set per-flavor in `ios/Runner.xcodeproj`.

---

## 5. Codegen, launcher icons, splash screens

### Codegen (`build_runner`)

Generates `lib/shared/assets/assets.gen.dart` (asset paths) and any `*.g.dart` files (JSON serialization).

```powershell
# One-shot:
make codegen
# OR
fvm dart run build_runner build --delete-conflicting-outputs

# Watch mode (re-generates on file changes — useful when editing models):
make codegen-watch
# OR
fvm dart run build_runner watch --delete-conflicting-outputs
```

**When you need to run codegen**:
- After a fresh clone (first-time setup)
- After switching branches if `pubspec.yaml` / `assets/` differ
- After adding assets to `pubspec.yaml`
- If you see `Error when reading 'lib/shared/assets/assets.gen.dart': The system cannot find the path specified`

### Launcher icons (per flavor)

```powershell
fvm flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
fvm flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
```

These read [`flutter_launcher_icons-parents.yaml`](../flutter_launcher_icons-parents.yaml) / [`flutter_launcher_icons-professores.yaml`](../flutter_launcher_icons-professores.yaml) and write platform-specific icon assets. Run after changing the source icons in `assets/icons/`.

### Native splash (per flavor)

```powershell
fvm flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
fvm flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml
```

---

## 6. Debugging

### Flutter DevTools

When `flutter run` is attached, it prints a DevTools URL like:
```
The Flutter DevTools debugger and profiler is available at: http://127.0.0.1:9100/?uri=ws://127.0.0.1:64355/...
```

Open in any browser. DevTools provides:
- **Widget inspector** — visual tree, layout debug
- **Performance** — frame timing, jank detection
- **Memory** — heap snapshots, allocation tracking
- **Network** — every `Dio` request/response (with the body redaction from `network_client._redactBody`)
- **Logging** — live `debugPrint` output + Flutter framework warnings

### Network inspection without DevTools

Every REST call goes through `lib/core/network/network_client.dart`. Add a temporary `debugPrint` in `sendRequest` or use the existing Crashlytics breadcrumbs to inspect what went over the wire.

For Firestore inspection: open the Firebase Console → Firestore → Data — you'll see live writes from the running app.

### Crashlytics (production crash reports)

Real-device debug builds also send crashes to Crashlytics. View at:
**Firebase Console → Crashlytics** (in the `escola-cede2` project)

The breadcrumb redaction in `network_client._redactBody` keeps sensitive payloads (medications, AABAR, email-OTP) out of the logs. If you add a new endpoint with PII, extend the redaction allowlist.

### Logs

```powershell
# Android (with device connected):
adb logcat | grep -i flutter

# iOS (macOS):
xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "com.algoriza"'

# Flutter-side debugPrint output is in the `flutter run` terminal directly
```

### Common debug scenarios

| Symptom | Where to look |
|---|---|
| App crashes on splash | `lib/features/splash/` — likely `initDependencies()` failure |
| Login succeeds but user lands on the wrong screen | `UserBloc.loggedIn(user)` + `isApproval` check in the listener |
| Chat messages don't appear | Firestore Console → `messages` collection; check security rules |
| Translations show the key name (e.g., `home_title` literally) | Either the key is missing from `assets/langs/*.json` or `ConfigCubit` translations haven't loaded |
| Image upload fails silently | Firebase Storage console → check rules + the upload's path |
| OTP says "already_sent" forever | Hive key `last_otp_request` is stuck; toggle `clearCache = true` in `init_dependencies.dart`, run once, toggle back |

---

## 7. Switching between flavors / branches

### Switching flavors

The two flavors share `lib/` code. Just stop the current `flutter run` (`q`) and start the other:

```powershell
# from parents to teachers:
fvm flutter run -t lib/main_professores.dart --flavor professores
```

Hive storage is per-flavor on Android (separate `applicationId`s mean separate app data). On iOS, same. So you have independent login sessions per flavor on the same device.

### Switching branches — important steps

After `git checkout <other-branch>`:

```powershell
# 1. Refresh dependencies (pubspec.yaml may differ between branches)
fvm flutter pub get

# 2. ALWAYS regenerate codegen output — assets.gen.dart is gitignored / branch-specific
fvm dart run build_runner build --delete-conflicting-outputs

# 3. If you hit weird build errors, nuclear-option clean:
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

The "missing `lib/shared/assets/assets.gen.dart`" error after a branch switch is the most common gotcha. Step 2 fixes it.

---

## 8. Reset / clear state for testing

### Clear app data (Hive + HydratedBloc)

Open [lib/init_dependencies.dart](../lib/init_dependencies.dart), set `bool clearCache = true;`, run once, then set back to `false`. This wipes:
- HydratedBloc storage (UserBloc, ConfigCubit)
- Hive boxes (token, user, last_otp_request, etc.)

Equivalent: uninstall the app and reinstall.

### Reset login session

If you just want to log out without rebuilding, use the in-app Settings → "Sair" (logout). Hive `token`/`user` are wiped; UserBloc emits `Empty`.

### Force-refresh remote config (translations / styling)

`ConfigCubit` reads Firestore `config/*` at app start AND listens for changes — restarting the app re-fetches. If translations look stale, check the `config/*` doc in Firebase Console and verify the field you expected to change is actually different.

---

## 9. Common errors & fixes

| Error | Likely cause | Fix |
|---|---|---|
| `Error when reading 'lib/shared/assets/assets.gen.dart'` | Codegen not run for this branch | `make codegen` |
| `Could not find an option named "flavor"` (on web) | Used `--flavor` with `-d chrome` | Drop the `--flavor` flag — web uses the entry-point file (`lib/main.dart` vs `lib/main_professores.dart`) |
| `FirebaseAppCheck activate failed` | App Check needs Play Integrity on a real device with a valid Google Play install | Only run on real devices for App Check; emulators / web skip it (see `init_dependencies.dart`) |
| `Tree-shaking icons` warning at build | Build without `--no-tree-shake-icons` | Use the Makefile targets (they include it) or add the flag manually |
| `flutter doctor` shows "Android license status unknown" | Haven't accepted Android SDK licenses | `fvm flutter doctor --android-licenses` then accept all |
| `cocoapods not installed` (macOS) | iOS dep | `sudo gem install cocoapods && cd ios && pod install` |
| App opens but immediately closes on Android | Crash before MaterialApp builds — usually missing google-services.json or wrong package name | Verify [android/app/google-services.json](../android/app/google-services.json) matches the flavor's `applicationId` (`com.algoriza.criarte` for parents, `com.algoriza.profecriarte` for teachers) |
| Chat messages don't sync | Firestore rules or App Check rejection | Firebase Console → Firestore → Rules tab → check the deny logs |
| Web build warning "This application is not configured to build on the web" | `web/` platform files might be missing or out of date | `flutter create . --platforms=web` (adds missing files; doesn't touch existing) |
| Random PowerShell errors with `&&` | PowerShell uses `;` not `&&` for command chaining (in older versions) | Use `;` or run each command separately |

---

## 10. Where to go next

- **Architecture deep-dive**: [../CLAUDE.md](../CLAUDE.md) — features, conventions, gotchas
- **Project constitution**: [../.specify/memory/constitution.md](../.specify/memory/constitution.md) — non-negotiable rules
- **Active feature plans**: [../specs/](../specs/) — one folder per feature, with spec.md / plan.md / tasks.md
- **Commercial reference**: [../specs/commercial-brief.md](../specs/commercial-brief.md) — sales-team-facing feature inventory
- **Makefile reference**: [../Makefile](../Makefile) — every shell target with the right flags
