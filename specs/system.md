# System Spec

Technical architecture, runtime, and operational practices. See [`../CLAUDE.md`](../CLAUDE.md) §2 for the condensed reference and [MIGRATION.md](MIGRATION.md) for the per-feature trio index.

> **Status (2026-05-15):** Rewritten from the per-feature trios under [specs/](.). Cross-cutting findings from those migrations are folded into §12 (Cross-feature findings). For per-feature implementation detail, the source of truth is the trio's `plan.md`.

## 1. Stack snapshot

- **Flutter** 3.29.3, Dart `>=3.0.5 <4.0.0` (FVM-pinned via [`.fvmrc`](../.fvmrc) — no `.fvm/` directory in repo)
- **State:** `flutter_bloc` + `hydrated_bloc` (HydratedCubit for [UserBloc](../lib/core/user/bloc/user_bloc.dart), [ConfigCubit](../lib/core/config/cubit/cubit.dart))
- **DI:** `get_it` — three patterns in use (see §12.1):
  - Feature-root `feature_di.dart` files implementing `DependencyInjection` (the canonical pattern in `login`, `chat`, etc.)
  - Sibling-co-located `data_sources/<feature>_di.dart`
  - Central registration inline in [init_dependencies.dart](../lib/init_dependencies.dart) (used by `search_for_filter`, `featured_events`, `gallery_images`, `terms_and_condtions`)
- **HTTP:** `dio` with interceptors in [lib/core/network/](../lib/core/network/)
- **Local DB:** `hive` via [lib/core/local_db/](../lib/core/local_db/) (box path `{appDir}/jeel`; sentinel `web` on Flutter web)
- **Backend:** REST `criarte.filhos.app` + Firebase (Auth, Firestore, Storage, Messaging, Crashlytics, App Check)
- **Media:** `image_picker`, `crop_your_image`, `flutter_sound` + `record` (audio messages), `just_audio`, `video_player` (stock), `photo_view`
  - `appinio_video_player_plus` removed 2026-05-14 due to `ui.platformViewRegistry` break in Flutter 3.27+
- **Notifications:** `firebase_messaging` + `flutter_local_notifications` + `alarm` (native medicine reminders)
- **Sizing:** `flutter_screenutil` with design size 430×932
- **Brazilian-specific:** `brasil_fields` (CPF/CEP/phone), `search_cep`
- **Web canvas:** mobile-sized canvas (430×932) on desktop browsers is implemented via CSS in [web/index.html](../web/index.html) — applies to `body > *` so `FlutterView` reports the right canvas size

## 2. Architecture

Clean-Architecture-flavored, feature-first. Feature layout (variations exist — mirror the closest sibling):

```text
lib/features/<name>/
  presentation/
    bloc/   feature_bloc.dart, _event.dart, _state.dart
    widgets/
    *_screen.dart
  data_sources/   feature_repository.dart, feature_impl.dart, feature_di.dart
  models/
```

Variations encountered during the 2026-05-15 migrations are catalogued in §12.2. Shared infrastructure in [lib/core/](../lib/core/) — see CLAUDE.md for the per-subdir table.

## 3. Data flow

```text
Screen → Bloc/Cubit → Repository (interface)
                         ↘ Impl → NetworkClient.handleRequest → Dio → REST
                                                                     ↘ Crashlytics on 5xx (redacted bodies/headers)
                         ↘ LocalDatabaseRepo → Hive
                         ↘ FirebaseFirestore (chat, notifications)
                         ↘ FirebaseStorage (chat media, prescriptions)
```

Repos return `Either<Failure, T>` (dartz). Blocs map `Failure` to user-facing state.

## 4. Networking conventions

