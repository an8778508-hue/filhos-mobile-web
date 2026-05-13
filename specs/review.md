# Multi-Expert Review (2026-05-13)

Consolidated findings from four parallel expert reviews:

- **Flutter** — pubspec, blocs, widgets, screenutil, async safety, init/DI, lints, theming
- **Mobile platform** — Android manifest/permissions, iOS Info.plist/privacy manifest, FCM, alarms, ATT, store readiness
- **Backend integration** — REST contract, auth flow, Firestore usage, FCM payloads, data parsing, error UX, offline behavior, PII
- **Full-stack / DevOps** — repo hygiene, CI/CD, secrets, compliance, testing, observability, docs

Each finding is tagged with a **priority** and an **area / feature**. Feature-scoped tasks are also mirrored into [features.md](features.md) under the matching feature.

---

## 0. Executive summary — what must change before next release

| # | Finding | Area | Source |
|---|---------|------|--------|
| 1 | **Android upload keystore + plaintext password `123456` are committed to GitHub.** Keystore is permanently in git history. Treat as compromised; rotate via Play Console; scrub history. | security | DevOps |
| 2 | **iOS `PRODUCT_BUNDLE_IDENTIFIER` is `com.algoriza.disneyNew` / `com.algoriza.profedisneyNew`** across `project.pbxproj` while Firebase plists and intended store identity use `com.algoriza.criarte` / `…profecriarte`. FCM token registration fails on iOS and the app cannot be submitted under the stated identity. | iOS | Mobile |
| 3 | **No `PrivacyInfo.xcprivacy` manifest** — Apple has required this since May 2024 for apps using "required reason APIs" (UserDefaults, file timestamps, system boot time, network APIs). App Store will reject. | iOS | Mobile |
| 4 | **Android `targetSdkVersion` is implicit (`flutter.targetSdkVersion`)** → resolves to 33 on the toolchain in use. Play Store rejects uploads with target SDK < 34 since Aug 2024 (35 since Aug 2025). | Android | Mobile |
| 5 | **No `POST_NOTIFICATIONS` permission** declared → push silently never appears on Android 13+. | Android push | Mobile |
| 6 | **`google-services` Gradle plugin not applied**; per-flavor `google-services.json` is ignored. Both flavors register against the parents Firebase app. Crashlytics symbols not uploaded. | Firebase | Mobile |
| 7 | **`alarm` package will crash on Android 14** (no `FOREGROUND_SERVICE_*` permission/type declared) and exact alarms silently demote (no runtime check on `SCHEDULE_EXACT_ALARM`, no `USE_EXACT_ALARM` fallback). Medicine reminders break. | alarms | Mobile |
| 8 | **ATT prompt fires on the language picker** (Apple Guideline 5.1.2 rejection vector) and is never re-fired for returning users. | iOS privacy | Mobile |
| 9 | **Dio timeouts set to 10 HOURS** for connect/receive/send. Any network blip hangs the UI indefinitely. | network | Flutter / Backend |
| 10 | **No auto-logout on 401**; the app wedges in a half-authenticated state forever after token expiry. | auth | Backend |
| 11 | **Chat messages are not ordered or paginated**; doc IDs and timestamps come from the device clock. Out-of-order messages, ID collisions, unbounded reads. | chat | Backend |
| 12 | **`Question.fromJson` throws on unknown type** → any backend-added diary question type breaks the entire diary screen for all clients. Same risk pattern in `Message.fromJson` and `ChildModel.fromJson` (`'age('` typo). | diary, chat | Backend |
| 13 | **FCM token not cleared / re-registered on logout or rotation.** Push intended for a previous user is delivered to the next user on the same device — LGPD cross-account leak. | notifications, LGPD | Backend |
| 14 | **Crashlytics 500 reports include full `Authorization` headers, request bodies (CPF, phone, medication info).** LGPD violation. | observability, LGPD | Backend |
| 15 | **`mainKey.currentContext!.isParents`** is force-unwrapped in 15+ repo/bloc sites for endpoint selection. Background isolates / early calls → NPE crash. Flavor/role should come from `UserBloc` state, not a widget key. | core, chat, home, settings | Flutter / Backend |
| 16 | **No CI/CD, zero tests, no release tags.** 28 features merge straight to main with no automated guardrails. | CI, testing | DevOps |

