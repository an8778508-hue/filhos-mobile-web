---
status: migrated
feature: background_services
migrated_from: specs/features.md#background_services--b
migrated_date: 2026-05-14
---

# Tasks: Background Services

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#background_services--b](../features.md#background_services--b).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

**Organization**: This is a **migration** of an existing feature.

## Migration summary

- 4 .dart files: `background_services_di.dart`, `bloc/background_services_{bloc,event,state}.dart`.
- One event (`CallServices`), one state (`BackgroundServicesInitial`), one logic path (`_callServices`).
- Dispatched from exactly two sites: [main_screen.dart:34](../../lib/features/main/presentation/main_screen.dart#L34) and [your_account_under_review_screen.dart:25](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L25).
- Wake-up frequency for `BackgroundServicesBloc`: **per mount**, not on a timer.

## Phase 1: Setup — ✅ Complete

- [x] **T-001**: Create `BackgroundServicesInjection` registering the bloc as a factory and `NotificationService` as a lazy singleton.
- [x] **T-002**: Register the injection in [lib/init_dependencies.dart](../../lib/init_dependencies.dart).
- [x] **T-003**: Provide `BackgroundServicesBloc` in `MainScreen.providers` ([main_screen.dart:64](../../lib/features/main/presentation/main_screen.dart#L64)).

## Phase 2: User Story 1 — One-shot CallServices orchestrator (P1) — ✅ Complete

- [x] **T-010**: Implement the `_callServices` handler running: `configureNotifications` → null-guard → `GetLastMessages` → `await getUserData` → `updateDeviceToken`.
- [x] **T-011**: Dispatch `CallServices` from `MainScreen.initState` and `YourAccountUnderReviewScreen.initState`.

## Phase 3: User Story 2 — Approval refresh via re-mount (P1) — ⚠️ Partial

- [x] **T-020**: Wire `userBloc.getUserData()` inside `_callServices` so a re-mount of `YourAccountUnderReviewScreen` pulls fresh `isApproval`.
- [ ] **T-021** [P1] **(from [features.md `background_services` P1)](../features.md#background_services--b))** Document the polling cadence and back-off for approval status. **Current cadence: mount-driven, no auto-poll.** Recommended next step: a `Timer.periodic(const Duration(seconds: 30), …)` started inside `YourAccountUnderReviewScreen.initState` (and cancelled in `dispose`) that re-dispatches `CallServices`, with exponential back-off on repeated failure.

## Phase 4: User Story 3 — FCM token sync (P1) — ✅ Complete

- [x] **T-030**: **(from [features.md `background_services` P0)](../features.md#background_services--b))** Add `FirebaseMessaging.onTokenRefresh` listener. *Fixed 2026-05-14: `CallServices` passes an `onTokenRefresh` callback to `NotificationService.configureNotifications` that invokes `userBloc.updateDeviceToken()`.*
- [x] **T-031**: Eagerly `updateDeviceToken` on every `CallServices` for the logged-in branch ([background_services_bloc.dart:39](../../lib/features/background_services/bloc/background_services_bloc.dart#L39)).
- [x] **T-032**: Logout: `UserBloc._signOutCleanup` calls `NotificationService.clearToken()` so the next user cannot inherit pushes ([user_bloc.dart:96](../../lib/core/user/bloc/user_bloc.dart#L96)).

## Phase 5: Gaps & cleanups

### Constitution drift fixes

- [ ] **T-fix-1** [P1] **Carry-over from [features.md `background_services` P1](../features.md#background_services--b)**: "Document the polling cadence and back-off for approval status." Resolved at the spec level here (see [spec.md US-2 Gap](spec.md#user-story-2---refresh-approval-status-by-polling-getuserdata-priority-p1)). Implementation work: add a periodic poll in `YourAccountUnderReviewScreen` with back-off — tracked at [T-021](#phase-3-user-story-2--approval-refresh-via-re-mount-p1--%E2%9A%A0%EF%B8%8F-partial).

- [ ] **T-fix-2** [P2] **Carry-over from [features.md `background_services`](../features.md#background_services--b)**: "Confirm token re-registration on user/account change." Today, on logout, `_signOutCleanup` calls `deleteToken`. On the *next* login, `LoginImpl.requestOTP/login` fetches a fresh `getToken()` and includes it in the auth body — so re-registration **is** wired by the login path, not by `BackgroundServicesBloc`. Verify the new token reaches `/auth/login` before any other authenticated request fires.

- [ ] **T-fix-3** [P1] **Singleton subscription leak**: `notificationService.configureNotifications(...)` re-runs on every `CallServices`. If `NotificationService` doesn't internally cancel its previous `onTokenRefresh` subscription / FCM listeners before re-subscribing, every remount of `MainScreen` adds another listener. Audit `notifications_service.dart` and either (a) cache "wired once" inside the singleton, or (b) cancel + recreate explicitly. *Subscription leak is implicitly suggested by [notifications_service.dart:60](../../lib/core/notifications_service/notifications_service.dart#L60) where `_tokenRefreshSub` is reassigned without prior `cancel`.*

- [ ] **T-fix-4** [P3] The bloc uses a single catch-all `on<BackgroundServicesEvent>` ([background_services_bloc.dart:19-23](../../lib/features/background_services/bloc/background_services_bloc.dart#L19-L23)) with an `if (event is CallServices)` branch. Convert to a typed `on<CallServices>` handler to match the pattern other reviewed blocs (chat, diary) are being moved toward — see [features.md chat / diary tasks](../features.md#chat--b).

### Code hygiene

- [ ] **T-cleanup-1** Convert `BackgroundServicesBloc` to a `Cubit` if no additional events are planned, OR commit to the `Bloc` shape and add typed handlers (T-fix-4). The current "Bloc-with-one-event" state is fence-sitting.

- [ ] **T-cleanup-2** Add a comment to `_callServices` documenting that the early `return` only fires after `configureNotifications` is wired — current code is correct but non-obvious.

### Tests (aspirational)

- [ ] **T-test-1** [P] Bloc test for `_callServices` with user logged in: verify `configureNotifications` called, `GetLastMessages` dispatched, `getUserData` awaited, `updateDeviceToken` invoked.
- [ ] **T-test-2** [P] Bloc test for `_callServices` with `userBloc.state.user == null`: verify `configureNotifications` *still* called, downstream calls skipped.
- [ ] **T-test-3** [P] Verify `onTokenRefresh` callback invokes `updateDeviceToken` via mocked `NotificationService`.
- [ ] **T-test-4** Approval-gate integration: pending user → admin approves → re-mount `YourAccountUnderReviewScreen` → expect router transitions to `MainScreen`.

## Phase 6: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-3 (subscription leak audit) — no new warnings.
- [ ] **TX02** [X] Smoke-test on both flavors with a pending account and an approved account.

## Dependencies & Execution Order

- **Phases 1–4 are mostly complete.**
- **Phase 5** order:
  1. T-fix-3 (subscription leak audit) — highest impact, low risk.
  2. T-fix-1 / T-021 (approval polling) — needs UX decision on cadence.
  3. T-fix-4 / T-cleanup-1 (Bloc vs Cubit shape) — pick one.
  4. Tests last, once the shape is settled.

## Constitution drift fixes (summary table)

| Drift | Source | Status |
|---|---|---|
| Approval polling cadence undocumented | features.md P1 | Documented in spec; impl pending (T-021) |
| Token re-registration on account change | features.md | Wired via login path; verify (T-fix-2) |
| Singleton `onTokenRefresh` subscription may leak | this migration | Open (T-fix-3) |
| Catch-all `on<BackgroundServicesEvent>` handler | this migration | Open (T-fix-4) |

## Gaps found

- **No auto-poll for approval**: a pending user has no way to discover approval without leaving and returning to the screen. Significant UX gap surfaced by this migration; matches [features.md `your_account_under_review` P0](../features.md#your_account_under_review--b) which mandates a test for the gate.
- **`NotificationService.configureNotifications` is non-idempotent**: based on the existing assignment to `_tokenRefreshSub` without prior cancel, re-mounting `MainScreen` likely leaks listeners. Verify and fix.
- **Bloc emits no state changes**: the orchestrator never moves out of `BackgroundServicesInitial`. If a future task wants to surface "approval polling in progress" or "token sync failed", a richer state machine will be required — keep this in mind when picking up T-021.
- **No metrics**: no `firebase_analytics` events on token sync success/failure, getUserData success/failure. Part of the cross-feature [analytics task](../features.md#cross-feature-tasks).