- Base URLs in [lib/core/utils/constants/api_const.dart](../lib/core/utils/constants/api_const.dart) (production `https://criarte.filhos.app/api/v1/`).
- [lib/core/network/network_interceptor.dart](../lib/core/network/network_interceptor.dart) injects `Authorization`, `school` / `school_id`, and `lang` headers.
- Dio timeouts as of 2026-05-14: 20 s connect / 30 s receive / 60 s send. (Was previously 10 h for large uploads.)
- 5xx responses are routed to Crashlytics in [lib/core/network/network_client.dart](../lib/core/network/network_client.dart) with `_redactHeaders` + `_redactBody` stripping `Authorization`, CPF, phone, medication payloads.
- 401 responses force `UserBloc.loggedOut()` via the interceptor (re-entrancy-guarded, once per session).

### 4.1 Known endpoint contract bugs (from migrations)

- **`add_form` announcement endpoint** has a double `/api/v1/` prefix — `/api/v1/teacher/announcements` is written full, but `NetworkClient` already prepends the base URL ([add_form/tasks.md](add_form/tasks.md) T-fix-N).
- **`add_address` POST body** writes `"city"` twice — `region_id` silently overwrites Brazil's `city` text in the same JSON object ([add_address/tasks.md](add_address/tasks.md)).
- **`settings/medicines` `rejectRequest`** sends `reason` via `queryParameters` rather than the body and silently drops the `attachments` argument ([settings/medicines/tasks.md](settings/medicines/tasks.md)).
- **`search`** always hits the *teacher* endpoint regardless of flavor; `ProfessorSearch` event/handler exist but aren't dispatched ([search/tasks.md](search/tasks.md)).
- Multiple repos still construct fresh `Dio()` instances bypassing interceptors — known cases: `diary/presentation/widgets/gallery_media/share_button.dart:87` and a few others ([diary/tasks.md](diary/tasks.md) P1).

### 4.2 Stub / fake-data layers

Production code currently returns fake data from two repos. These must be wired before release:

- **`GalleryRepo.getGalleryImages`** — returns hardcoded `cataas.com` cat-meme URLs after a 1-second `Future.delayed`; real `NetworkClient.handleRequest` block is commented out ([gallery_images/tasks.md](gallery_images/tasks.md)).
- **`AboutRepo.getAbout`** — REST call commented out; the screen's `email` / `phone` rows are guarded by `validString(...)` which is always false ([settings/about/tasks.md](settings/about/tasks.md)).
- **`gallery` settings entry** is wrapped in `if(false)` at [settings_screen.dart:144](../lib/features/settings/settings_screen.dart#L144) so the surface is unreachable in production even though the screen renders.

## 5. Persistence

- **HydratedBloc** auto-persists `UserBloc` and `ConfigCubit` to `getApplicationDocumentsDirectory()`. Keep `toJson` / `fromJson` round-trippable. On web, `HydratedStorageDirectory.web` is used (IndexedDB).
- **Hive box keys:** `token`, `user`, `last_otp_request`, `last_otp_phone`, `rememberMe`, `seenFeaturedEvents`. Access through [LocalDatabaseRepo](../lib/core/local_db/local_db_repo.dart), not Hive directly.
- `initDependencies(clearCache: true)` wipes both stores — debug aid only.
- Web: `LocalDatabaseRepo.dbPath()` returns the literal `'web'` sentinel; Hive uses IndexedDB transparently.

### 5.1 Unused-but-injected dependencies

The following blocs inject `LocalDatabaseRepo` but never use it — placeholder slots for "persist last X" features that were planned but not implemented. Surfaced during migrations:

- [home/bloc/home_bloc.dart](../lib/features/home/bloc/home_bloc.dart)
- [search_for_filter/bloc/](../lib/features/search_for_filter/bloc/)
- [settings/announcements/](../lib/features/settings/announcements/)

## 6. Auth & session

- Firebase Auth issues SMS OTP; server returns a long-lived `accessToken` (no refresh flow observed) stored on `UserModel`.
- Logout clears Hive, hydrated storage, calls `FirebaseMessaging.instance.deleteToken()` and resets `UserBloc` via `_signOutCleanup()`.
- **`UserBloc.deleteAccount()` aliases to `_signOutCleanup()`** — local logout only, no server-side erasure. LGPD-relevant; tracked in [settings/tasks.md](settings/tasks.md) and [business.md §6](business.md#6-compliance--sensitive-data-lgpd).
- Approval gate: `UserModel.isApproval == false` → route to `your_account_under_review`. A poll in `BackgroundServicesBloc` detects approval; **wake-up is mount-driven only**, so a pending user must keep returning to the screen to re-poll ([background_services/tasks.md](background_services/tasks.md)).
- Server-side `revoke_device_token` endpoint pending — coordinate with backend. Tracked in [features.md cross-feature tasks](features.md#cross-feature-tasks).

## 7. Real-time & push

- **Firestore** powers chat (1:1 parent↔teacher scoped to a child, group chats teacher-only) — source of truth, no parallel REST chat. Schema and storage paths documented in [chat/plan.md](chat/plan.md).
  - Outstanding: switch from asymmetric `chat/{senderId}/{receiverId}/...` storage paths to symmetric `conversations/{conversationId}/...`; re-enable offline persistence (currently disabled in [init_dependencies.dart](../lib/init_dependencies.dart)).
- **FCM** delivers announcements, event, and message pushes. Notification payload carries `eventable_id` + `eventable_type` for deep-linking; unknown `type` falls back to the in-app inbox (fixed 2026-05-14).
- **Local notifications** are used for in-app foreground display.
- **Native alarms** (via `alarm` package + [lib/core/custom_packages/](../lib/core/custom_packages/) wrapper) handle medicine reminders so they survive app kill. Foreground service + `SCHEDULE_EXACT_ALARM` + `USE_FULL_SCREEN_INTENT` permissions declared 2026-05-14. iOS 17+ / Android 14 survival **unverified**.
- **`NotificationService.configureNotifications` is non-idempotent** — re-mount likely leaks `onTokenRefresh` subscriptions ([background_services/tasks.md](background_services/tasks.md)).

## 8. Flavors

- Declared in `android/app/build.gradle` (dimension `flavors`, products `parents` / `professores`).
- iOS flavors mirrored via [ios/](../ios/) schemes; bundle IDs `com.algoriza.criarte` / `com.algoriza.profecriarte` (fixed 2026-05-14 from legacy `disneyNew`).
- Runtime: `AppFlavor` `InheritedWidget` in [lib/flavors/app_flavors.dart](../lib/flavors/app_flavors.dart); branch on `context.isParents` / `context.isProfessors`.
- Pre-login (where no `BuildContext` is yet available), use the process-wide `isProfessorsFlavor` / `isCurrentUserProfessor` / `isCurrentUserParent` helpers in [lib/core/user/current_role.dart](../lib/core/user/current_role.dart) — set by `main*.dart` before `runApp`. The legacy `mainKey.currentContext?.isProfessors` pattern was removed across 18 sites in two passes (2026-05-14).
- Server `role` is derived from flavor at login — [login_impl.dart:30](../lib/features/login/data_sources/login_impl.dart#L30).

## 9. Build & release

```bash
# Run
flutter run -t lib/main.dart             --flavor parents
flutter run -t lib/main_professores.dart --flavor professores

# Launcher icons & splash (per flavor)
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml

# Release (native)
flutter build appbundle --flavor parents      -t lib/main.dart
flutter build appbundle --flavor professores  -t lib/main_professores.dart

# Web (--no-tree-shake-icons is required — non-const IconData uses in the codebase)
flutter build web --no-tree-shake-icons -t lib/main.dart
flutter build web --no-tree-shake-icons -t lib/main_professores.dart
```

Version source of truth: [pubspec.yaml](../pubspec.yaml) `version:` line.

### 9.1 Web

- Web shell exists at [web/index.html](../web/index.html); a CSS rule on `body > *` constrains the canvas to 430×932 on viewports ≥ 601 px.
- `--no-tree-shake-icons` is required (non-const `IconData` invocations would otherwise fail the analyzer at build time).
- Six external steps still required for full web functionality (Firebase Web App registration, FCM VAPID + service worker, OAuth web client IDs, App Check reCAPTCHA, backend CORS, phone-auth reCAPTCHA Enterprise) — tracked in [web-setup.md](web-setup.md).

## 10. Observability

- **Crashlytics** initialised in [init_dependencies.dart](../lib/init_dependencies.dart). 5xx responses reported automatically (with `_redactHeaders` + `_redactBody`).
- **App Check** activated in release builds on non-web platforms (`AndroidProvider.playIntegrity`).
- No structured analytics SDK is wired today. Firebase Analytics is the path of least resistance given existing Firebase deps.
- Debug logging via `lib/core/utils/print.dart` — gated; avoid `print` directly.
- ~146 `print` / `debugPrint` calls across the codebase should be routed through a logger that drops in release ([features.md cross-feature tasks](features.md#cross-feature-tasks) P1).

## 11. Known operational risks

- **Single base URL constant** plus a few "old/new/newest" experimental URLs in `api_const.dart` — pruning needed.
- **No automated tests** (no `test/` directory in features). Refactors are eyes-only.
- **`build_runner` is a dev dep** but no generators are currently active — leftover from a prior plan.
- **`dependency_overrides`** for `http` and `package_info_plus` indicate version-resolution friction; revisit on upgrade.
- **`disney.filhos.app` / `disney-d2bd5` Firebase project** still referenced in code config files while business documentation says `criarte.filhos.app` / `escola-cede2` — reconcile.

## 12. Cross-feature findings (from 2026-05-15 migration sweep)

### 12.1 DI pattern variations

Three patterns are in use simultaneously. The canonical pattern (per [system.md §2](#2-architecture) and [CLAUDE.md §2.2](../CLAUDE.md#22-architecture)) is feature-root `*_di.dart`. Deviations:

| Feature | DI location | Notes |
|---|---|---|
| `featured_events`, `gallery_images`, `terms_and_condtions` | Central inline in `init_dependencies.dart` | No feature-root DI file |
| `search_for_filter` | Central inline at [init_dependencies.dart:86](../lib/init_dependencies.dart#L86) | No feature-root DI file |
| `register` | None — registered alongside `LoginBloc` in [login/login_di.dart](../lib/features/login/login_di.dart) | Shares `LoginRepository`; intentional |
| `add_form` | `data_sources/` (the only DI for it) | Mirrors the canonical layout |

Decision pending: normalize or formally accept the variation in the constitution.

### 12.2 Layout variations

- `home`, `featured_events`, `gallery_images`, `background_services`, `select_attendants`, `attendants_selection` — bloc/screen at feature root with no `presentation/` wrapper.
- `add_form` uses `repo/` instead of the canonical `data_sources/`.
- `my_addresses` repo field is named `eventForUserEndpoint` (leftover from an events template).
- `terms_and_condtions` folder name has a typo (`condtions`) — coordinated rename pending.

### 12.3 Catch-all bloc handlers (anti-pattern — `on<FeatureEvent>`)

Several blocs use a single catch-all handler that fans out via `switch` on the event type, defeating bloc-test ergonomics and event-by-event concurrency strategy (`droppable`, `restartable`):

- [chat_bloc.dart:44-70](../lib/features/chat/presentation/bloc/chat_bloc.dart#L44-L70)
- [diary_bloc.dart:38-54](../lib/features/diary/presentation/bloc/diary_bloc.dart#L38-L54)
- `home_bloc`, `search_bloc`, `all_children_bloc`, `background_services_bloc`

Tracked as P1 in each feature's `tasks.md`.

### 12.4 Recurring code-quality drift

| Pattern | Where (sample) | Tracked in |
|---|---|---|
| Hardcoded `Color(0xff...)` / `Colors.white` | splash, your_account_under_review, choose_language, featured_events, all_children, main, settings shell | per-feature tasks.md; [features.md cross-feature tasks](features.md#cross-feature-tasks) P2 |
| Stray `print` / `debugPrint` | add_address, my_addresses, search, settings/about, settings/events, settings/edit_profile, featured_events, add_medicine | features.md cross-feature P1 |
| Dead code (commented-out blocks, commented `if(false)` gates, vestigial enums/models/events) | settings shell, my_addresses, all_children, add_address, settings/medicines (parents repo), featured_events_screen_old.dart | per-feature tasks.md |
| Cross-feature absolute imports | many | features.md cross-feature P1 (lint rule pending) |
| `bottom_navy_bar` in pubspec, never imported | `main` (actual nav is hand-rolled `CustomBottomNavigation`) | main/tasks.md |

### 12.5 Cross-feature coupling smells

- [settings/events](settings/events/) reaches into [home/widgets/event_item.dart](../lib/features/home/widgets/event_item.dart).
- [your_account_under_review](your_account_under_review/) reaches into `splash/widgets/logo_back_ground.dart`.
- [attendants_selection](attendants_selection/) reaches into [DiaryBloc + SearchBloc](../lib/features/) internals — couples a generic picker to diary state.
- Add a lint rule preventing cross-feature absolute imports ([features.md cross-feature tasks](features.md#cross-feature-tasks)).

### 12.6 Stub / fake-data surfaces

See §4.2 — `gallery`, `gallery_images`, `settings/about`. None can ship to production without backend wiring.

### 12.7 Naming-collision blocker

`select_attendants/` and `attendants_selection/` both exist, both are placeholder/scaffold-only, and neither is wired. Must resolve before any event-RSVP / QR-pickup feature can ship. Decisions to make:

1. Children-picker or guardians-picker?
2. Which folder name survives?
3. Delete the other.

Tracked in [select_attendants/tasks.md](select_attendants/tasks.md), [attendants_selection/tasks.md](attendants_selection/tasks.md), and [business.md §11](business.md#11-production-blocking-surfaces-must-fix-before-next-release).

---

## Tasks

### Architecture hygiene
- [ ] [both] Decide canonical DI pattern and migrate the central-inline registrations to feature-root `*_di.dart` (or formally accept the variation in the constitution). See §12.1.
- [ ] [both] Audit `lib/features/*` for the layout template; either normalize §12.2 deviations or accept them in writing.
- [ ] [both] Decide whether to keep `dartz` `Either<Failure, T>` everywhere or migrate to `Result` / sealed classes; document.
- [ ] [both] Add a lint rule preventing cross-feature absolute imports (124+ today).
- [ ] [both] Add a lint rule preventing `mainKey.currentContext?.isParents/isProfessors` regressions.

### Networking
- [ ] [both] Fix the four endpoint contract bugs in §4.1 (`add_form` double-prefix, `add_address` duplicate `city`, `medicines.rejectRequest`, `search` flavor-incorrect endpoint).
- [ ] [both] Wire the stub repos in §4.2 (`GalleryRepo`, `AboutRepo`) and remove the `if(false)` gate on the gallery settings entry.
- [ ] [both] Remove unused base URL experiments from `api_const.dart` or move them under a debug-only switch.
- [ ] [both] Centralize endpoint paths (currently 20+ scattered string literals) into a typed `Endpoints` class.
- [ ] [both] Switch base URL via `--dart-define API_BASE_URL=` and remove legacy URLs.
- [ ] [both] Ban fresh `Dio()` construction in repos — they bypass interceptors. Known offenders: `diary/.../share_button.dart`.

### Persistence
- [ ] [both] Add a Hive migration strategy: bump a `schemaVersion` on every box-key change.
- [ ] [both] Verify `UserModel.toJson` / `fromJson` covers every field — write a round-trip test.
- [ ] [both] Remove unused `LocalDatabaseRepo` injections (§5.1) or wire them.

### Auth & session
- [ ] [both] Investigate whether the server supports a token-refresh endpoint; if so, implement a refresh interceptor; if not, document expiry behaviour.
- [ ] [both] Make `UserBloc.deleteAccount()` trigger actual server-side LGPD-Art.18 erasure (currently aliased to local logout).
- [ ] [both] Coordinate the backend `revoke_device_token` endpoint and call it from `_signOutCleanup` before `NotificationService.clearToken()`.
- [ ] [both] Ensure every deep-link / push entry point checks `isApproval` before routing (audit `navigatorKey` usages).
- [ ] [both] Promote `BackgroundServicesBloc` approval polling to a timer-driven loop (currently mount-only).

### Real-time & push
- [ ] [both] Re-enable Firestore offline persistence and move chat storage paths to symmetric `conversations/{conversationId}/...`.
- [ ] [both] Make `NotificationService.configureNotifications` idempotent (cancel previous `onTokenRefresh` subscription before re-subscribing).
- [ ] [both] Document the FCM payload contract (`eventable_id`, `eventable_type`, supported types).
- [ ] [both] Add a Firestore security-rules review to the release checklist.
- [ ] [parents] Verify medicine alarms survive app-kill on iOS 17+ and Android 14.

### Build & CI
- [ ] [both] Add CI that builds both flavors on every PR (currently no CI workflow files committed).
- [ ] [both] Pin Flutter version via FVM in CI (`.fvmrc` already pins 3.29.3) to avoid drift.
- [ ] [both] Sign release builds in CI with secrets pulled from a vault, not local keystores.
- [ ] [both] Document the `--no-tree-shake-icons` requirement until non-const `IconData` uses are cleaned up.
- [ ] [both] Complete the six external web-setup steps in [web-setup.md](web-setup.md) and document the result.

### Testing
- [ ] [both] Add at least smoke tests for `UserBloc`, `ConfigCubit`, and `NetworkClient.handleRequest`.
- [ ] [both] Add a widget test for the approval gate routing.
- [ ] [both] Add per-feature smoke tests (open screen, render, no exception) once the testing baseline exists.
- [ ] [both] Add an integration test for `your_account_under_review` covering splash, OTP success, and push-tap from terminated state.

### Observability
- [ ] [both] Decide on analytics SDK (Firebase Analytics is the path of least resistance).
- [ ] [both] Route ~146 `print` / `debugPrint` calls through a single logger that drops in release.
- [ ] [both] LGPD audit pass on Crashlytics breadcrumbs in staging to confirm redaction is comprehensive.

### Dependency health
- [ ] [both] Resolve the `http` / `package_info_plus` `dependency_overrides` — upgrade or document why they're pinned.
- [ ] [both] Remove `build_runner` if no generators are in use, or add the generator that's expected.
- [ ] [both] Replace abandoned packages: `image_gallery_saver`, `quill_html_editor`, `flutter_custom_theme`, `separated_column` / `separated_row`. Remove unused: `flutter_sound`, `audio_session`, `bottom_navy_bar`. Audit: `flash`, `crop_your_image`, `dotted_border`.
- [ ] [both] Bump 1–3-major-behind: `image_picker`, `permission_handler`, `firebase_*`, `intl`, `alarm`, `flutter_lints`.

### Stub / blocker resolution
- [ ] [both] Resolve `select_attendants` vs `attendants_selection` collision (§12.7). Blocks events, RSVPs, QR-pickup.
- [ ] [both] Wire `GalleryRepo` to the real `gallery` endpoint and remove the `cataas.com` placeholder + `if(false)` gate.
- [ ] [both] Wire `AboutRepo.getAbout()` so contact rows render.

### Hygiene tracked elsewhere
For analyzer settings, lint rule enabling, package upgrades, license/readme/contributing, i18n key sync, see [features.md cross-feature tasks](features.md#cross-feature-tasks). Those are not per-feature migration concerns.
