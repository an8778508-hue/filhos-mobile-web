# Features Spec

One entry per feature under [lib/features/](../lib/features/). Each entry has a short description, the flavor(s) it applies to, and an open tasks list. Tick `- [x]` when shipped.

> Flavor key: **P** = parents, **T** = teachers (professores), **B** = both.
> Priority tags from the multi-expert review live in [review.md](review.md): **(P0)** / **(P1)** / **(P2)**.

---

## splash · B
[lib/features/splash/](../lib/features/splash/) — App boot, restores session, decides next route (login / approval gate / main).

### Tasks
- [ ] **(P0)** Add a `Bootstrap` step that **awaits `UserBloc` hydration before any network call**. Today splash kicks off `getUserData` while `HydratedCubit.fromJson` is still running, so the first request may go out without `Authorization`.
- [ ] **(P2)** Replace hardcoded `Color(0xffF2F2F2)` at `splash_screen.dart:85` with `context.colors.*`.
- [ ] Add an explicit minimum-display-time so the splash doesn't flicker on fast cold starts.
- [ ] Surface a clear error state if `initDependecies()` fails (currently silent).

---

## onboard · B
[lib/features/onboard/](../lib/features/onboard/) — First-run carousel introducing the product.

### Tasks
- [ ] Confirm onboarding appears only on first install (gate by Hive flag).
- [ ] Localize illustration captions for AR/EN/PT.
- [ ] Add a "skip" CTA on every page.

---

## choose_language · B
[lib/features/choose_language/](../lib/features/choose_language/) — Language picker (EN / PT / AR).

### Tasks
- [ ] **(P0)** **Remove the `requestTrackingAuthorization` call at `choose_language_screen.dart:63-72`.** Apple Guideline 5.1.2 rejection vector — ATT must run *after* the user has privacy context (e.g. post-onboarding) and must also fire for returning users who skip the language picker.
- [ ] Make the selected language sticky across logouts.
- [ ] Verify RTL switch is instant (no app restart needed).

---

## login · B
[lib/features/login/](../lib/features/login/) — Phone + country code entry; passes role from flavor to server.

### Tasks
- [ ] **(P0)** Stop reading role from `mainKey.currentContext.isProfessors` at `login_impl.dart:30`. Pass flavor explicitly via DI or read from a parameter — `mainKey.currentContext` can be null during early boot.
- [ ] **(P0)** On logout, call `FirebaseMessaging.instance.deleteToken()` and a server `revoke_device_token` so the next user doesn't inherit FCM pushes (LGPD cross-account leak).
- [ ] **(P0)** On logout, `clear()` the `HydratedBloc` storage for `UserState` (Hive `user` key alone is not enough — hydrated state lives in a separate path).
- [ ] Add explicit invalid-phone-format messaging using `brasil_fields`.
- [ ] Persist `last_otp_phone` to prefill on retry.
- [ ] Audit error mapping for 401/403 from `/auth/login`.

---

## otp · B
[lib/features/otp/](../lib/features/otp/) — SMS code entry, resend timer (Firebase Auth).

### Tasks
- [ ] Surface the SMS auto-fill suggestion on Android.
- [ ] Document the resend cooldown (uses `last_otp_request`).
- [ ] Handle the "code expired" path explicitly.

---

## your_account_under_review · B
[lib/features/your_account_under_review/](../lib/features/your_account_under_review/) — Approval gate; polled by `BackgroundServicesBloc`.

### Tasks
- [ ] **(P0)** Enforce approval check inside `notification_helper.dart:13` before any `WidgetFunctions.navigateTo` — a pending user tapping a chat/event push currently bypasses the gate.
- [ ] **(P0)** Add an integration / widget test that proves the gate works from splash, OTP success, AND a push tap from terminated state.
- [ ] Add a "contact your school" CTA after N minutes pending.
- [ ] Show a short reason string if the server returns one (rejected vs. pending).

---

## main · B
[lib/features/main/](../lib/features/main/) — Tab shell with `bottom_navy_bar`; owns `MainBloc`.

### Tasks
- [ ] Document the tab order per flavor (parents vs. teachers).
- [ ] Add a guard so background pushes don't switch tabs while the user is mid-flow.

---

## home · B
[lib/features/home/](../lib/features/home/) — Dashboard. Parents: per-child cards + recent activity. Teachers: class roster + recent class activity.

