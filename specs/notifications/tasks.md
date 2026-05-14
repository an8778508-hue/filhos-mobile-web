---
status: migrated
feature: notifications
migrated_from: specs/features.md#notifications--b
migrated_date: 2026-05-14
---

# Tasks: Notifications

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#notifications--b](../features.md#notifications--b).

**Tests**: No `test/` directory.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/notifications/](../../lib/features/notifications/) with `bloc/`, `models/`, `repo/`, and `notifications_page.dart` at feature root (variation)
- [x] T002 Localization keys (`notifications`, `no_notifications`) added to [localization_keys.dart](../../lib/core/localization/localization_keys.dart) + pt/en/ar JSONs
- [x] T003 ✅ DI placement uses central registration per [constitution v1.2.0 principle II](../../.specify/memory/constitution.md): [di.dart:73](../../lib/core/dependency_injection/di.dart#L73) (`NotificationsRepo`) + [di.dart:107](../../lib/core/dependency_injection/di.dart#L107) (`NotificationsBloc`).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `NotificationModel` with defensive `validateString` parsing
- [x] T011 Define composed `NotificationsState` = `NotificationsListState` + `ViewNotificationState` with `setNotificationsListState` / `setViewNotificationState` mutator helpers
- [x] T012 Implement `NotificationsRepo.getNotificationsPaginated(page)` via `NetworkClient.handleRequest` → `List<NotificationModel>`
- [x] T013 Wire FCM lifecycle in [NotificationService.configureNotifications](../../lib/core/notifications_service/notifications_service.dart#L40-L67): permission, iOS presentation options, foreground/background/terminated handlers, `onTokenRefresh` subscription
- [x] T014 Background isolate Firebase re-init in [notificationBackgroundHandler](../../lib/core/notifications_service/notifications_service.dart#L157-L169) with `@pragma('vm:entry-point')`
- [x] T015 Approval gate enforced in [NotificationHelper.handleNotificationTap](../../lib/core/notifications_service/notification_helper.dart#L34-L67)

## Phase 3: User Story 1 — In-app inbox (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement `NotificationsPage` with `BlocProvider` dispatching `FetchNotifications()` on mount
- [x] T021 [US1] `RefreshIndicator` wired to `ReloadNotificationsEvent(completer)`
- [x] T022 [US1] Infinite scroll: `scrollSetListener` triggers `FetchMoreNotifications()` within 25% of the bottom
- [x] T023 [US1] `isLastPage` short-circuit when result length < 10
- [x] T024 [US1] Empty state via `NoNotifications` widget with bell icon and `no_notifications` copy

## Phase 4: User Story 2 — Deep-link router (P1) — ✅ Complete

- [x] T030 [US2] **(P0)** Tolerate FCM `sender` / `child` payloads in both JSON-string and nested-object forms via `_parseEmbedded`. *Fixed 2026-05-14 per [features.md#notifications--b](../features.md#notifications--b)*
- [x] T031 [US2] **(P0)** Tolerate unknown `type` — fall back to in-app inbox so taps are never silently lost. *Fixed 2026-05-14*
- [x] T032 [US2] Route `chat` / `event` / `diary` / `FieldAnswer` types
- [x] T033 [US2] **(P0)** Approval gate inside `notification_helper.dart`. *Fixed 2026-05-14*
- [x] T034 [US2] Cold-start tap via `FirebaseMessaging.getInitialMessage()`; background tap via `onMessageOpenedApp`

## Phase 5: User Story 3 — FCM token lifecycle (P1) — ✅ Complete

- [x] T040 [US3] **(P0)** `FirebaseMessaging.onTokenRefresh` registered with `FcmTokenRefreshHandler` callback. *Fixed 2026-05-14 — `BackgroundServicesBloc` wires it to `UserBloc.updateDeviceToken`*
- [x] T041 [US3] `NotificationService.clearToken()` called from `UserBloc._signOutCleanup` on logout (best-effort)
- [x] T042 [US3] Token rides in login bodies as `device_token` field via `LoginImpl.login`

---

## Phase 6: Gaps & cleanups

### Bugs

- [x] **T-fix-1** **(P1)** [US1] ✅ **Fixed 2026-05-14** in [notifications_page.dart:60-66](../../lib/features/notifications/notifications_page.dart#L60-L66): snackbar now reads `state.notificationsListState.error` (the slice the `listenWhen` actually watches), with explicit null check instead of `validString` over a `Failure` type (`validString` is for strings) — closes both the wrong-state-slice and the latent null-deref risk in one edit.

- [ ] **T-fix-2** **(P2)** [US1] `NotificationModel.image` is parsed but never rendered ([notifications_page.dart:241-258](../../lib/features/notifications/notifications_page.dart#L241-L258)). Decide product intent: either render the image when `validString(notification.image)`, or drop the field.

- [ ] **T-fix-3** **(P2)** [theming] Hardcoded `Material(color: Colors.white)` ([notifications_page.dart:221](../../lib/features/notifications/notifications_page.dart#L221)) — replace with `context.colors.card` (or `scaffold`).

- [ ] **T-fix-4** **(P1)** [US2] *(from [features.md#notifications--b](../features.md#notifications--b))* Add Universal Links / App Links so cold-start push taps deep-link reliably from external sources (Android manifest needs `VIEW/BROWSABLE` filter; `Runner.entitlements` needs `applinks:`).

- [ ] **T-fix-5** **(P1)** [US3] *(from [features.md#notifications--b](../features.md#notifications--b))* Implement or remove the empty `subScribeToTopic()` stub at [notifications_service.dart:80](../../lib/core/notifications_service/notifications_service.dart#L80). If keeping, document the subscription strategy (per-school topic? per-child? broadcast?).

- [ ] **T-fix-6** **(P2)** [docs] *(from [features.md#notifications--b](../features.md#notifications--b))* Document the supported `eventable_type` values and their destinations in this spec and in the backend's payload contract.

- [ ] **T-fix-7** **(P2)** [UX] *(from [features.md#notifications--b](../features.md#notifications--b))* Add a "mark all as read" action. Wire the unused `ViewNotification` event or design a bulk-mark endpoint.

- [ ] **T-fix-8** **(P2)** [LGPD] Defer the iOS notification permission prompt to a more contextual moment. Today `configureNotifications` runs early in app boot; the prompt fires before the user has privacy context. Consider gating behind a first-screen "let's set up notifications" moment.

### Code hygiene

- [ ] **T-cleanup-1** Delete `ViewNotification` event ([notifications_events.dart:28-32](../../lib/features/notifications/bloc/notifications_events.dart#L28-L32)) and `ViewNotificationState` ([notifications_state.dart:81-109](../../lib/features/notifications/bloc/notifications_state.dart#L81-L109)) — both declared, no `on<ViewNotification>` handler exists. Or implement the mark-as-read flow per T-fix-7.

- [ ] **T-cleanup-2** Delete the `IndexedStack(index: 0, children: [single child])` wrapper ([notifications_page.dart:89-125](../../lib/features/notifications/notifications_page.dart#L89-L125)) — leftover scaffolding from an unfinished `NotificationType.all` vs `notRead` filter. Either implement the filter or drop the `notificationType` ValueNotifier too.

- [ ] **T-cleanup-3** Rename `eventable_id` / `eventable_type` to camelCase (`eventableId` / `eventableType`) in `NotificationModel`. The snake_case form is server-payload mirror; the Dart-side identifier should be conventional. JSON keys can stay snake_case in `fromJson`.

- [ ] **T-cleanup-4** Replace `debugPrint` cluster in `_listentToForgoundNotification` ([notifications_service.dart:96-114](../../lib/core/notifications_service/notifications_service.dart#L96-L114)) with a structured logger. Also fix the typo'd identifier `_listentToForgoundNotification` → `_listenToForegroundNotification`.

- [ ] **T-cleanup-5** Fix the typo'd identifier `_hanldeBackgroundMessageInteractions` and `_handleBankgroundPressed` ([notifications_service.dart:117](../../lib/core/notifications_service/notifications_service.dart#L117), [131](../../lib/core/notifications_service/notifications_service.dart#L131)).

### Architecture (deferred)

- [ ] **T-arch-1** **(P2)** Consider a deep-link router registry to break `NotificationHelper`'s many cross-feature imports (chat, diary, settings, events). Each feature registers its handler at startup; `NotificationHelper` looks up by `type`. Worth doing if the deep-link surface grows.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `FetchNotifications` happy path; failure path; pagination boundary (10-exactly vs 9-or-fewer).
- [ ] **T-test-2** [P] [US2] `NotificationHelper.handleNotificationTap` covering all 5 type branches + the two approval-gate short-circuits (`user == null`, `isApproval == false`).
- [ ] **T-test-3** [P] [US3] Token-refresh listener test: emit a fake `onTokenRefresh` event → assert callback invoked exactly once.

---

## Notes

- `auth/notifications` endpoint is shared across roles — server routes by token (confirmed in [notifications_repo.dart:8](../../lib/features/notifications/repo/notifications_repo.dart#L8)).
- `NotificationHelper` is the project's single deep-link router. New features that should be FCM-routable must add a `type` branch here AND update the spec's `eventable_type` table.
- Background isolate Firebase init + `@pragma('vm:entry-point')` are AOT-release-correctness gates — do not refactor without re-validating both flavors.
