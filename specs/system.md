# System Spec

Technical architecture, runtime, and operational practices. See [`../CLAUDE.md`](../CLAUDE.md) §2 for the condensed reference.

## 1. Stack snapshot

- **Flutter** 3.13.6, Dart `>=3.0.5 <4.0.0` (FVM-pinned via [`.fvm/`](../.fvm/))
- **State:** `flutter_bloc` + `hydrated_bloc` (HydratedCubit for `UserBloc`, `ConfigCubit`)
- **DI:** `get_it` singleton in [lib/core/dependency_injection/di.dart](../lib/core/dependency_injection/di.dart); each feature has a `*_di.dart` implementing `DependencyInjection`
- **HTTP:** `dio` with interceptors in [lib/core/network/](../lib/core/network/)
- **Local DB:** `hive` via [lib/core/local_db/](../lib/core/local_db/) (box path `{appDir}/jeel`)
- **Backend:** REST `criarte.filhos.app` + Firebase (Auth, Firestore, Storage, Messaging, Crashlytics)
- **Media:** `image_picker`, `crop_your_image`, `flutter_sound`, `record`, `just_audio`, `video_player`, `appinio_video_player`, `photo_view`
- **Notifications:** `firebase_messaging` + `flutter_local_notifications` + `alarm` (native medicine reminders)
- **Sizing:** `flutter_screenutil` with design size 430×932

## 2. Architecture

Clean-Architecture-flavored, feature-first. Feature layout (variations exist — mirror the closest sibling):

```
lib/features/<name>/
  presentation/
    bloc/   feature_bloc.dart, _event.dart, _state.dart
    widgets/
    *_screen.dart
  data_sources/   feature_repository.dart, feature_impl.dart, feature_di.dart
  models/
```

Shared infrastructure in [lib/core/](../lib/core/) — see CLAUDE.md for the per-subdir table.

## 3. Data flow

```
Screen → Bloc/Cubit → Repository (interface)
                         ↘ Impl → NetworkClient.handleRequest → Dio → REST
                                                                     ↘ Crashlytics on 5xx
                         ↘ LocalDatabaseRepo → Hive
                         ↘ FirebaseFirestore (chat, notifications)
                         ↘ FirebaseStorage (media)
```

Repos return `Either<Failure, T>` (dartz). Blocs map `Failure` to user-facing state.

## 4. Networking conventions

- Base URLs in `lib/core/utils/constants/api_const.dart` (production `https://criarte.filhos.app/api/v1/`).
- [lib/core/network/network_interceptor.dart](../lib/core/network/network_interceptor.dart) injects `Authorization`, `school`/`school_id`, and `lang` headers.
- Dio timeout is 10h intentionally (large uploads). Don't lower without checking media flows.
- 5xx responses are routed to Crashlytics in [lib/core/network/network_client.dart](../lib/core/network/network_client.dart).

## 5. Persistence

- **HydratedBloc** auto-persists `UserBloc` and `ConfigCubit` to `getApplicationDocumentsDirectory()`. Keep `toJson`/`fromJson` round-trippable.
- **Hive box keys:** `token`, `user`, `last_otp_request`, `last_otp_phone`, `rememberMe`, `seenFeaturedEvents`. Use `LocalDatabaseRepo`, not Hive directly.
- `initDependecies(clearCache: true)` wipes both stores — debug aid only.

## 6. Auth & session

- Firebase Auth issues SMS OTP; server returns a long-lived `accessToken` (no refresh flow observed) stored on `UserModel`.
- Logout clears Hive, hydrated storage, and resets `UserBloc`.
- Approval gate: `UserModel.isApproval == false` → route to `your_account_under_review`; a `BackgroundServicesBloc` poll detects approval.

## 7. Real-time & push

- **Firestore** powers chat (1:1 parent↔teacher scoped to a child, group chats teacher-only). It is the source of truth — no parallel REST chat.
- **FCM** delivers announcements, event, and message pushes. Notification payload carries `eventable_id` + `eventable_type` for deep-linking.
- **Local notifications** are used for in-app foreground display.
- **Native alarms** (via `alarm` package + [lib/core/custom_packages/](../lib/core/custom_packages/) wrapper) handle medicine reminders so they survive app kill.

## 8. Flavors

