# Command Reference — Criarte (Filhos / Escola)

The complete command set with **every flag explained**, paired with the **common sequences** new team members need. If you're brand new, read sections **A** and **B** in order; after that this file is a reference.

For build/run/debug guidance, see [DEVELOPMENT.md](DEVELOPMENT.md). For shell-target reference, the [../Makefile](../Makefile) is authoritative.

---

## How to read this doc

Every command appears in this shape:

> ### `flutter <command>`
>
> **What it does**: one-line description
>
> **Key flags**:
> | Flag | Purpose |
> |---|---|
> | `--example` | what it does |
>
> **Example for parents**: command with parents-specific args
> **Example for teachers**: command with teachers-specific args
> **When to use**: situations where this is the right command

If you're on **Windows PowerShell**, use `;` instead of `&&` to chain commands. If you have FVM installed, replace `flutter` with `fvm flutter` and `dart` with `fvm dart` — the Makefile auto-detects and does this for you.

---

## A. Common workflows (run these in order)

### A1. First-time setup (after cloning)

```powershell
# 1. Pin Flutter version
fvm use 3.29.3

# 2. Install dependencies
fvm flutter pub get

# 3. Generate code (assets.gen.dart and any *.g.dart)
fvm dart run build_runner build --delete-conflicting-outputs

# 4. (iOS only, macOS) install pods
cd ios; fvm flutter pub run pod install; cd ..

# 5. Verify toolchain
fvm flutter doctor -v

# 6. Find a device to run on
fvm flutter devices

# 7. Run the parents flavor
fvm flutter run -t lib/main.dart --flavor parents
```

**Single-line Makefile equivalent (steps 2-3)**: `make setup`

### A2. Daily development loop

```powershell
# Pull latest changes
git pull

# Refresh dependencies if pubspec changed
fvm flutter pub get

# If you see "missing assets.gen.dart" — codegen
fvm dart run build_runner build --delete-conflicting-outputs

# Run the flavor you're working on
fvm flutter run -t lib/main.dart --flavor parents
# (or main_professores.dart --flavor professores)

# While running: press 'r' for hot reload, 'R' for hot restart, 'q' to quit
```

### A3. Branch-switching workflow

```powershell
# Save / commit / stash work in progress
git status

# Switch branches
git checkout <other-branch>

# REQUIRED: refresh deps (pubspec.yaml may differ)
fvm flutter pub get

# REQUIRED: regenerate codegen output (assets.gen.dart is branch-specific)
fvm dart run build_runner build --delete-conflicting-outputs

# If you get weird errors, nuclear-option clean:
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

# Resume development
fvm flutter run -t lib/main.dart --flavor parents
```

### A4. Release build workflow (Android Play Store)

```powershell
# 1. Make sure analyze is clean
fvm flutter analyze

# 2. Make sure both flavors build debug
make build-parents-debug
make build-professors-debug

# 3. Build the release AAB for both flavors
make build-parents-aab
make build-professors-aab

# 4. Inspect output
ls build/app/outputs/bundle/parentsRelease/
ls build/app/outputs/bundle/professoresRelease/

# 5. Upload to Play Console
```

### A5. Web build & deploy workflow

```powershell
# 1. Build parents web bundle (to default build/web/)
fvm flutter build web -t lib/main.dart --release

# 2. Move to a flavor-specific folder so it doesn't collide with teachers
move build/web build/web-parents

# 3. Build teachers web bundle
fvm flutter build web -t lib/main_professores.dart --release

# 4. Move that one too
move build/web build/web-professores

# 5. Deploy each folder to its own subdomain / path
# e.g., upload build/web-parents/ to https://parents.criarte.filhos.app
# and  build/web-professores/ to https://teachers.criarte.filhos.app
```

Flutter web doesn't support `--flavor` — the entry-point file is the only flavor signal. You must build each flavor sequentially and rename the output folder (see §C5).

### A6. Hotfix workflow

```powershell
# 1. Branch from current production
git checkout main; git pull
git checkout -b hotfix/<short-description>

# 2. Make the smallest possible fix
# 3. Test on both flavors
make run-parents       # in one terminal, smoke-test
make run-professors    # in another terminal, smoke-test

# 4. Analyze + build to confirm no regressions
fvm flutter analyze
make build-parents-aab
make build-professors-aab

# 5. Commit + PR
git add <changed-files>
git commit -m "fix: ..."
git push -u origin hotfix/<short-description>
```