### Tasks
- [ ] **(P0)** Replace `mainKey.currentContext`-based endpoint selection in `home_repo.dart:8` with `UserBloc.get.state.user?.type`.
- [ ] **(P2)** `getAlarms(context)` called from `initState` at `home_screen.dart:45` — verify it does no work after `await` on the same context, or guard with `if (!mounted) return;`.
- [ ] [P] Make the active child unmistakable — large avatar, name, and a clear switcher.
- [ ] [T] Surface class-level summaries (children present / activities pending).
- [ ] [B] Pull-to-refresh on the home feed.

---

## all_children · P
[lib/features/all_children/](../lib/features/all_children/) — List of children linked to the parent account.

### Tasks
- [ ] Show enrollment status badge per child.
- [ ] Allow re-ordering children if a parent has many.

---

## diary · B
[lib/features/diary/](../lib/features/diary/) — Typed activity reports (`MainCategory` → `QuestionCategory` → typed `Question`).

### Tasks
- [ ] **(P0)** Replace `default: throw Exception('Invalid question type')` at `questions_models/question.dart:108-110` with an `UnknownQuestion` fallback or skip-on-unknown — a single new server-side question type currently breaks the entire diary for every old client.
- [ ] **(P0)** Make `QuestionCategory.fromJson` fallback safe at `question_category.dart:89` — the current `{}` fallback then hits the `Invalid question type` throw above.
- [ ] **(P0)** Fix typo `json['age(']` → `json['age']` in `child_model.dart:29` — every child's age is currently empty.
- [ ] **(P1)** Add an `idempotency_key` / `request_id` to `sendQuestions` at `diary_impl.dart:99-136` to prevent duplicate answers on retry.
- [ ] **(P1)** Use the shared `NetworkClient` in `presentation/widgets/gallery_media/share_button.dart:87` — currently constructs a fresh `Dio()` that bypasses interceptors.
- [ ] **(P1)** Replace catch-all `on<DiaryEvent>` in `diary_bloc.dart:38-54` with typed handlers.
- [ ] [T] Add a "save as draft" path so partial entries don't lose data.
- [ ] [T] Auto-populate the date with the current school day.
- [ ] [P] Add a weekly digest view (mood/sleep/food trends).
- [ ] [B] Cache the question schema so the editor opens offline.

---

## chat · B
[lib/features/chat/](../lib/features/chat/) — Firestore-backed messaging, 1:1 child-scoped + teacher group chats.