Everything below expands these and lists the rest.

---

## 1. Security & compliance

### P0
- [ ] **Rotate the Android upload signing key.** `android/key.keystore` + `android/key.properties` (passwords `123456`) are committed to the public GitHub remote. The earlier "remove keystore from git tracking" commit did not work — files are still tracked on the current branch and are permanently in git history. Use Play Console → Use Play App Signing → reset upload key, then `git rm --cached`, `git filter-repo` to scrub history, force-push, and store the new keystore as a CI secret only.
- [ ] **Add `**/key.properties`, `**/*.keystore`, `**/*.jks`, `*.p12`, `*.mobileprovision`, `.env*` to root [.gitignore](../.gitignore).** The current root ignore doesn't cover these; only `android/.gitignore` (added late) does.
- [ ] **Move Firebase config out of source control.** `android/app/google-services.json`, the per-flavor copies, and `ios/config/{parents,professores}/GoogleService-Info.plist` should be CI-injected from secrets. Enable Firebase App Check to mitigate token-spoofing now that these IDs have leaked.
- [ ] **Remove dev/staging base URLs from `lib/core/utils/constants/api_const.dart`.** Four URLs ship in every binary (`escola.spotlayer.com`, `platform.filhos.app`, `beta.filhos.app`, prod). Switch via `--dart-define` per flavor.
- [ ] **Stop logging Authorization + request bodies in Crashlytics.** [lib/core/network/network_client.dart:175-177](../lib/core/network/network_client.dart#L175-L177) sends headers and body as the `reason` on every 500. Redact `Authorization`, strip CPF / `cpf_num` / phone / medication keys, or log only URL + method + status.
- [ ] **ATT prompt: move out of language picker.** [lib/features/choose_language/presentation/choose_language_screen.dart:63-72](../lib/features/choose_language/presentation/choose_language_screen.dart#L63-L72) calls `requestTrackingAuthorization` before the user has any privacy context. Prompt after onboarding or before any tracking SDK initializes; ensure returning users (who skip the language picker) also get prompted once.
- [ ] **iOS `PrivacyInfo.xcprivacy` manifest is missing.** Required by Apple since May 2024 for apps using `UserDefaults`, file timestamps via `path_provider`, system boot time via `device_info_plus`, and network APIs. Add it under [ios/Runner/](../ios/Runner/).
- [ ] **In-app data export missing.** Account deletion path exists ([lib/features/settings/settings_screen.dart:240-254](../lib/features/settings/settings_screen.dart#L240-L254)); LGPD Art. 18 II also requires data export. Add an "Export my data" path.
- [ ] **Drop unused iOS privacy strings.** `Info-{parents,professores}.plist` declare `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`, and location strings that no code uses. Apple has rejected apps in 2024 audits for unused strings.

### P1
- [ ] Add `LICENSE` to the repo.
- [ ] Add `SECURITY.md` with a disclosure email.
- [ ] Audit Crashlytics breadcrumbs across the codebase for any child name / photo URL / medication info.

---

## 2. CI / CD / release engineering

### P0
- [ ] **Add a CI pipeline.** No `.github/workflows/`, `fastlane/`, `codemagic.yaml`, `bitrise.yml`, or `.gitlab-ci.yml` exists. Minimum: format, `flutter analyze`, `flutter test`, build APK+AAB per flavor, build iOS archive per scheme. Inject keystore + Firebase configs from CI secrets.
- [ ] **Pin Flutter via FVM in CI.** `.fvm/` is committed; lock the version in CI to avoid drift.

### P1
- [ ] **Tag releases per flavor** (e.g. `parents-1.0.30+31`, `professores-1.0.30+31`). Currently `git tag` returns nothing.
- [ ] **Add `CHANGELOG.md`**, ideally generated from Conventional Commits.
- [ ] **Document a hotfix branching strategy.**
- [ ] **Make iOS `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` inherit from `Generated.xcconfig`** instead of the hardcoded `1.0.27` / `1` in `project.pbxproj` (currently ships stale version metadata on iOS).

---

## 3. Testing

### P0
- [ ] **There are no tests in this project.** No `test/`, no `integration_test/`, no `*_test.dart`. `flutter_test` is in dev deps but unused. Start with:
  - [ ] Bloc tests for `UserBloc` (login / logout / hydration round-trip).
  - [ ] Bloc tests for `ConfigCubit` (translation/styling rehydration).
  - [ ] Unit tests for `NetworkClient.handleRequest` (200/4xx/5xx/timeout paths).
  - [ ] Widget test for the **approval gate** (`isApproval == false` routes correctly from splash, OTP, and push tap).
  - [ ] Round-trip test for `UserModel.toJson` / `fromJson`.

### P1
- [ ] Add at least smoke tests per feature (open screen, render, no exception) once a testing baseline exists.
- [ ] Golden tests for shared components in `lib/core/components/`.

---

## 4. Android native

### P0
- [ ] **Pin `targetSdkVersion 34` (or 35)** in [android/app/build.gradle:62](../android/app/build.gradle#L62) — currently `flutter.targetSdkVersion` resolves to 33 on the toolchain in use; Play Store rejects new uploads below 34 since Aug 2024.
- [ ] **Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`** to [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml). Without it, runtime requests in `notifications_service.dart` silently no-op on API 33+ and pushes never appear.
- [ ] **Apply the `google-services` Gradle plugin** in [android/build.gradle](../android/build.gradle) and [android/app/build.gradle](../android/app/build.gradle) so the per-flavor `google-services.json` is actually picked up. Today both flavors register against the parents app from `firebase_options.dart`.
- [ ] **Apply `com.google.firebase.crashlytics` plugin and configure symbol upload.** Currently crashes ship unsymbolicated.
- [ ] **Declare a foreground service for the `alarm` package** — add `FOREGROUND_SERVICE`, the appropriate `FOREGROUND_SERVICE_*` type permission, and a `<service ... foregroundServiceType=...>` element. Android 14 throws `ForegroundServiceTypeException` otherwise. Add `USE_FULL_SCREEN_INTENT` for API 34+.
- [ ] **Gate `SCHEDULE_EXACT_ALARM` at runtime** (`AlarmManager.canScheduleExactAlarms()`) before calling `Alarm.set` ([lib/core/utils/alarm_manager/alarm_manager.dart:90](../lib/core/utils/alarm_manager/alarm_manager.dart#L90)). Add `USE_EXACT_ALARM` fallback (auto-granted on API 33+ with Play policy declaration). Otherwise medicine reminders silently demote to inexact.

### P1
- [ ] Add `proguard-rules.pro` and audit R8 keep rules for Hive, Firebase, just_audio. `proguardFiles` in `build.gradle:69,73` references a file that doesn't exist.
- [ ] Add `android.nonTransitiveRClass=true` and `android.enableR8.fullMode=true` to [android/gradle.properties](../android/gradle.properties).
- [ ] Remove `enableOnBackInvokedCallback="true"` from the manifest or upgrade Flutter — on 3.13 the framework doesn't support predictive back, so back gestures jank on Android 14.
- [ ] Bump AGP (7.3.0 → 7.4+) and Kotlin (1.7.10 → 1.8+) before bumping `targetSdk`.

### P2
- [ ] Replace `flavorDimensions "flavors"` with `flavorDimensions += "flavors"` for AGP 8 compatibility.

---

## 5. iOS native

### P0
- [ ] **Replace every `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`** that currently reads `com.algoriza.disneyNew` / `com.algoriza.profedisneyNew` with `com.algoriza.criarte` / `com.algoriza.profecriarte`. Affected: lines around 553, 661, 764, 867, 1061, 1098.
- [ ] **Add `PrivacyInfo.xcprivacy` manifest** under [ios/Runner/](../ios/Runner/) declaring required-reason APIs (UserDefaults, file timestamps, system boot time, network) — see P0 in §1.
- [ ] **Fix `FLUTTER_TARGET` hardcoded to `/Users/ahmedemad/...`** in `project.pbxproj` (lines 544, 652, 755, 858, 1052, 1089). Replace with `$(SRCROOT)/../lib/main.dart` / `main_professores.dart`.
- [ ] **Unify iOS deployment target.** `Podfile` says 13.0, `project.pbxproj` build settings say 11.0. Pin one (13.0).
- [ ] **APS environment hardcoded to `development`** in [ios/Runner/Runner.entitlements](../ios/Runner/Runner.entitlements). Switch to `production` for release builds (or via provisioning profile at archive time).

### P1
- [ ] Remove unused privacy usage strings (Bluetooth, location) — see §1 P0.
- [ ] Add `android_12:` block to `flutter_native_splash-{parents,professores}.yaml` so Android 12+ users don't see the default white-circle splash.
- [ ] Confirm `LaunchScreenParents.storyboard` / `LaunchScreenProfessores.storyboard` resolve correctly via `$(LAUNCH_SCREEN_STORYBOARD)` after the bundle-ID fix.

---

## 6. Networking

### P0
- [ ] **Lower Dio timeouts.** [lib/core/network/network_client.dart:57-61](../lib/core/network/network_client.dart#L57-L61) sets connect / receive / send to 10 hours. Split: 15–30s connect, 30–60s JSON receive, longer only for explicit upload requests.
- [ ] **Handle 401 in the interceptor.** [lib/core/network/network_interceptor.dart:95-100](../lib/core/network/network_interceptor.dart#L95-L100) `_handleOnError` is empty. On 401: clear `UserBloc`, clear hydrated storage, pop to login. Document whether the server supports refresh tokens; if not, document expiry behavior.
- [ ] **Stop reading `mainKey.currentContext` to pick endpoints.** [lib/features/chat/presentation/bloc/chat_bloc.dart:90](../lib/features/chat/presentation/bloc/chat_bloc.dart#L90) and 14+ other repo/bloc sites force-unwrap a global widget context to select role-based URLs. Use `UserBloc.get.state.user?.type` (or pass flavor through DI) instead.
- [ ] **Switch `responseType: ResponseType.json`** (currently `.plain` + manual `jsonDecode`). On HTML error responses (Cloudflare 502/504, Laravel debug pages) the manual decode throws and the original status is lost.

### P1
- [ ] Centralise all REST paths in a typed `Endpoints` class. Currently 20+ scattered string literals across feature repos.
- [ ] Switch the base URL via `--dart-define API_BASE_URL=` per flavor / per CI lane; remove the legacy URL constants from `api_const.dart`.
- [ ] Add an idempotent-GET retry interceptor with jittered backoff.
- [ ] Replace `describeEnum(request.method)` ([network_client.dart:45](../lib/core/network/network_client.dart#L45)) with `request.method.name` (deprecated in modern Flutter).
- [ ] Remove the unused `dart:ffi` import in `network_client.dart:2`.

---

## 7. Auth & session

### P0
- [ ] **Hydration race on bootstrap.** `UserBloc` is a `HydratedCubit` whose `fromJson` is async; the splash kicks off `getUserData` before hydration completes, so the first request may go out without `Authorization`. Add a `Bootstrap` event that awaits hydration before any network call.
- [ ] **Clear `HydratedBloc` storage on logout** — `loggedOut()` ([lib/core/user/bloc/user_bloc.dart:76-82](../lib/core/user/bloc/user_bloc.dart#L76-L82)) only wipes the Hive `user` key, not the hydrated state. Next launch may rehydrate stale state.
- [ ] **Drop the arbitrary `Future.delayed(seconds: 1)`** between `removeUser()` and `FirebaseAuth.signOut()` ([user_bloc.dart:78,86](../lib/core/user/bloc/user_bloc.dart#L78)). Await each step properly.

### P1
- [ ] Null-guard `UserModel.fromJson(json['user'])` in `UserBloc.fromJson` ([user_bloc.dart:103](../lib/core/user/bloc/user_bloc.dart#L103)) so a corrupted store doesn't wipe login silently.

---

## 8. Push notifications & deep linking

### P0
- [ ] **Register `FirebaseMessaging.instance.onTokenRefresh`** and resync the device token on every change. Today only `BackgroundServicesBloc` registers once per session, so token rotations (reinstall, restore, GMS update, 270-day rotation) silently stop pushes.
- [ ] **Clear / revoke FCM token on logout.** `UserBloc.loggedOut()` doesn't call `FirebaseMessaging.instance.deleteToken()` and doesn't call a server-side revoke endpoint, so the next user receives push from the previous user (LGPD cross-account leak).
- [ ] **Initialise Firebase + add `@pragma('vm:entry-point')` to the FCM background isolate handler.** [lib/core/notifications_service/notifications_service.dart:120](../lib/core/notifications_service/notifications_service.dart#L120) `notificationBackgroundHandler` has neither — release AOT builds tree-shake the handler entirely; Firestore/Firebase calls inside the handler would crash.
- [ ] **Respect the approval gate from push taps.** [notification_helper.dart:13](../lib/core/notifications_service/notification_helper.dart#L13) navigates directly into features without checking `UserBloc.get.state.user?.isApproval`.
- [ ] **Don't crash on unknown FCM `type`.** Currently silently dropped; tap goes nowhere. Add a fallback to a generic notifications list.
- [ ] **`Message.fromJson` parser in the push payload** ([notification_helper.dart:18-20](../lib/core/notifications_service/notification_helper.dart#L18-L20)) does `jsonDecode(data['sender'])` assuming a string. If the backend ever sends `sender` as an object, the handler crashes. Pin the contract; tolerate both.

### P1
- [ ] Implement or remove `subScribeToTopic()` stub in `notifications_service.dart:49`.
- [ ] Document the FCM payload contract (`eventable_id`, `eventable_type`, `type`, `sender`) in code.
- [ ] Add Universal Links / App Links for deep-link push taps; right now `AndroidManifest.xml` has no `VIEW/BROWSABLE` intent-filter, and `Runner.entitlements` has no `applinks:`.

---

## 9. Firestore / chat

### P0
- [ ] **Order and paginate the messages query.** [lib/features/chat/data_sources/chat_impl.dart:152-164](../lib/features/chat/data_sources/chat_impl.dart#L152-L164) reads the entire collection with no `orderBy` and no `limit`. Cost and ordering bugs scale linearly.
- [ ] **Use `FieldValue.serverTimestamp()` for `dateTime` and Firestore-auto IDs.** Today doc IDs come from `DateTime.now().millisecondsSinceEpoch.toString()` and timestamps from the device clock — same-ms ID collisions and clock-skew ordering bugs.
- [ ] **`sendMessage` needs a `WriteBatch` / transaction.** The 6 sequential writes ([chat_impl.dart:39-77](../lib/features/chat/data_sources/chat_impl.dart#L39-L77)) leave the contact list and message list out of sync if any one fails. The `unReadCount` read-then-write is racy — use `FieldValue.increment(1)`.
- [ ] **Guard `Message.fromJson` against null/wrong `dateTime`** ([lib/features/chat/models/message.dart:48-49](../lib/features/chat/models/message.dart#L48-L49)). The unchecked cast to `Timestamp` blanks the whole conversation on a single bad doc. Also tighten `ChatUser.fromJson` casts.
- [ ] **Use UUIDs for Storage filenames.** [lib/features/chat/presentation/bloc/images_message_bloc.dart:53,122-123](../lib/features/chat/presentation/bloc/images_message_bloc.dart#L53) uses `image.name`, which collides (`image_0001.jpg`) and overwrites previous messages' images.
- [ ] **Cancel singleton stream subscriptions correctly.** [lib/features/chat/presentation/chat_screen.dart:42-45](../lib/features/chat/presentation/chat_screen.dart#L42-L45) cancels `di<ChatBloc>().messagesSubscription` in `dispose`, killing the singleton's stream for everyone. Either scope `ChatBloc` per chat (factory DI), or own subscription lifecycle inside the bloc.

### P1
- [ ] Compress images before `putFile` (no `maxWidth` / `imageQuality` set in [attachment_selection.dart:36](../lib/core/attachment_selection/attachment_selection.dart#L36)). A 12MP camera photo is ~5MB.
- [ ] Expose upload `task.cancel()` to the UI, and consider resumable uploads.
- [ ] Path scheme `chat/{senderId}/{receiverId}/...` is one-sided; consider `conversations/{conversationId}/...`. Audit storage rules for cross-user reads.
- [ ] Re-enable Firestore persistence (`init_dependencies.dart:32` disables it) — it queues offline writes and avoids re-fetches on chat open. The current setting causes the "offline message lost" UX (chat_bloc.dart:152-162 silently drops on failure).
- [ ] Use lexicographic compare on string IDs instead of `int.parse` in [chat_impl.dart:122-127](../lib/features/chat/data_sources/chat_impl.dart#L122-L127).
- [ ] Switch `on<ChatEvent>` catch-all to `on<Specific>` per event with bloc transformers (`droppable()` for send-message, `restartable()` for load).

---

## 10. Diary

### P0
- [ ] **`Question.fromJson` throws on unknown type.** [lib/features/diary/models/questions_models/question.dart:108-110](../lib/features/diary/models/questions_models/question.dart#L108-L110) hits `default: throw Exception('Invalid question type')`. A backend-added question type breaks the entire diary screen for every existing client. Add an `UnknownQuestion` fallback or filter unknown entries.
- [ ] **`QuestionCategory.fromJson` falls back to `{}`** for `question` ([question_category.dart:89](../lib/features/diary/models/question_category.dart#L89)), which triggers the throw above. Make the fallback safe.
- [ ] **Typo in `ChildModel.fromJson`** — [lib/features/diary/models/child_model.dart:29](../lib/features/diary/models/child_model.dart#L29) reads `json['age(']`, so every child's age is always empty.

### P1
- [ ] Add an `idempotency_key` / `request_id` to `sendQuestions` ([diary_impl.dart:99-136](../lib/features/diary/data_sources/diary_impl.dart#L99-L136)) so retries don't create duplicates.
- [ ] Use the shared `NetworkClient` in [diary/.../share_button.dart:87](../lib/features/diary/presentation/widgets/gallery_media/share_button.dart#L87) — currently constructs a fresh `Dio()` bypassing interceptors.

---

## 11. State management & widgets

### P0
- [ ] **`_MyAppState.dispose()` closes singletons.** [lib/my_app.dart:33-37](../lib/my_app.dart#L33-L37) calls `ConfigCubit.get.close()` / `UserBloc.get.close()` from the root widget. Singletons should not be closed by widget lifecycle.
- [ ] **`ConfigCubit.close()` throws on `late` fields that are never assigned.** [lib/core/config/cubit/cubit.dart:32-33,77-80](../lib/core/config/cubit/cubit.dart#L32-L33). Make `_configSubscription` / `_silentNotificationSubscription` nullable.
- [ ] **EventBus subscription created inside a `Builder` rebuild** in [lib/features/settings/events/event_screen.dart:55-62](../lib/features/settings/events/event_screen.dart#L55-L62) leaks the previous subscription on every rebuild. Move to `initState`.
- [ ] **`ScreenUtilInit` is nested inside `CustomThemes`/`ConfigSelector`** in [my_app.dart](../lib/my_app.dart). Any `.sp/.h/.w` used above `ScreenUtilInit` asserts in debug. Wrap the entire tree.

### P1
- [ ] Add `isClosed` / `if (!emit.isDone)` guards on every async emit in `user_bloc`, `featured_events_bloc`, `notifications_bloc`, `settings/*`. Currently only `login_bloc` and `otp_bloc` check.
- [ ] Switch chat / diary catch-all `on<Event>` to typed handlers per event subtype with bloc transformers.
- [ ] Make `ChatBloc` a per-chat factory in DI, or clear its mutable lists and subscriptions on every `GetMessages`. Today the singleton accumulates state across screens.
- [ ] Make `_MyApp.providers` an instance member built in `build()`, not a class-level `static`.

### P2
- [ ] Reduce `MaterialApp` rebuilds on every styling change — split selectors.
- [ ] Replace 25+ hardcoded `Color(0xff...)` literals across feature widgets with `context.colors.*`.
- [ ] Audit `BuildContext`-after-`await` use site by site; only 3 files check `mounted`/`context.mounted`.
- [ ] `AudioBloc.close()` doesn't await `dispose()` chains ([audio_bloc.dart:306-321](../lib/features/chat/presentation/audio_bloc/audio_bloc.dart#L306-L321)).
- [ ] Delete `lib/s.dart` (stray dev file with a top-level `main()`).

---

## 12. Dependencies

### P1
- [ ] Document why `dependency_overrides` for `http: ^1.1.0` and `package_info_plus: ^4.2.0` exist in [pubspec.yaml:109-111](../pubspec.yaml#L109-L111) — and remove them after upgrading the conflicting transitive parent.
- [ ] Replace abandoned/risky packages: `image_gallery_saver` (unmaintained, Android 14 scoped-storage breakage), `quill_html_editor` (abandoned, XSS surface), `flutter_custom_theme` (stale), `separated_column` / `separated_row` (trivial, replaceable with `ListView.separated`/`Wrap`).
- [ ] Bump deps that are 1–3 majors behind: `image_picker` (0.8 → 1.x), `permission_handler` (10.x → 11.x), `file_picker`, `record` (4.x → 5.x or `record_platform_interface`), `firebase_messaging`, `cloud_firestore`, `intl`, `alarm` (2.x → 4.x), `flutter_lints` (2 → 4 or 5).
- [ ] Remove unused deps: `flutter_sound` (never imported — recording uses `record`), `audio_session`, plus any of `appinio_video_player`, `flash`, `crop_your_image`, `dotted_border` that are imported 0–1 times.

---

## 13. Linting & code hygiene

### P1
- [ ] Enable in [analysis_options.yaml](../analysis_options.yaml): `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `unawaited_futures`, `avoid_print`, `cancel_subscriptions`, `close_sinks`, `use_super_parameters`.
- [ ] Route the ~146 `print` / `debugPrint` calls in `lib/` through a single logger that drops in release builds.
- [ ] Add a lint that prevents cross-feature absolute imports (`import_lint`, custom analyzer plugin, or a CI script). 124+ `package:escola/features/*` cross-imports today.

### P2
- [ ] Rename folder `lib/features/terms_and_condtions/` → `terms_and_conditions/`.
- [ ] Decide whether the pubspec name should match the brand (`escola` vs `criarte`).

---

## 14. Observability

### P1
- [ ] Add `firebase_analytics` (gated by ATT/consent for iOS).
- [ ] Add `firebase_performance` for HTTP timings.
- [ ] Migrate the homegrown Firestore `config/*` translations+styling to Firebase Remote Config (typed parameters, canary, audit log).

---

## 15. Documentation

### P1
- [ ] Replace the 3-line [README.md](../README.md) with: prerequisites (FVM, Flutter pin), how to run each flavor, where Firebase configs come from, who to ping for keystore/provisioning.
- [ ] Add `CODEOWNERS`, `CONTRIBUTING.md`, `SECURITY.md`, `docs/adr/`.
- [ ] Add a translation-key sync check (`tool/i18n_check.dart`) and run it in CI. `ar.json` is currently missing ~40% of keys.
- [ ] Decide whether Arabic is actually a shipping language (Brazil-focused product) or remove it.

---

## Cross-cutting tasks (not feature-scoped)

- [ ] Run the full review again at each major release; track P0 burn-down.
- [ ] Add a release checklist gate: "every PR touching shared code is smoke-tested in BOTH flavors."
- [ ] Audit every deep-link / push entry point for the `isApproval` gate.
- [ ] Audit logging for PII (CPF, phone, child name, medication, photo URLs).

Feature-specific tasks are mirrored into [features.md](features.md).