- Declared in `android/app/build.gradle` (dimension `flavors`, products `parents` / `professores`).
- iOS flavors mirrored via [ios/](../ios/) schemes.
- Runtime: `AppFlavor` `InheritedWidget` in [lib/flavors/app_flavors.dart](../lib/flavors/app_flavors.dart); branch on `context.isParents` / `context.isProfessors`.
- Server `role` is derived from flavor at login — [lib/features/login/data_sources/login_impl.dart:30](../lib/features/login/data_sources/login_impl.dart#L30).

## 9. Build & release

```bash
# Run
flutter run -t lib/main.dart            --flavor parents
flutter run -t lib/main_professores.dart --flavor professores

# Launcher icons & splash (per flavor)
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml

# Release
flutter build appbundle --flavor parents      -t lib/main.dart
flutter build appbundle --flavor professores  -t lib/main_professores.dart
```

Version source of truth: [pubspec.yaml](../pubspec.yaml) `version:` line.

## 10. Observability

- **Crashlytics** initialised in [lib/init_dependencies.dart](../lib/init_dependencies.dart). 5xx responses are reported automatically by the network layer.
- No structured analytics SDK is wired in today.
- Debug logging via `lib/core/utils/print.dart` — gated; avoid `print` directly.

## 11. Known operational risks

- **Single base URL constant** plus a few "old/new/newest" experimental URLs in `api_const.dart` — pruning needed.
- **No automated tests** (no `test/` directory in features). Refactors are eyes-only.
- **`build_runner` is a dev dep** but no generators are currently active — leftover from a prior plan.
- **`dependency_overrides`** for `http` and `package_info_plus` indicate version-resolution friction; revisit on upgrade.

---

## Tasks

### Architecture hygiene
- [ ] [both] Audit `lib/features/*` for the layout template — file an issue listing features that deviate (e.g., `home/bloc/` at root, missing `data_sources/`). Either normalize or accept the variation in writing.
- [ ] [both] Decide whether to keep `dartz` `Either<Failure, T>` everywhere or migrate to `Result`/sealed classes; document the chosen approach.
- [ ] [both] Confirm all feature DI files are wired via `initDependecies()`; flag any that self-register at import time.

### Networking
- [ ] [both] Remove unused base URL experiments from `api_const.dart` or move them under a debug-only switch.
- [ ] [both] Review the 10-hour Dio timeout: split into separate values for media uploads vs. JSON endpoints if possible.
- [ ] [both] Centralize endpoint paths (currently scattered string literals) into a typed `Endpoints` class.

### Persistence
- [ ] [both] Add a Hive migration strategy: bump a `schemaVersion` on every box-key change so old installs don't crash.
- [ ] [both] Verify `UserModel.toJson`/`fromJson` covers every field after recent additions — write a round-trip test.

### Auth & session
- [ ] [both] Investigate whether the server supports a token refresh endpoint; if so, implement refresh interceptor; if not, document expiry behaviour.
- [ ] [both] Ensure every deep-link / push entry point checks `isApproval` before routing (audit `navigatorKey` usages).

### Real-time & push
- [ ] [both] Add a Firestore security-rules review to the release checklist; rules govern chat reads/writes.
- [ ] [both] Document the FCM payload contract (`eventable_id`, `eventable_type`, supported types) in a code-level doc.
- [ ] [parents] Confirm medicine alarms survive app-kill on iOS 17+ and Android 14 background restrictions.

### Build & CI
- [ ] [both] Add CI that builds both flavors on every PR (currently no CI workflow files committed).
- [ ] [both] Pin Flutter version via FVM in CI (`.fvm/fvm_config.json`) to avoid drift.
- [ ] [both] Sign release builds in CI with secrets pulled from a vault, not local keystores.

### Testing
- [ ] [both] Add at least smoke tests for `UserBloc`, `ConfigCubit`, and `NetworkClient.handleRequest`.
- [ ] [both] Add a widget test for the approval gate routing.

### Observability
- [ ] [both] Decide on analytics SDK (Firebase Analytics is the path of least resistance given existing Firebase deps).
- [ ] [both] Add a release-notes generator from git log to ease store submission.

### Dependency health
- [ ] [both] Resolve the `http` / `package_info_plus` `dependency_overrides` — upgrade or document why they're pinned.
- [ ] [both] Remove `build_runner` if no generators are in use, or add the generator that's expected.
