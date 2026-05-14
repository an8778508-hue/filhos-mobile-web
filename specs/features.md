# Features Spec

One entry per feature under [lib/features/](../lib/features/). Each entry has a short description, the flavor(s) it applies to, and an open tasks list. Tick `- [x]` when shipped.

> Flavor key: **P** = parents, **T** = teachers (professores), **B** = both.
> Priority tags from the multi-expert review live in [review.md](review.md): **(P0)** / **(P1)** / **(P2)**.
>
> **2026-05-14:** Executive-summary items 1–15 from [review.md](review.md) were fixed in code. The matching feature tasks below are ticked. See the change log at the top of [review.md](review.md) for the full file list.

---

## splash · B
[lib/features/splash/](../lib/features/splash/) — App boot, restores session, decides next route (login / approval gate / main).

### Tasks
- [ ] **(P0)** Add a `Bootstrap` step that **awaits `UserBloc` hydration before any network call**. Today splash kicks off `getUserData` while `HydratedCubit.fromJson` is still running, so the first request may go out without `Authorization`. *(partial: `UserBloc.fromJson` is now null-guarded, but a real `Bootstrap` event is still pending)*
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
- [x] **(P0)** **Remove the `requestTrackingAuthorization` call at `choose_language_screen.dart:63-72`.** Apple Guideline 5.1.2 rejection vector — ATT must run *after* the user has privacy context. *Fixed 2026-05-14: removed from choose_language; moved to `MainScreen.initState` via new `core/utils/tracking_permission.dart`. Idempotent on `notDetermined` so returning users get prompted on first reach of main.*
- [ ] Make the selected language sticky across logouts.
- [ ] Verify RTL switch is instant (no app restart needed).

---

## login · B
[lib/features/login/](../lib/features/login/) — Phone + country code entry; passes role from flavor to server.

### Tasks
- [x] **(P0)** Stop reading role from `mainKey.currentContext.isProfessors`. *Fixed 2026-05-14: login_impl now reads `isProfessorsFlavor` from the process-wide flavor singleton; flavor is set in `main*.dart` before `runApp`.*
- [x] **(P0)** On logout, call `FirebaseMessaging.instance.deleteToken()` so the next user doesn't inherit FCM pushes. *Fixed 2026-05-14: `UserBloc._signOutCleanup` calls `NotificationService.clearToken()`. Server-side `revoke_device_token` endpoint still pending — coordinate with backend.*
- [ ] **(P0)** On logout, `clear()` the `HydratedBloc` storage for `UserState`. *Partial: `UserBloc.fromJson` is null-guarded so corrupt state can't crash, and `emit(state.copyWith(user: null))` writes a clean state to Hydrated storage. Explicit `HydratedBloc.storage.clear()` for the UserState key is still optional cleanup.*
- [ ] Add explicit invalid-phone-format messaging using `brasil_fields`.
- [ ] Persist `last_otp_phone` to prefill on retry.
- [ ] Audit error mapping for 401/403 from `/auth/login`.

---

## register · B
[lib/features/register/](../lib/features/register/) — Create-account flow reached from the login footer. Collects `name / email / password / password_confirmation`; submits `POST auth/register`; on success calls `UserBloc.loggedIn(userModel)` and routes to main (`isApproval == true`) or to `your_account_under_review`. Shares [LoginRepository](../lib/features/login/data_sources/login_repository.dart) — `RegisterBloc` is registered alongside `LoginBloc` in [login_di.dart](../lib/features/login/login_di.dart) so there is no separate `register_impl.dart`.