---

## B. Setup commands

### `fvm use 3.29.3`

**What it does**: Pins this checkout to Flutter 3.29.3 (the version in [.fvmrc](../.fvmrc)). Downloads it on first run.

**Key flags**: none commonly needed.

**When to use**: First time you clone the repo, or after Flutter updates `.fvmrc`.

**Without FVM**: ensure your global `flutter --version` reports `3.29.3`. Different versions cause hard-to-debug build errors.

---

### `flutter pub get`

**What it does**: Reads [pubspec.yaml](../pubspec.yaml), downloads all declared dependencies into the Pub cache, generates [.dart_tool/package_config.json](../.dart_tool/package_config.json).

**Key flags**:
| Flag | Purpose |
|---|---|
| `--offline` | Use cached packages only (don't hit pub.dev) |
| `--verbose` | Show network activity and resolution decisions |

**Example**: `fvm flutter pub get`

**When to use**:
- After cloning
- After `git pull` if `pubspec.yaml` changed
- After branch switch
- Whenever you see `Target of URI doesn't exist: package:...`

**Makefile**: `make deps`

---

### `flutter pub upgrade`

**What it does**: Updates dependencies to the latest versions allowed by the constraints in `pubspec.yaml`. Writes new versions to `pubspec.lock`.

**Key flags**:
| Flag | Purpose |
|---|---|
| `--major-versions` | Allow breaking major-version bumps (rewrites `pubspec.yaml` constraints — use with caution) |
| `--dry-run` | Preview changes without writing |

**When to use**: Sparingly. Only when explicitly bringing dependencies forward — never as part of regular setup, because it can introduce unexpected breaking changes. Prefer `flutter pub outdated` first to see what would change.

---

### `flutter pub outdated`

**What it does**: Lists packages with newer versions available (without changing anything).

**Example output**: shown in [Bash output earlier in this session](#) — 119 packages out of date.

**When to use**: Periodic dependency-health check. Decide which ones to upgrade explicitly.

**Makefile**: `make outdated`

---

### `dart run build_runner build --delete-conflicting-outputs`

**What it does**: Runs all configured code generators. For this repo: generates `lib/shared/assets/assets.gen.dart` (asset path constants from `assets/` directory).

**Key flags**:
| Flag | Purpose |
|---|---|
| `--delete-conflicting-outputs` | **Required** — overwrites stale generated files without prompting |
| `--verbose` | Show each generator's progress |
| `--filter <glob>` | Re-generate only files matching the pattern |

**When to use**:
- After cloning (first setup)
- After branch switch (assets.gen.dart is branch-specific)
- After adding/removing files in `assets/`
- Whenever you see `Error when reading 'lib/shared/assets/assets.gen.dart'`

**Makefile**: `make codegen`

---

### `dart run build_runner watch --delete-conflicting-outputs`

**What it does**: Same as `build` but watches files and regenerates on every change. Stays attached.

**When to use**: While editing assets or model files actively — saves you having to re-run the one-shot command repeatedly.

**Makefile**: `make codegen-watch`

**Quit**: `Ctrl+C`

---

### `dart run build_runner clean`

**What it does**: Removes the build_runner cache and all generated files.

**When to use**: When `build` mysteriously fails or produces stale output despite `--delete-conflicting-outputs`. Follow with a fresh `build`.

---

### `cd ios && pod install` *(macOS only)*

**What it does**: Installs CocoaPods dependencies for the iOS build (Firebase, third-party native libs).

**Key flags**:
| Flag | Purpose |
|---|---|
| `--repo-update` | Pull the latest CocoaPods spec repo before install |
| `--clean-install` | Delete existing Pods/ first |

**When to use**:
- After cloning on macOS
- After `flutter pub get` if any plugin with iOS native code changed
- After `flutter clean`

**Makefile**: `make ios-pods`

---

## C. Run commands

### `flutter devices`

**What it does**: Lists every device, emulator, simulator, and platform target flutter can run on right now.

**Example output**:
```text
Found 3 connected devices:
  Windows (desktop) • windows • windows-x64    • Microsoft Windows [Version 10...]
  Chrome (web)      • chrome  • web-javascript • Google Chrome 148.0.7778
  Edge (web)        • edge    • web-javascript • Microsoft Edge 148.0.3967
```

**When to use**: Before `flutter run -d <device>` to know what device IDs are available.

**Pro tip**: If no Android device shows up, plug in a phone with USB debugging on, or start an emulator in Android Studio's AVD Manager.

---

### `flutter run`

**What it does**: Compiles the app and runs it on the selected device with hot-reload attached.

**Key flags**:
| Flag | Purpose |
|---|---|
| `-t <file>`, `--target <file>` | The entry-point file. **Required** for this repo: `lib/main.dart` (parents) or `lib/main_professores.dart` (teachers). |
| `--flavor <name>` | The build flavor. **Required** on Android/iOS: `parents` or `professores`. **Not supported on web.** |
| `-d <id>`, `--device-id <id>` | Pick a specific device when more than one is connected. Use `flutter devices` to see IDs. |
| `--debug` | Default mode. Includes hot reload, asserts, DevTools. Slower than release. |
| `--profile` | Performance-profiling mode. No asserts, but observatory is on. For benchmarking — DON'T use for regular development. |
| `--release` | Production mode. No hot reload, no asserts. Identical perf to the built APK. |
| `--web-port <int>` | (Web only) Pin the dev server to a specific port. Without it, Flutter picks a random one. |
| `--web-renderer <html\|canvaskit\|auto>` | (Web only) Renderer choice. `auto` is default. `canvaskit` for best fidelity, `html` for smallest bundle. |
| `--dart-define <KEY=VALUE>` | Inject compile-time constants. Used for env-specific config (rare in this repo). |
| `--hot` / `--no-hot` | Hot-reload behavior. Defaults to on in debug, off in profile/release. |
| `--observatory-port <int>` | Pin the VM service port. Use if your firewall needs a known port. |

**Example for parents (Android/iOS)**:
```powershell
fvm flutter run -t lib/main.dart --flavor parents
```

**Example for teachers (Android/iOS)**:
```powershell
fvm flutter run -t lib/main_professores.dart --flavor professores
```

**Example for parents (web — Chrome)**:
```powershell
fvm flutter run -t lib/main.dart -d chrome --web-port 5173
```

**Example for teachers (web — Chrome)**:
```powershell
fvm flutter run -t lib/main_professores.dart -d chrome --web-port 5173
```

**Example targeting a specific device**:
```powershell
# After running `flutter devices` to get the id
fvm flutter run -t lib/main.dart --flavor parents -d 192.168.1.50:5555
```

**Hot keys while running**:
| Key | Action |
|---|---|
| `r` | Hot reload (re-apply Dart changes, keep state) |
| `R` | Hot restart (re-apply everything, reset state) |
| `p` | Toggle widget paint borders |
| `o` | Toggle platform (Android ↔ iOS rendering simulation) |
| `q` | Quit |
| `d` | Detach (app stays running, terminal returns) |
| `h` | Help (full key list) |

**Makefile**: `make run-parents` / `make run-professors`

---

### `flutter run --profile`

**What it does**: Builds and runs in profile mode — optimized like release, but DevTools still attached.

**When to use**: Performance benchmarking. Frame-rate measurements are only meaningful in profile or release mode (debug mode has overhead).

**Example**: `fvm flutter run -t lib/main.dart --flavor parents --profile`

---

### `flutter run --release`

**What it does**: Builds and runs in release mode on a device. Same artifacts as `flutter build apk` would produce, but skips the install-from-APK step.

**When to use**: Verify a release build behaves correctly before producing the actual artifact.

**Example**: `fvm flutter run -t lib/main.dart --flavor parents --release --no-tree-shake-icons`

---

## D. Build commands (artifacts)

### `flutter build apk`

**What it does**: Compiles a single Android APK for the chosen flavor and mode. Output goes to `build/app/outputs/flutter-apk/`.

**Key flags**:
| Flag | Purpose |
|---|---|
| `-t <file>` | **Required**: entry-point file |
| `--flavor <name>` | **Required**: `parents` or `professores` |
| `--debug` / `--profile` / `--release` | Build mode. Default is `--release`. |
| `--no-tree-shake-icons` | **Required for this repo** — preserves dynamic IconData (see `my_icon.dart`) |
| `--split-per-abi` | Produces 3 APKs (armv7, arm64, x86_64) instead of 1 fat APK. Each is ~33% smaller. |
| `--obfuscate` + `--split-debug-info=<dir>` | Obfuscate Dart symbols for release. Saves the mapping in `<dir>` (commit this if you want symbolicated crashes). |
| `--dart-define <KEY=VALUE>` | Inject compile-time constants. |
| `--target-platform <abi>` | Restrict to one ABI. E.g., `android-arm64` for a 64-bit-only build. |

**Example for parents (release APK)**:
```powershell
fvm flutter build apk -t lib/main.dart --flavor parents --release --no-tree-shake-icons
```

**Example for teachers (release APK)**:
```powershell
fvm flutter build apk -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons
```

**Output paths**:
- Parents release: `build/app/outputs/flutter-apk/app-parents-release.apk`
- Teachers release: `build/app/outputs/flutter-apk/app-professores-release.apk`

**Makefile**: `make build-parents-apk` / `make build-professors-apk` / `make build-parents-debug` / `make build-professors-debug`

---

### `flutter build appbundle`

**What it does**: Compiles an **Android App Bundle** (`.aab`) — the format required by Google Play. Smaller install size than APK (Play Store generates device-specific APKs at install time).

**Key flags**: Same as `flutter build apk` plus:
| Flag | Purpose |
|---|---|
| `--target-platform android-arm,android-arm64,android-x64` | All three ABIs in one bundle (default) |

**Example for parents**:
```powershell
fvm flutter build appbundle -t lib/main.dart --flavor parents --release --no-tree-shake-icons
```

**Example for teachers**:
```powershell
fvm flutter build appbundle -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons
```

**Output paths**:
- Parents: `build/app/outputs/bundle/parentsRelease/app-parents-release.aab`
- Teachers: `build/app/outputs/bundle/professoresRelease/app-professores-release.aab`

**Use this (not APK) for Play Store uploads.**

**Makefile**: `make build-parents-aab` / `make build-professors-aab`

---

### `flutter build ios`  *(macOS only)*

**What it does**: Compiles an iOS app archive in `build/ios/`. Does **not** sign or bundle into an `.ipa` — open the project in Xcode for the final archive step.

**Key flags**:
| Flag | Purpose |
|---|---|
| `-t <file>` | **Required** |
| `--flavor <name>` | **Required** |
| `--release` | Default for builds; explicit is clearer |
| `--no-tree-shake-icons` | **Required** for this repo |
| `--no-codesign` | Skip code-signing (useful for CI verification builds; Xcode signs at archive time) |

**Example for parents**:
```bash
fvm flutter build ios -t lib/main.dart --flavor parents --release --no-tree-shake-icons
```

**Example for teachers**:
```bash
fvm flutter build ios -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons
```

**Post-build step**: Open `ios/Runner.xcworkspace` in Xcode → Product → Archive → Distribute App.

**Makefile**: `make build-parents-ios` / `make build-professors-ios`

---

### `flutter build ipa`  *(macOS only)*

**What it does**: One-shot: builds and signs an `.ipa` ready for TestFlight / App Store Connect.

**Key flags**: same as `build ios` plus:
| Flag | Purpose |
|---|---|
| `--export-method app-store` | App Store distribution (most common) |
| `--export-method ad-hoc` | Specific UDIDs (internal testing) |
| `--export-method development` | Development team only |

**Example for parents**:
```bash
fvm flutter build ipa -t lib/main.dart --flavor parents --release --no-tree-shake-icons --export-method app-store
```

**Output path**: `build/ios/ipa/`

---

### `flutter build web`

**What it does**: Compiles a static-website bundle in `build/web/`. Output is HTML + JS + assets, deployable to any static host (Firebase Hosting, Netlify, Vercel, S3+CloudFront, nginx).

**Key flags**:
| Flag | Purpose |
|---|---|
| `-t <file>` | **Required**: `lib/main.dart` (parents) or `lib/main_professores.dart` (teachers). **Note: `--flavor` is NOT supported on web** — the entry-point file is the only flavor signal. |
| `--release` | Default. Produces minified JS. |
| `--profile` | Optimized but with profiling enabled |
| `--web-renderer <html\|canvaskit\|auto>` | `canvaskit` (default): WebAssembly-based, best fidelity but ~2 MB extra download. `html`: smaller bundle, less faithful to mobile rendering. `auto`: canvaskit on desktop, html on mobile. |
| `--base-href <path>` | If deploying to a subdirectory (e.g., `/parents/`), set this to `/parents/`. Defaults to `/`. |
| `--output <dir>` | Custom output directory (default `build/web`). **Critical for this repo** since both flavors write to the same default path. |
| `--source-maps` | Emit JS source maps (useful for debugging production crashes) |
| `--csp` | Build in Content Security Policy mode — needed for some hosts that enforce strict CSP |
| `--pwa-strategy <none\|offline-first>` | Service-worker behavior. `offline-first` (default) caches everything for offline use. `none` disables the service worker. |

**Example for parents (production web)**:
```powershell
fvm flutter build web -t lib/main.dart --release --output build/web-parents
```

**Example for teachers (production web)**:
```powershell
fvm flutter build web -t lib/main_professores.dart --release --output build/web-professores
```

**Example for parents (deployed under /parents/ subdirectory)**:
```powershell
fvm flutter build web -t lib/main.dart --release --base-href "/parents/" --output build/web-parents
```

**Example with HTML renderer (smaller bundle, mobile-friendly)**:
```powershell
fvm flutter build web -t lib/main.dart --release --web-renderer html --output build/web-parents
```

**Output**: `build/web-parents/` (or whatever `--output` specifies) containing `index.html`, `main.dart.js`, `flutter.js`, `assets/`, `canvaskit/`, etc.

**Deploy**: copy the entire output directory to your static host's root.

**Serving the build locally for verification**:
```powershell
# Option 1: any static-file server
npx serve build/web-parents

# Option 2: Python
python -m http.server 8080 --directory build/web-parents

# Option 3: Firebase Hosting emulator (if you'll deploy there)
firebase emulators:start --only hosting
```

**No Makefile target today** — add one if you'll build web often. Template:
```makefile
build-parents-web:
	$(FLUTTER) build web -t lib/main.dart --release --output build/web-parents $(BUILD_FLAGS)

build-professors-web:
	$(FLUTTER) build web -t lib/main_professores.dart --release --output build/web-professores $(BUILD_FLAGS)
```

---

## E. Maintenance commands

### `flutter clean`

**What it does**: Deletes `build/` and `.dart_tool/`. Next `flutter run` or `flutter build` will rebuild everything from scratch.

**Key flags**: none commonly needed.

**When to use**:
- Build is broken in a way you can't diagnose
- Switching between modes (debug → release) on the same device sometimes leaves stale state
- After upgrading Flutter version

**Makefile**: `make clean` (also removes `.dart_tool` and `build`)

---

### `flutter analyze`

**What it does**: Runs the static analyzer over `lib/` per [analysis_options.yaml](../analysis_options.yaml). Reports errors, warnings, and lint issues.

**Key flags**:
| Flag | Purpose |
|---|---|
| `--fatal-warnings` | Treat warnings as errors (CI-friendly) |
| `--fatal-infos` | Treat info-level lints as errors |
| `--no-fatal-warnings` | Default — only errors fail |
| `<path>` | Analyze a specific directory |

**Example**: `fvm flutter analyze`

**When to use**:
- Before pushing a PR
- After resolving merge conflicts
- After a major refactor
- Required to be clean before merge (constitution Quality Gates)

**Makefile**: `make analyze`

---

### `flutter test`

**What it does**: Runs all `_test.dart` files in the `test/` directory.

**Note**: This repo has **no test suite today** (see constitution Quality Gates). The command is documented for when one is added. It runs without errors when there's no `test/` directory — just reports "No tests ran."

**Key flags**:
| Flag | Purpose |
|---|---|
| `--coverage` | Generate coverage report in `coverage/lcov.info` |
| `--name <pattern>` | Only run tests whose name matches |
| `--plain-name <substring>` | Only tests with this substring in the name |
| `--update-goldens` | Re-record golden-file tests |

---

### `dart format lib/`

**What it does**: Formats every Dart file in `lib/` per [analysis_options.yaml](../analysis_options.yaml).

**Key flags**:
| Flag | Purpose |
|---|---|
| `--line-length <n>` | Default 80; this project uses default |
| `-o write\|show\|none\|json` | Output mode. Default `write` modifies files in place. |
| `--set-exit-if-changed` | Exit non-zero if files would be reformatted (CI-friendly) |

**Example**: `fvm dart format lib/`

**Makefile**: `make format`

---

### `flutter doctor`

**What it does**: Diagnoses your local toolchain. Reports the status of Flutter, Android SDK, Xcode, Chrome, IDEs.

**Key flags**:
| Flag | Purpose |
|---|---|
| `-v`, `--verbose` | Detailed diagnostic output (the full file list per check) |
| `--android-licenses` | Interactive prompt to accept Android SDK licenses |

**Example**: `fvm flutter doctor -v`

**When to use**:
- After installing Flutter
- When a build mysteriously fails (often a toolchain issue, not your code)
- Before troubleshooting any platform-specific bug

---

### `flutter precache`

**What it does**: Downloads platform-specific Flutter artifacts (the engine for each platform). Normally runs on demand, but you can force it.

**Key flags**:
| Flag | Purpose |
|---|---|
| `--android` / `--ios` / `--web` / `--windows` / `--macos` / `--linux` | Restrict to specific platforms |
| `--all-platforms` | Download every platform's artifacts (large) |

**When to use**: CI provisioning, or first run on a metered connection where you want to control timing.

---

## F. Platform-specific commands

### Android

#### `adb devices`

**What it does**: Lists connected Android devices and their states.

**Example output**:
```
List of devices attached
192.168.1.50:5555  device
emulator-5554      device
```

#### `adb install <apk>`

**What it does**: Installs an APK directly on a connected device.

**Example**: `adb install build/app/outputs/flutter-apk/app-parents-release.apk`

#### `adb logcat | grep -i flutter`

**What it does**: Streams device logs filtered for Flutter output.

**When to use**: Native crashes, plugin errors that don't surface in `flutter run`'s output.

#### `cd android && ./gradlew clean`

**What it does**: Clears the Gradle build cache for the Android project.

**When to use**: When `flutter clean` isn't enough and Gradle-specific errors persist.

**Makefile**: `make android-clean`

---

### iOS *(macOS only)*

#### `cd ios && pod install`

**What it does**: Installs CocoaPods native dependencies for iOS plugins.

#### `cd ios && pod update`

**What it does**: Updates CocoaPods dependencies. Use sparingly — can introduce breaking changes.

**Makefile**: `make ios-pods-update`

#### `xcrun simctl list devices`

**What it does**: Lists iOS Simulators by version.

#### `xcrun simctl spawn booted log stream --predicate 'subsystem CONTAINS "com.algoriza"'`

**What it does**: Streams device logs for the Criarte app (replace `com.algoriza` if the bundle id changed).

---

## G. Per-flavor asset commands

### `flutter pub run flutter_launcher_icons -f <config>.yaml`

**What it does**: Reads a per-flavor config and writes launcher icons to the right Android/iOS asset directories.

**Configs in this repo**:
- [flutter_launcher_icons-parents.yaml](../flutter_launcher_icons-parents.yaml)
- [flutter_launcher_icons-professores.yaml](../flutter_launcher_icons-professores.yaml)

**Example for parents**:
```powershell
fvm flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
```

**Example for teachers**:
```powershell
fvm flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
```

**When to use**: After changing the source icon file(s) referenced in the config.

---

### `flutter pub run flutter_native_splash:create -f <config>.yaml`

**What it does**: Generates the native splash screen assets per flavor.

**Configs in this repo**:
- [flutter_native_splash-parents.yaml](../flutter_native_splash-parents.yaml)
- [flutter_native_splash-professores.yaml](../flutter_native_splash-professores.yaml)

**Example for parents**:
```powershell
fvm flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
```

**Example for teachers**:
```powershell
fvm flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml
```

**When to use**: After changing the splash background, logo, or color in the YAML config.

---

## H. Recovery / debug commands

### `flutter create . --platforms=web`

**What it does**: Scaffolds missing platform files for this project. Specifically, recreates the `web/` folder with `index.html`, `manifest.json`, `favicon.png`, and the `icons/` set if any are missing.

**When to use**: You see `This application is not configured to build on the web` when running `flutter run -d chrome`.

**Safety**: Does NOT overwrite existing files. Safe to run.

---

### `flutter screenshot`

**What it does**: Takes a screenshot of the connected device and saves to the current directory.

**Key flags**:
| Flag | Purpose |
|---|---|
| `--out <path>` | Output file (default `flutter_<timestamp>.png`) |
| `--type <device\|rasterizer\|skia>` | Screenshot mode. `device` is what the user sees; `skia` shows the Skia layer (debugging) |

**Example**: `fvm flutter screenshot --out screenshot.png`

---

### `flutter logs`

**What it does**: Streams logs from the connected device (Android `adb logcat` or iOS device logs).

**When to use**: When you've detached `flutter run` and want to keep watching logs.

---

### `flutter install`

**What it does**: Installs the most recently built APK to the connected device.

**Key flags**:
| Flag | Purpose |
|---|---|
| `--flavor <name>` | Which flavor's APK to install |

**Example**: `fvm flutter install --flavor parents`

**When to use**: You've built a release APK and want to install it on a device without rebuilding.

---

### `clearCache = true` recipe (in-app reset)

Not a CLI command, but the equivalent. Open [lib/init_dependencies.dart](../lib/init_dependencies.dart), change `bool clearCache = false` to `true`, run the app once. This wipes:
- HydratedBloc storage (UserBloc, ConfigCubit)
- Hive boxes (token, user, last_otp_request, rememberMe, etc.)

**When to use**: Test a clean cold-boot without uninstalling the app from a device.

**REMEMBER**: set it back to `false` before committing.

---

## I. Makefile targets (quick map)

The Makefile bakes in `--no-tree-shake-icons` and FVM detection. Use it when convenient:

| Target | Equivalent raw command |
|---|---|
| `make setup` | `flutter pub get && dart run build_runner build --delete-conflicting-outputs` |
| `make deps` | `flutter pub get` |
| `make codegen` | `dart run build_runner build --delete-conflicting-outputs` |
| `make codegen-watch` | `dart run build_runner watch --delete-conflicting-outputs` |
| `make clean` | `flutter clean && rm -rf .dart_tool build` |
| `make run-parents` | `flutter run -t lib/main.dart --flavor parents` |
| `make run-professors` | `flutter run -t lib/main_professores.dart --flavor professores` |
| `make build-parents-debug` | `flutter build apk -t lib/main.dart --flavor parents --debug` |
| `make build-professors-debug` | `flutter build apk -t lib/main_professores.dart --flavor professores --debug` |
| `make build-parents-apk` | `flutter build apk -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| `make build-professors-apk` | `flutter build apk -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons` |
| `make build-parents-aab` | `flutter build appbundle -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| `make build-professors-aab` | `flutter build appbundle -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons` |
| `make build-parents-ios` | `flutter build ios -t lib/main.dart --flavor parents --release --no-tree-shake-icons` |
| `make build-professors-ios` | `flutter build ios -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons` |
| `make analyze` | `flutter analyze` |
| `make format` | `flutter format lib/` |
| `make outdated` | `flutter pub outdated` |
| `make upgrade` | `flutter pub upgrade` |
| `make ios-pods` | `cd ios && pod install` |
| `make ios-pods-update` | `cd ios && pod update` |
| `make android-clean` | `cd android && ./gradlew clean` |
| `make help` | Print the help menu |

**No Makefile targets exist for `flutter build web` yet** — see §C5 for the recommended commands; add Makefile targets if you'll build web regularly.

---

## J. Quick reference — most-used commands

The 10 commands you'll use 95% of the time:

```powershell
# 1. Verify toolchain
fvm flutter doctor -v

# 2. Install deps
fvm flutter pub get

# 3. Generate code
fvm dart run build_runner build --delete-conflicting-outputs

# 4. List devices
fvm flutter devices

# 5. Run parents (Android/iOS)
fvm flutter run -t lib/main.dart --flavor parents

# 6. Run teachers (Android/iOS)
fvm flutter run -t lib/main_professores.dart --flavor professores

# 7. Run parents on web
fvm flutter run -t lib/main.dart -d chrome --web-port 5173

# 8. Build parents release AAB
fvm flutter build appbundle -t lib/main.dart --flavor parents --release --no-tree-shake-icons

# 9. Build teachers release AAB
fvm flutter build appbundle -t lib/main_professores.dart --flavor professores --release --no-tree-shake-icons

# 10. Analyze
fvm flutter analyze
```

Memorize these and you're 95% productive. Everything else in this doc is for the remaining 5%.

---

## Where to go next

- **Build/run/debug guide (narrative form)**: [DEVELOPMENT.md](DEVELOPMENT.md)
- **Architecture conventions**: [../CLAUDE.md](../CLAUDE.md)
- **Project rules (non-negotiable)**: [../.specify/memory/constitution.md](../.specify/memory/constitution.md)
- **Makefile source of truth**: [../Makefile](../Makefile)
- **Active feature specs**: [../specs/](../specs/)