### Tasks
- [ ] **(P0)** Switch to `FieldValue.serverTimestamp()` for `dateTime` and let Firestore auto-generate doc IDs. Current `DateTime.now().millisecondsSinceEpoch.toString()` IDs in `chat_helper.dart:14-15` and `chat_impl.dart:245-249` collide on same-ms writes.
- [ ] **(P0)** Add `.orderBy('timestamp').limitToLast(N)` + pagination to the messages query at `chat_impl.dart:152-164`. Today it streams the entire collection unordered.
- [ ] **(P0)** Wrap `sendMessage` (`chat_impl.dart:39-77`) in a `WriteBatch` / transaction so the 6 sequential writes are atomic. Use `FieldValue.increment(1)` for `unReadCount` to fix the read-then-write race.
- [ ] **(P0)** Guard `Message.fromJson` at `message.dart:48-49` — null/non-Timestamp `dateTime` currently blanks the entire conversation. Tighten `ChatUser.fromJson` casts at `chat_user.dart:31-38` similarly.
- [ ] **(P0)** Use UUIDs for Firebase Storage filenames in `images_message_bloc.dart:53,122-123` (currently `image.name`, which collides like `image_0001.jpg` and overwrites prior messages' images).
- [ ] **(P0)** Stop killing the singleton stream from `chat_screen.dart:42-45`. Either move `ChatBloc` to per-screen factory DI or own the subscription's lifecycle inside the bloc.
- [ ] **(P0)** Replace `mainKey.currentContext` lookups in `chat_repository.dart:11` for `teachersEndpoint` with `UserBloc.get.state.user?.type`.
- [ ] **(P0)** Replace catch-all `on<ChatEvent>` (`chat_bloc.dart:44-70`) with typed `on<Specific>` handlers; use `droppable()` for send-message and `restartable()` for load.
- [ ] **(P1)** Compress images before `putFile` in `attachment_selection.dart:36` (set `maxWidth`/`imageQuality`).
- [ ] **(P1)** Expose upload `task.cancel()` and consider resumable uploads.
- [ ] **(P1)** Move storage path from `chat/{senderId}/{receiverId}/...` to a symmetric `conversations/{conversationId}/...` — current scheme makes cross-user reads dependent on lenient rules.
- [ ] **(P1)** Re-enable Firestore offline persistence (currently disabled in `init_dependencies.dart:32`) — auto-queues offline writes and fixes the "send while offline → message lost" UX at `chat_bloc.dart:152-162`.
- [ ] **(P1)** Use lexicographic compare on string IDs at `chat_impl.dart:122-127` instead of `int.parse` (UUID-safe).
- [ ] **(P2)** `AudioBloc.close()` (`audio_bloc.dart:306-321`) doesn't await `dispose()` chains — use `Future.wait` and await.
- [ ] [T] Confirm group-chat creation flow is reachable only when `context.isProfessors && groupType != null`.
- [ ] [B] Add typing indicators (Firestore presence doc).
- [ ] [B] Add per-message delivery / read receipts.
- [ ] [B] Sanity-check Firestore security rules cover parent/teacher/child triples.

---

## featured_events · B
[lib/features/featured_events/](../lib/features/featured_events/) — Highlighted/featured events carousel on home.

### Tasks
- [ ] [P] Track "seen" featured events in Hive (`seenFeaturedEvents`) to dedupe badges.
- [ ] [B] Add empty/error states.

---

## gallery · P
[lib/features/gallery/](../lib/features/gallery/) — List of photo collections per child.

### Tasks
- [ ] Add date-grouping in the list.
- [ ] Confirm thumbnails use cached_network_image with a placeholder.

---

## gallery_images · P
[lib/features/gallery_images/](../lib/features/gallery_images/) — Full-screen image viewer (`photo_view`).

### Tasks
- [ ] Add "save to device" via `image_gallery_saver`.
- [ ] Add share-sheet via `share_plus`.

---

## notifications · B
[lib/features/notifications/](../lib/features/notifications/) — In-app FCM inbox; deep-links via `eventable_id` + `eventable_type`.

### Tasks
- [ ] **(P0)** Register `FirebaseMessaging.instance.onTokenRefresh` and resync to the server on change. Today only a single one-shot `updateDeviceToken()` runs at session start; rotated tokens silently break push.
- [ ] **(P0)** Add `@pragma('vm:entry-point')` AND call `Firebase.initializeApp(options: ...)` inside `notificationBackgroundHandler` at `notifications_service.dart:120`. Release AOT builds otherwise tree-shake the handler and any Firestore/Firebase call inside it crashes.
- [ ] **(P0)** Check `UserBloc.get.state.user?.isApproval` inside `notification_helper.dart:13` before routing — a pending user tapping a push currently bypasses the approval gate.
- [ ] **(P0)** Tolerate unknown FCM `type` — `notification_helper.dart:13-34` silently drops the tap. Add a fallback to the in-app inbox.
- [ ] **(P0)** Normalize the `sender` contract — `notification_helper.dart:18-20` does `jsonDecode(data['sender'])` assuming a string; document and enforce both client and server side.
- [ ] **(P1)** Implement or remove the empty `subScribeToTopic()` stub at `notifications_service.dart:49`.
- [ ] **(P1)** Add Universal Links / App Links so cold-start push taps deep-link reliably (Android manifest needs `VIEW/BROWSABLE` filter; `Runner.entitlements` needs `applinks:`).
- [ ] Document the supported `eventable_type` values and their destinations.
- [ ] Mark-all-as-read action.
- [ ] Empty state copy in PT/EN/AR.

---

## search · B
[lib/features/search/](../lib/features/search/) — Global search. Parents search teachers; teachers search children.

### Tasks
- [ ] Debounce the query (use `lib/core/utils` Debouncer).
- [ ] Show recent searches.

---

## search_for_filter · B
[lib/features/search_for_filter/](../lib/features/search_for_filter/) — Filter-builder UI used by other features.

### Tasks
- [ ] Reusable API: document the inputs/outputs.
- [ ] Persist last-used filters per context.

---

## attendants_selection · B
[lib/features/attendants_selection/](../lib/features/attendants_selection/) — Multi-select picker for attendants (teachers/guardians).

### Tasks
- [ ] Distinguish "already invited" vs. "available" states.

---

## select_attendants · B
[lib/features/select_attendants/](../lib/features/select_attendants/) — Choose children attending an event/form.

### Tasks
- [ ] Add "select all in class" shortcut for teachers.

---

## add_form · B
[lib/features/add_form/](../lib/features/add_form/) — Dynamic schema-driven form engine (RSVPs, consents, medical, incident).

### Tasks
- [ ] Document every supported field type in this file (Text, TextArea, RichText, Number, Counter, DatePicker, TimePicker, Dropdown, MultiSelect, SegmentedControl, PeriodOfTime, CreateMeetingButton, UploadImage, Attachment, Comments, AttendantsSelection, Collection, Group).
- [ ] Add validation summary at the top of a form on submit failure.
- [ ] Snapshot autosave so back-press doesn't lose data.
- [ ] Document `FormDependencyModel` semantics with examples.

---

## add_medicine · P
[lib/features/add_medicine/](../lib/features/add_medicine/) — Register child medication (name, dosage, schedule, prescription image).

### Tasks
- [ ] **(P0)** Declare the `alarm` package's foreground service in [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml): `FOREGROUND_SERVICE`, an appropriate `FOREGROUND_SERVICE_*` type permission, a `<service ... foregroundServiceType=...>` element, and `USE_FULL_SCREEN_INTENT` for API 34+. Android 14 throws `ForegroundServiceTypeException` otherwise — medicine alarms crash the app.
- [ ] **(P0)** Gate `SCHEDULE_EXACT_ALARM` at runtime in `lib/core/utils/alarm_manager/alarm_manager.dart:90` (call `AlarmManager.canScheduleExactAlarms()` first). Add `USE_EXACT_ALARM` fallback (auto-granted on API 33+ with the right Play policy declaration). Otherwise reminders silently demote to inexact.
- [ ] **(P0)** Audit Crashlytics logging in this flow — medication info is currently sent as `reason` on 500 responses (LGPD violation).
- [ ] **(P1)** Verify alarms survive app-kill on iOS 17+ and Android 14.
- [ ] Encrypt prescription images at rest (or restrict to memory cache).

---

## add_address · P
[lib/features/add_address/](../lib/features/add_address/) — Add a parent address with CEP lookup (`search_cep`).

### Tasks
- [ ] Validate CEP format before lookup.
- [ ] Cache last-resolved CEPs to reduce API calls.

---

## my_addresses · P
[lib/features/my_addresses/](../lib/features/my_addresses/) — List of saved addresses.

### Tasks
- [ ] "Set as default" action.
- [ ] Swipe-to-delete with undo.

---

## settings · B
[lib/features/settings/](../lib/features/settings/) — Container with sub-features: `edit_profile`, `my_children`, `medicines`, `announcements`, `events`, `about`.

### Tasks
- [ ] **(P0)** `events`: fix the EventBus subscription leak at `settings/events/event_screen.dart:55-62` — `_sub = eventBus.on().listen(...)` is inside the `Builder.builder` and re-subscribes on every rebuild. Move into `initState`.
- [ ] **(P0)** Logout: confirm it calls `FirebaseMessaging.instance.deleteToken()`, clears `HydratedBloc` state (not just the Hive `user` key), and revokes the token server-side. See also login tasks.
- [ ] **(P0)** Add an "Export my data" path under settings → LGPD Art. 18, II.
- [ ] **(P1)** Verify `settings_screen.dart:240-254` `deleteAccount` triggers actual server-side LGPD-Art.18 erasure, not just a local logout.
- [ ] [P] Replace direct REST endpoint role-branching using `mainKey.currentContext` in `edit_profile_repo.dart:16` — use `UserBloc.get.state.user?.type`.
- [ ] `edit_profile`: confirm completeness % calc matches `UserModel.getPercentage()`.
- [ ] `my_children` [P]: show "remove from account" with a confirmation modal.
- [ ] `medicines`: align with `add_medicine` flow (single source of truth for schedule).
- [ ] `announcements`: toggle per-category subscriptions.
- [ ] `events`: surface upcoming RSVPs and history.
- [ ] `about`: show app version (`package_info_plus`), contact, terms, privacy.

---

## privacy_policy · B
[lib/features/privacy_policy/](../lib/features/privacy_policy/) — Static / WebView privacy policy. URL is server-driven via `Config.get.appInfo.privacyUrl` (`privacy_policy_screen.dart:50`).

### Tasks
- [ ] **(P1)** Add a navigation-host allowlist to the WebView at `privacy_policy_screen.dart:21-49`. With `JavaScriptMode.unrestricted` on a remote URL, any link in the page loads in-app — phishing surface.
- [ ] **(P1)** Set `WebView.setBackgroundColor` to avoid the white flash on first paint.
- [ ] Confirm policy URL is environment-aware (no prod URL in staging).

---

## terms_and_condtions · B
[lib/features/terms_and_condtions/](../lib/features/terms_and_condtions/) — Static / WebView terms.

### Tasks
- [ ] Rename folder to `terms_and_conditions` (typo) — coordinate with all imports.

---

## background_services · B
[lib/features/background_services/](../lib/features/background_services/) — `BackgroundServicesBloc`: approval polling, push-token registration, foreground listeners.

### Tasks
- [ ] **(P0)** Add `FirebaseMessaging.onTokenRefresh` listener (currently only a one-shot `updateDeviceToken()` at `background_services_bloc.dart:37`).
- [ ] **(P1)** Document the polling cadence and back-off for approval status.
- [ ] Confirm token re-registration on user/account change.

---

## Cross-feature tasks

### From the multi-expert review ([review.md](review.md))
- [ ] **(P0)** **Rotate the Android keystore** — committed to public GitHub with password `123456` (see review §1).
- [ ] **(P0)** Fix iOS bundle IDs in `project.pbxproj` — currently `com.algoriza.disneyNew*` (see review §5).
- [ ] **(P0)** Add `PrivacyInfo.xcprivacy` manifest (App Store rejection blocker).
- [ ] **(P0)** Pin Android `targetSdkVersion 34+` (Play Store rejection blocker).
- [ ] **(P0)** Lower Dio timeouts from 10 hours to 15–60s (see review §6).
- [ ] **(P0)** Replace every `mainKey.currentContext?.isParents/isProfessors` call site (15+ across repos/blocs) with `UserBloc.get.state.user?.type`.
- [ ] **(P0)** Stop logging `Authorization` header + request body in Crashlytics (`network_client.dart:175-177`) — LGPD violation.
- [ ] **(P0)** Handle 401 in `network_interceptor._handleOnError` — clear `UserBloc` + hydrated storage + pop to login.
- [ ] **(P0)** Stop closing singletons from `_MyAppState.dispose()` (`my_app.dart:33-37`).
- [ ] **(P0)** Wrap the entire app tree (including `ConfigSelector`) inside `ScreenUtilInit` — currently nested too deep.
- [ ] **(P0)** Delete `lib/s.dart` (stray dev file with its own `main()`).
- [ ] **(P0)** Add a CI pipeline (format / analyze / test / build both flavors / build iOS for both schemes).
- [ ] **(P0)** Add the first tests — bloc tests for `UserBloc` and `ConfigCubit`, unit tests for `NetworkClient`, widget test for the approval gate.
- [ ] **(P1)** Centralise REST paths in a typed `Endpoints` class (currently 20+ scattered string literals).
- [ ] **(P1)** Switch base URL via `--dart-define API_BASE_URL=` and remove the legacy URLs from `api_const.dart`.
- [ ] **(P1)** Replace abandoned packages (`image_gallery_saver`, `quill_html_editor`, `flutter_custom_theme`, `separated_column`/`_row`) and bump 1–3-major-behind packages (`image_picker`, `permission_handler`, `firebase_*`, `intl`, `alarm`, `flutter_lints`).
- [ ] **(P1)** Remove unused packages: `flutter_sound`, `audio_session` (recording uses `record`); audit `appinio_video_player`, `flash`, `crop_your_image`, `dotted_border`.
- [ ] **(P1)** Document or remove the `http` / `package_info_plus` `dependency_overrides`.
- [ ] **(P1)** Enable in [analysis_options.yaml](../analysis_options.yaml): `prefer_const_constructors`, `unawaited_futures`, `avoid_print`, `cancel_subscriptions`, `close_sinks`, `use_super_parameters`.
- [ ] **(P1)** Route 146 `print` / `debugPrint` calls through a single logger that drops in release.
- [ ] **(P1)** Add `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, and replace the 3-line README.
- [ ] **(P1)** Add a translation-key sync check (`tool/i18n_check.dart`) — `ar.json` is missing ~40% of keys today.
- [ ] **(P1)** Add `firebase_analytics`, `firebase_performance`, and migrate the homegrown `Firestore config/*` to Firebase Remote Config.
- [ ] **(P1)** Add a lint rule preventing cross-feature absolute imports (124+ today).
- [ ] **(P2)** Replace 25+ hardcoded `Color(0xff...)` literals in feature widgets with `context.colors.*`.
- [ ] **(P2)** Rename `terms_and_condtions/` → `terms_and_conditions/`.

### Pre-existing
- [ ] Audit every feature for PT/EN/AR string coverage; flag missing keys.
- [ ] Add per-feature smoke tests (open screen, render, no exception) once a testing baseline exists.
- [ ] Confirm every feature respects the approval gate (no screen reachable when `isApproval == false` except `your_account_under_review`).
- [ ] Verify both flavors compile and run after any cross-feature refactor.