### Tasks
- [x] **(P0)** Replace `(mainKey.currentContext?.isProfessors ?? false)` in `LoginImpl.register` with `isProfessorsFlavor`. *Fixed 2026-05-14 alongside [login → T-fix-1](login/tasks.md#constitution-drift-fixes); the initial "14 sites swept" missed this file plus 3 others in `login_impl.dart`.*
- [ ] **(P1)** Move `register` out of `LoginRepository` into a dedicated `RegisterRepository` so the abstraction matches the screen boundary. Today the only difference between login and register at the data layer is the endpoint path.
- [ ] **(P1)** Surface server-side validation errors per field (email already in use, weak password, name length) instead of the generic `ServerFailure('Registration failed')` at [login_impl.dart:386](../lib/features/login/data_sources/login_impl.dart#L386).
- [ ] **(P2)** Client-side validators currently mirror login's: email regex + ≥6-char password. Confirm parity with the server contract. *Confirm-password mismatch check is already present at [register_screen.dart:218-220](../lib/features/register/presentation/register_screen.dart#L218-L220) — initial entry incorrectly flagged this as missing.*
- [ ] [B] Add a "back to login" CTA in the app bar (today reachable only by `Navigator.pop`).
- [ ] [B] Document whether teachers can self-register or only school admins. Today the screen is identical for both flavors; the role header still distinguishes them server-side.
- [x] [B] Surface terms / privacy consent at submission time. *Fixed 2026-05-14 — inline T&C / Privacy block added to register screen mirroring the login pattern. See [register/tasks.md T-fix-3](register/tasks.md).*

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
- [x] **(P0)** Enforce approval check inside `notification_helper.dart`. *Fixed 2026-05-14: returns early if `UserBloc.get.state.user?.isApproval == false`.*
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
- [x] **(P0)** Replace `mainKey.currentContext`-based endpoint selection in `home_repo.dart:8`. *Fixed 2026-05-14: uses `isCurrentUserProfessor` from `core/user/current_role.dart`.*
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
- [x] **(P0)** Replace `default: throw` in `Question.fromJson`. *Fixed 2026-05-14: now `static Question? fromJson(...)` returning null on unknown / null / empty input. Stray `print`s removed.*
- [x] **(P0)** Make `QuestionCategory.fromJson` fallback safe. *Fixed 2026-05-14: filters nulls via `whereType<Question>()` and only parses `question` when the entry is a real `Map<String, dynamic>`.*
- [x] **(P0)** Fix typo `json['age(']` → `json['age']`. *Fixed 2026-05-14.*
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
- [x] **(P0)** Switch to `FieldValue.serverTimestamp()` for `dateTime`. *Fixed 2026-05-14: `Message.toJson({forServer:true})` writes the sentinel; doc IDs auto-allocated by Firestore when no client id is supplied.*
- [x] **(P0)** Add `.orderBy('timestamp', descending: true).limit(N)` to the messages query. *Fixed 2026-05-14 with `_messagesPageSize = 50`. Pagination UI still pending.*
- [x] **(P0)** Wrap `sendMessage` in a `WriteBatch`; use `FieldValue.increment(1)` for `unReadCount`. *Fixed 2026-05-14.*
- [x] **(P0)** Guard `Message.fromJson` and `ChatUser.fromJson` against null/wrong types. *Fixed 2026-05-14.*
- [x] **(P0)** Use auto-id Storage paths for message docs. *Fixed 2026-05-14: `_messageDoc` calls `col.doc()` (auto-id) when no client id is supplied. Image filename collisions on the underlying Firebase **Storage** putFile path are tracked separately under attachment_selection.*
- [ ] **(P0)** Stop killing the singleton stream from `chat_screen.dart:42-45`. Either move `ChatBloc` to per-screen factory DI or own the subscription's lifecycle inside the bloc.
- [x] **(P0)** Replace `mainKey.currentContext` lookups in `chat_repository.dart`. *Fixed 2026-05-14: uses `isCurrentUserParent`.*
- [ ] **(P0)** Replace catch-all `on<ChatEvent>` (`chat_bloc.dart:44-70`) with typed `on<Specific>` handlers; use `droppable()` for send-message and `restartable()` for load.
- [ ] **(P1)** Compress images before `putFile` in `attachment_selection.dart:36` (set `maxWidth`/`imageQuality`).
- [ ] **(P1)** Expose upload `task.cancel()` and consider resumable uploads.
- [ ] **(P1)** Move storage path from `chat/{senderId}/{receiverId}/...` to a symmetric `conversations/{conversationId}/...` — current scheme makes cross-user reads dependent on lenient rules.
- [ ] **(P1)** Re-enable Firestore offline persistence (currently disabled in `init_dependencies.dart:32`) — auto-queues offline writes and fixes the "send while offline → message lost" UX at `chat_bloc.dart:152-162`.
- [x] **(P1)** Use lexicographic compare on string IDs instead of `int.parse`. *Fixed 2026-05-14 in `updateConversations`.*
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
- [x] **(P0)** Register `FirebaseMessaging.instance.onTokenRefresh`. *Fixed 2026-05-14: `NotificationService.configureNotifications` accepts an `onTokenRefresh` callback; `BackgroundServicesBloc` wires it to `UserBloc.updateDeviceToken`.*
- [x] **(P0)** Add `@pragma('vm:entry-point')` + `Firebase.initializeApp` to the background handler. *Fixed 2026-05-14 in `notifications_service.dart`.*
- [x] **(P0)** Approval-gate check in `notification_helper.dart`. *Fixed 2026-05-14.*
- [x] **(P0)** Tolerate unknown FCM `type`. *Fixed 2026-05-14: unknown types deep-link to `NotificationsPage` (the in-app inbox) instead of being dropped silently.*
- [x] **(P0)** Normalize the `sender` contract. *Fixed 2026-05-14: `_parseEmbedded` accepts both JSON-string and nested-object form.*
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
- [x] **(P0)** Declare the `alarm` package's foreground service. *Fixed 2026-05-14: added `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `USE_FULL_SCREEN_INTENT`, `USE_EXACT_ALARM`, `VIBRATE` to AndroidManifest.*
- [x] **(P0)** Gate `SCHEDULE_EXACT_ALARM` at runtime + `USE_EXACT_ALARM` fallback. *Fixed 2026-05-14: `AlarmManager._ensureExactAlarmPermission` requests via `permission_handler`, skips with a log if denied.*
- [x] **(P0)** Audit Crashlytics logging — medication / CPF / phone keys redacted. *Fixed 2026-05-14 in `network_client._redactBody`.*
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
- [x] **(P0)** Logout: clears `FirebaseMessaging.deleteToken()` + alarm state + emits a clean `UserState`. *Fixed 2026-05-14 in `UserBloc._signOutCleanup`. Server-side token revocation endpoint pending — coordinate with backend.*
- [ ] **(P0)** Add an "Export my data" path under settings → LGPD Art. 18, II.
- [ ] **(P1)** Verify `settings_screen.dart:240-254` `deleteAccount` triggers actual server-side LGPD-Art.18 erasure, not just a local logout.
- [x] [P] Replace `mainKey.currentContext` role-branching in `edit_profile_repo.dart` and `edit_profile_bloc.dart`. *Fixed 2026-05-14: the endpoint is identical for both roles (server routes by token) so the branch is gone; the bloc uses `isCurrentUserProfessor`.*
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
- [x] **(P0)** Add `FirebaseMessaging.onTokenRefresh` listener. *Fixed 2026-05-14: `CallServices` passes an `onTokenRefresh` callback to `NotificationService.configureNotifications`.*
- [ ] **(P1)** Document the polling cadence and back-off for approval status.
- [ ] Confirm token re-registration on user/account change.

---

---

# Proposed features — competitive gap closure (added 2026-05-14)

*Driven by the iCare Kids / InstaKidz comparison in [business.md §9](business.md#9-competitive-landscape). Each entry is a candidate feature, not a committed roadmap item — pick during planning. Flavor tag uses the same P/T/B convention as above.*

## qr_pickup · B *(Tier 1 — proposed)*
QR-code drop-off and pickup. Parent app generates a rotating QR for an authorized pickup person; teacher app scans on arrival/release. Closes the iCare-only "QR pickup" gap.

### Tasks
- [ ] Generate per-authorization rotating QR codes on the parent side (TTL ≤ 24h).
- [ ] Scanner UI in teacher app; logs `pickup_at` / `dropoff_at` timestamps server-side.
- [ ] Pair with `attendants_selection` for authorized-list management.
- [ ] Push parent confirmation: "Child picked up by {name} at {time}".
- [ ] Verify LGPD: QR encodes an opaque token only, no PII.

## parent_arrival · P *(Tier 1 — proposed)*
"I'm here" tap from parent home → push to the assigned teacher, reducing pickup wait time.

### Tasks
- [ ] New action on parent home; debounced to one ping per 5 min per child.
- [ ] Pre-built localized message; teacher gets a special-styled push (different from chat).
- [ ] Surfaces a "Parents waiting at gate" widget on the teacher home.

## allergies · B *(Tier 1 — proposed)*
Surface `ChildDetailsModel` allergy / medical-flag data prominently on the teacher-side child header.

### Tasks
- [ ] Confirm the field exists on the server payload; add to `ChildDetailsModel` if not.
- [ ] Red banner above the child name on diary write, gallery upload, and chat header.
- [ ] Bypass parent app — teacher-only surface.
- [ ] Treat as sensitive: no logging in Crashlytics breadcrumbs.

## incident_report · B *(Tier 1 — proposed)*
Accident / incident report template; legal paper trail. Builds on `add_form` engine.

### Tasks
- [ ] Add `AddFormType.incidentReport`; schema with who / what / when / where / severity / photo / parent-acknowledgement.
- [ ] PDF export for the school archive (server-side rendering preferred).
- [ ] Auto-push to the parent with "Open report" CTA; parent ack stored.
- [ ] LGPD: 5-year retention by default (check Brazilian education-law requirements).

## health_log · B *(Tier 1 — proposed)*
Health / nurse diary subtype: temperature, symptoms, action taken, notify-nurse flag.

### Tasks
- [ ] New `MainCategory` "Saúde" + typed questions (temp, symptoms multi-select, action-taken text, notify-nurse boolean).
- [ ] Parent receives a "Health update" push distinct from regular diary push.
- [ ] Optionally hide from the standard diary timeline unless permission granted (LGPD).

## poll · B *(Tier 1 — proposed)*
Parent-facing polls / surveys via the `add_form` engine.

### Tasks
- [ ] Add `AddFormType.poll`; single-question (radio / multi-select / Likert).
- [ ] School-wide vs per-class targeting.
- [ ] Results visible to admin (and optionally parents, per setting).
- [ ] Deadline + reminder push for non-responders.

## reactions · B *(Tier 1 — proposed)*
Likes & comments on gallery posts and diary entries. Maps to InstaKidz's social-engagement feature.

### Tasks
- [ ] Firestore reactions doc per content item (`{contentType, contentId, userId, type}`).
- [ ] Render heart / clap / "saudades" reactions on `gallery_images` and diary entries.
- [ ] Comment thread (text only first; no media).
- [ ] Reuse chat moderation primitives (eventual: word filter, abuse report).

---

## gate_module · B *(Tier 2 — proposed)*
School-gate kiosk mode using teacher app; pairs with `qr_pickup`.

### Tasks
- [ ] Kiosk-mode auth flow for the gate tablet (separate from teacher login).
- [ ] Continuous QR scanner; logs `arrived_at` / `released_at` per child.
- [ ] Parent push on both events.
- [ ] Offline buffer for poor gate-Wi-Fi.

## bus_tracking · P *(Tier 2 — proposed)*
Parent-side read-only bus map + ETA push.

### Tasks
- [ ] Pick a GPS/telematics vendor; document API contract.
- [ ] Parent map shows current bus position only for the trip their child is on (privacy).
- [ ] 5-min-before-arrival push to the parent's chosen stop.
- [ ] Out-of-route alert to school admin.

## white_label_theming · B *(Tier 2 — proposed)*
Per-school branding (palette + logo + display name) without separate binaries. Extends `ConfigCubit.styling`.

### Tasks
- [ ] Per-`school_id` Firestore `config/{school_id}` document overrides theming.
- [ ] Logo asset URL hot-swapped on splash + main app bar.
- [ ] "Display name" in `AppInfo` overridable.
- [ ] Document the schema; ship 1 pilot school to validate.

---

## ai_diary_draft · T *(Tier 3 — proposed — flagship AI feature)*
Teacher uploads 3–4 photos + 30s voice note → LLM drafts a typed-question diary entry pre-filled into the existing diary editor. Teacher edits + sends.

### Tasks
- [ ] Server-side LLM endpoint with photo+audio input (Vertex AI Gemini or Anthropic via Claude API; both have multimodal vision + audio).
- [ ] Output schema matches `QuestionCategory` so the editor can pre-fill without UI changes.
- [ ] LGPD: photos are processed in-region (São Paulo for GCP, AWS sa-east-1 for AWS); no model-provider retention of children's images.
- [ ] Always teacher-confirmed before send; no auto-publish.
- [ ] Per-school opt-in; default OFF for first 6 months.

## photo_moderation · T *(Tier 3 — proposed)*
Pre-publish vision check on `gallery` uploads: tagged-only children visible, no PII in background.

### Tasks
- [ ] Vision model inference on the teacher's device (TFLite / Core ML) for first pass; server-side for second pass.
- [ ] Suggest crops; teacher confirms before publish.
- [ ] Reject obviously-unsafe content (e.g., screen with another child's data visible).

## chat_sentiment · B *(Tier 3 — proposed)*
PT-BR-aware sentiment scorer on incoming parent messages; high-anxiety messages get a priority push on the teacher side.

### Tasks
- [ ] Per-message sentiment classification (server-side; cached for re-use).
- [ ] Priority push channel separate from default chat push.
- [ ] Opt-out for parents who don't want their messages classified.

## parent_faq_assistant · P *(Tier 3 — proposed)*
PT-BR / EN RAG over school-admin-uploaded docs (handbook, calendar, policies). Lives as "Ask the school" tile.

### Tasks
- [ ] School admin uploads docs via web (out of scope of mobile).
- [ ] Vector store per `school_id`.
- [ ] Citations in every answer (link back to the source page in the doc).
- [ ] Escalate to teacher when confidence is low.

## anomaly_alerts · admin/T *(Tier 3 — proposed, primarily server-side)*
Detect: child absent N consecutive days; behavior-rating drop; missed medication.

### Tasks
- [ ] Server-side daily cron over diary + attendance + medicine records.
- [ ] Push to assigned teacher + school admin (not to parent directly).
- [ ] Tunable thresholds per school.

---

## (NOT building — explicit non-goals from §9.3)

- ❌ **IP camera integration** — LGPD risk for a children's product in Brazil; brand damage if a stream is breached. Document this decision when next reviewed; do not entertain in sales discovery.
- ❌ **HR / payroll module** — scope creep; if a school needs it they have dedicated HR tools.
- ❌ **Full discovery / marketplace pivot** — that is a different business model (B2B → B2B2C with two-sided flywheel). Evaluate as a separate product, not as a feature.

---

## Cross-feature tasks

### From the multi-expert review ([review.md](review.md))
- [x] **(P0)** ~~Rotate the Android keystore~~ — *Code-side: 2026-05-14 keystore + key.properties + all `google-services.json` + `GoogleService-Info.plist` untracked via `git rm --cached`; `.gitignore` hardened. **Still pending (external):** rotate in Play Console + scrub git history. See [docs/SECURITY-INCIDENT-KEYSTORE.md](../docs/SECURITY-INCIDENT-KEYSTORE.md).*
- [x] **(P0)** Fix iOS bundle IDs in `project.pbxproj`. *Fixed 2026-05-14: `com.algoriza.disneyNew` → `criarte`, `profedisneyNew` → `profecriarte`. Hardcoded `/Users/ahmedemad/...` paths replaced with `$(SRCROOT)/...`. Deployment target unified at 13.0.*
- [x] **(P0)** Add `PrivacyInfo.xcprivacy` manifest. *Fixed 2026-05-14.*
- [x] **(P0)** Pin Android `targetSdkVersion 34+`. *Fixed 2026-05-14: pinned to 34; AGP bumped to 7.4.2; Kotlin to 1.8.22.*
- [x] **(P0)** Lower Dio timeouts. *Fixed 2026-05-14: 20s connect / 30s receive / 60s send.*
- [x] **(P0)** Replace every `mainKey.currentContext?.isParents/isProfessors` call site. *Fixed 2026-05-14: new `core/user/current_role.dart` + process-wide `AppFlavor.current`; **18 sites swept** (initial sweep of 14 missed 4 sites in `login_impl.dart` — `sendSocialTokenToApi`, `signInWithGoogle` iOS client-ID branch, `register`, `loginWithEmail` — these were caught by the [login migration](login/tasks.md#constitution-drift-fixes) on 2026-05-14 and fixed in the same day's second sweep). Only commented-out references remain in `chat/data_sources/static_data.dart` and the wrapper-docs in `flavors/app_flavors.dart` + `core/user/current_role.dart`.*
- [x] **(P0)** Stop logging `Authorization` header + request body in Crashlytics. *Fixed 2026-05-14 with `_redactHeaders` + `_redactBody`.*
- [x] **(P0)** Handle 401 in `network_interceptor._handleOnError`. *Fixed 2026-05-14: forces `UserBloc.loggedOut()` once per session, re-entrancy-guarded.*
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

### External follow-ups from the 2026-05-14 remediation
*Full list with owners and details in [review.md → Open follow-up actions](review.md#open-follow-up-actions-external--cannot-be-done-from-the-codebase-alone).*

- [ ] **(P0, security)** Rotate the Android upload key in Play Console.
- [ ] **(P0, security)** Scrub git history of the leaked keystore + key.properties + committed Firebase configs.
- [ ] **(P0, security)** Enable Firebase App Check + restrict the Firebase API key by bundle/applicationId.
- [ ] **(P0, build)** Smoke-build both flavors after the AGP 7.4.2 / Kotlin 1.8.22 / google-services 4.4.2 bump.
- [ ] **(P0, iOS)** Regenerate iOS provisioning profiles for the corrected bundle IDs (`com.algoriza.criarte` / `.profecriarte`) and confirm App Store Connect entries.
- [ ] **(P0, iOS)** Validate `PrivacyInfo.xcprivacy` via Xcode → Validate App. Switch `aps-environment` to `production` for release.
- [ ] **(P0, manual QA)** Both flavors × both platforms smoke pass before next release.
- [ ] **(P1, backend)** Add a server-side `revoke_device_token` endpoint; call it from `UserBloc._signOutCleanup` before `NotificationService.clearToken()`.
- [ ] **(P1, backend)** Document FCM payload contract; agree on string-vs-object form for `sender` / `child`.
- [ ] **(P1, backend)** Review + deploy Firestore security rules for the new chat write paths; add the composite index for `orderBy('timestamp', desc) limit 50` if Firestore prompts.
- [ ] **(P1, security)** LGPD audit pass on Crashlytics breadcrumbs in staging to confirm redaction is comprehensive.
