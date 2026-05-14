---
status: migrated
feature: background_services
flavor_scope: both
migrated_from: specs/features.md#background_services--b
migrated_date: 2026-05-14
---

# Feature Specification: Background Services

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/background_services/](../../lib/features/background_services/), [lib/core/notifications_service/](../../lib/core/notifications_service/), and the [features.md `## background_services · B`](../features.md#background_services--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores). The bloc is constructor-symmetric and has no flavor branches.
- **Flavor-conditional behavior**: none in this feature directly. Downstream calls (`UserBloc.getUserData`, `ChatBloc.GetLastMessages`) route by `isCurrentUserProfessor` internally.
- **Server role implication**: indirect via the downstream calls. `userBloc.updateDeviceToken` PATCH/PUTs the FCM device token to the role-appropriate endpoint server-side based on `Authorization`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Boot the post-login background work (Priority: P1) 🎯 MVP

When the user reaches `MainScreen` (or `YourAccountUnderReviewScreen`), the app fires a single `CallServices` event into `BackgroundServicesBloc`. The bloc:

1. Configures `NotificationService` (FCM + local notification handlers + token-refresh listener).
2. Returns early if `userBloc.state.user == null` (cold start before user hydration).
3. Triggers `chatBloc.add(GetLastMessages())` so chat conversation list is hot.
4. Awaits `userBloc.getUserData()` so the locally cached `UserModel` reflects the latest server-side approval / profile state.
5. Calls `userBloc.updateDeviceToken()` so the server has the current FCM token for this device.

**Why this priority**: Without this, push notifications are silent on new installs, the approval gate never refreshes for pending users, and chat threads appear stale.

**Independent Test**:
1. Cold-start the app, log in, reach `MainScreen`.
2. Confirm: `notificationService.configureNotifications` ran with an `onTokenRefresh` callback wired; `chatBloc.GetLastMessages` was dispatched; `userBloc.getUserData()` resolved; `userBloc.updateDeviceToken()` fired with a non-null token.

**Acceptance Scenarios**:

1. **Given** the user lands on `MainScreen`, **When** `initState` runs, **Then** `context.read<BackgroundServicesBloc>().add(CallServices())` is dispatched ([main_screen.dart:34](../../lib/features/main/presentation/main_screen.dart#L34)).
2. **Given** the user lands on `YourAccountUnderReviewScreen` (pending approval), **When** `initState` runs, **Then** the same `CallServices` event is dispatched ([your_account_under_review_screen.dart:25](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L25)) — this is the surface that re-fetches `user` to discover approval-flip.
3. **Given** `userBloc.state.user == null` (e.g., race during login), **When** `_callServices` runs, **Then** the bloc short-circuits after wiring `configureNotifications`, avoiding `null`-token PUTs ([background_services_bloc.dart:33](../../lib/features/background_services/bloc/background_services_bloc.dart#L33)).
4. **Given** FCM rotates the device token mid-session, **When** `messaging.onTokenRefresh` fires, **Then** the `onTokenRefresh` callback passed to `configureNotifications` calls `userBloc.updateDeviceToken()` ([background_services_bloc.dart:29-31](../../lib/features/background_services/bloc/background_services_bloc.dart#L29-L31)).

---

### User Story 2 - Refresh approval status by polling getUserData (Priority: P1)

A teacher / parent with `isApproval == false` lands on `YourAccountUnderReviewScreen`. The bloc calls `userBloc.getUserData()`, which refreshes the persisted `UserModel`. If the admin approves the account, the next `CallServices` cycle picks up `isApproval == true` and downstream screens can route the user out of the waiting room.

**Why this priority**: This is the **only** mechanism today by which a pending user discovers their account has been approved without manually logging out + in. Without this, the gate is one-way until restart.

**Independent Test**:
1. Land on `YourAccountUnderReviewScreen` with a pending account.
2. Approve the account in the admin console.
3. Trigger a re-mount of `YourAccountUnderReviewScreen` (e.g., re-open from background).
4. Confirm: `getUserData()` returns `isApproval == true`, and the listener / router transitions the user to `MainScreen`.

**Acceptance Scenarios**:

1. **Given** a pending account, **When** `CallServices` fires, **Then** `userBloc.getUserData()` is awaited and the new `UserModel` is emitted via `UserBloc` (Hydrated).
2. **Given** approval flips server-side, **When** the **next** `CallServices` event runs (re-mount), **Then** `userBloc.state.user.isApproval == true` and routing can advance.

> ⚠️ **Gap**: This is **not** a periodic poll. `CallServices` is dispatched **once** per mount of `MainScreen` / `YourAccountUnderReviewScreen` — there is no `Timer.periodic` or auto-refresh. A pending user staring at the waiting screen will *not* discover approval without manually leaving and returning. See [features.md `background_services` (P1)](../features.md#background_services--b) and [tasks.md T-fix-2](tasks.md).

---

### User Story 3 - Sync FCM device token on every cold path (Priority: P1, infrastructure)

The server must know the *current* FCM token for the *current* user on this device. This breaks when:

- A new install gets a fresh token.
- Google rotates the token (~270 days, after GMS update, after reinstall + restore).
- The user logs out as A and logs in as B on the same device.

The bloc handles all three: `configureNotifications` wires `onTokenRefresh`, and `updateDeviceToken` is called eagerly on mount.

**Acceptance Scenarios**:

1. **Given** a logged-in user, **When** `_callServices` runs, **Then** the explicit `userBloc.updateDeviceToken()` call at [line 39](../../lib/features/background_services/bloc/background_services_bloc.dart#L39) PUTs the token regardless of whether refresh has fired.
2. **Given** the FCM SDK rotates the token, **When** the `onTokenRefresh` stream emits, **Then** `NotificationService._tokenRefreshSub.listen` invokes the callback → `userBloc.updateDeviceToken()` ([notifications_service.dart:60-63](../../lib/core/notifications_service/notifications_service.dart#L60-L63)).
3. **Given** the user logs out, **When** `UserBloc._signOutCleanup` runs, **Then** `NotificationService.clearToken()` calls `messaging.deleteToken()` so the next user cannot inherit pushes ([user_bloc.dart:96](../../lib/core/user/bloc/user_bloc.dart#L96)).

---

### Edge Cases

- **Race: `CallServices` before `UserBloc` hydration**: handled by the `if (userBloc.state.user == null) return;` guard. The `configureNotifications` call still runs (it doesn't need a user) — push handlers are wired even pre-login so a cold-start deep-link tap from `getInitialMessage` can route correctly downstream.
- **`onTokenRefresh` fires when no user is logged in**: the callback calls `userBloc.updateDeviceToken()` unconditionally; `UserBloc.updateDeviceToken` should no-op when `state.user == null`. Verify in [user_bloc.dart:35](../../lib/core/user/bloc/user_bloc.dart#L35).
- **Re-mount loops**: `CallServices` will re-run on every `MainScreen.initState`. The bloc has no de-dupe, so `configureNotifications` is wired multiple times per session. `NotificationService` likely doesn't internally dedupe — if so, every remount adds another `onTokenRefresh` subscription. See [tasks.md T-fix-3](tasks.md).
- **Pending users never approved**: the only mechanism (US-2) is manual re-mount. No timeout, no "contact your school" CTA — captured in [`your_account_under_review` features.md](../features.md#your_account_under_review--b).
- **No back-off on `getUserData` failure**: a 401 / 500 silently fails; the next remount retries. Acceptable while the cadence is mount-driven, but if the team adds polling (US-2 gap), back-off must come with it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register a `BackgroundServicesBloc` as a factory in DI ([background_services_di.dart:11-12](../../lib/features/background_services/background_services_di.dart#L11-L12)).
- **FR-002**: System MUST register `NotificationService` as a `LazySingleton` ([background_services_di.dart:15](../../lib/features/background_services/background_services_di.dart#L15)).
- **FR-003**: System MUST dispatch `CallServices` on `MainScreen.initState` and on `YourAccountUnderReviewScreen.initState`.
- **FR-004**: On `CallServices`, the system MUST call `notificationService.configureNotifications` with an `onTokenRefresh` callback that invokes `userBloc.updateDeviceToken()`.
- **FR-005**: On `CallServices`, the system MUST short-circuit if `userBloc.state.user == null`, **after** wiring `configureNotifications` (so push handlers are registered for cold-start deep-link).
- **FR-006**: On `CallServices`, when a user is logged in, the system MUST dispatch `GetLastMessages` to `ChatBloc` so the conversation list is hot.
- **FR-007**: On `CallServices`, when a user is logged in, the system MUST `await userBloc.getUserData()` so `isApproval` and profile fields are fresh.
- **FR-008**: On `CallServices`, the system MUST call `userBloc.updateDeviceToken()` to PUT the current FCM token to the server.
- **FR-009**: System MUST ensure the FCM token refresh listener calls back to `UserBloc.updateDeviceToken()` per [features.md `notifications` (P0)](../features.md#notifications--b) — already wired.

### Localization Requirements

None — this feature is invisible to the user.

### Backend Touchpoints

- **REST**: indirect — `userBloc.getUserData()` GETs the user profile; `userBloc.updateDeviceToken()` PUT/POSTs the FCM token. Both via `NetworkClient.handleRequest`.
- **FCM**: `FirebaseMessaging.instance.onTokenRefresh` listened-to inside `NotificationService.configureNotifications`. Foreground / background / terminated handlers also wired inside `configureNotifications` (see [notifications/spec.md](../notifications/spec.md)).
- **Firestore**: indirect — `chat`'s last-messages stream (Firestore-backed) is kicked off via `GetLastMessages`.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **No** — the bloc runs **before** the approval check; in fact one of its purposes (US-2) is to *re-fetch* approval state.
- Device permissions: notification permission is requested inside `NotificationService.askPermission` (called by `configureNotifications`).

### Key Entities

- **`BackgroundServicesBloc`** — `Bloc<BackgroundServicesEvent, BackgroundServicesState>`. Sole event: `CallServices`. Sole state: `BackgroundServicesInitial`. Used as a one-shot trigger; the state machine is intentionally trivial.
- **`CallServices`** ([event](../../lib/features/background_services/bloc/background_services_event.dart)) — empty marker event.
- **`BackgroundServicesInitial`** ([state](../../lib/features/background_services/bloc/background_services_state.dart)) — the only state ever emitted; this bloc never reacts to its own state changes.
- **Dependencies injected**: `ChatBloc`, `UserBloc`, `NotificationService`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-install user, after login, has their FCM token registered server-side within 3 seconds of reaching `MainScreen` (network-dependent).
- **SC-002**: After Google rotates the token (forced via Firebase console "delete instance ID"), the new token reaches the server within one app session without an explicit user action — driven by the `onTokenRefresh` wiring.
- **SC-003**: A pending user whose admin approves their account discovers the change on the *next* re-mount of `YourAccountUnderReviewScreen` (worst-case: app brought to foreground from background). No auto-poll today.
- **SC-004**: Logging out as A and logging in as B on the same device results in the server receiving B's token registration and (via cross-feature `UserBloc._signOutCleanup`) the server losing A's token mapping.

## Assumptions

- `UserBloc.updateDeviceToken()` is null-safe when `state.user == null` (callback path).
- `NotificationService.configureNotifications` is idempotent per process (re-calling it doesn't double-subscribe to FCM streams). **Worth verifying** — see [tasks.md T-fix-3](tasks.md).
- `ChatBloc.GetLastMessages` is idempotent (can be dispatched repeatedly without rebuilding the stream from scratch).
- `MainScreen` mounts at most a small number of times per session (no nested tab-host that re-mounts repeatedly).
- The server tolerates duplicate `updateDeviceToken` PUTs with the same token (no rate-limit on this endpoint).
