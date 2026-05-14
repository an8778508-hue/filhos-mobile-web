---
status: migrated
feature: notifications
flavor_scope: both
migrated_from: specs/features.md#notifications--b
migrated_date: 2026-05-14
---

# Feature Specification: Notifications

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/notifications/](../../lib/features/notifications/) + [lib/core/notifications_service/](../../lib/core/notifications_service/) + [features.md#notifications--b](../features.md#notifications--b).

## Flavor Scope

- **Target flavor(s)**: both. The notifications inbox, FCM token registration, and deep-link router are identical for parents and teachers.
- **Flavor-conditional behavior**: none observed.
- **Server role implication**: none directly. The `auth/notifications` endpoint is identical for both roles (server routes by token — confirmed in [notifications_repo.dart:8](../../lib/features/notifications/repo/notifications_repo.dart#L8)).

## User Scenarios & Testing

### User Story 1 — Read the in-app inbox (Priority: P1) 🎯 MVP

A user opens the Notifications tab (or arrives via deep-link fallback). They see a paginated, pull-to-refreshable list of past notifications.

**Why this priority**: This is the recovery surface for missed pushes — the only way to see history of school-side activity.

**Independent Test**: Navigate to `NotificationsPage`; observe `FetchNotifications` event fires, list renders, and infinite scroll requests page 2 when the viewport approaches the end.

**Acceptance Scenarios**:

1. **Given** a fresh page load, **When** `NotificationsPage` mounts, **Then** `BlocProvider` dispatches `FetchNotifications()` → `notificationsRepo.getNotificationsPaginated(1)` → list renders.
2. **Given** the user pulls down, **When** the gesture completes, **Then** `ReloadNotificationsEvent(completer)` re-fetches page 1 and the `RefreshIndicator` dismisses when `completer.complete()` fires.
3. **Given** the user scrolls within 25% of the bottom, **When** `scrollController` listener fires, **Then** `FetchMoreNotifications()` is dispatched.
4. **Given** the loaded page returned fewer than 10 items, **When** the bloc handles the response, **Then** `isLastPage = true` and subsequent `FetchMoreNotifications()` short-circuits (no further requests).
5. **Given** an empty result, **When** the list is empty, **Then** `NoNotifications` widget renders with localized "no notifications" copy and a bell icon.

---

### User Story 2 — Tap a notification (in-app or push) and deep-link (Priority: P1)

A user taps a notification — either in the list, in the OS shade (foreground/background), or on the lockscreen with the app terminated.

**Why this priority**: Push notifications are the school's primary signal to parents; broken deep-linking erodes trust fast.

**Independent Test**: Send a push with `data: {type: 'chat', sender: '{...}', child: '{...}'}` — confirm tap routes to `ChatScreen` with the correct contact + child models. Repeat for `event`, `diary`, and unknown types.

**Acceptance Scenarios**:

1. **Given** `type == 'chat'` with sender + child payloads, **When** the user taps, **Then** [NotificationHelper.handleNotificationTap](../../lib/core/notifications_service/notification_helper.dart#L34-L67) parses both (string-encoded OR nested-object form) and routes to `ChatScreen(contact, child)`.
2. **Given** `type == 'event'` (or `'events'`) with an `id`, **When** tapped, **Then** routes to `AcceptEventScreen(eventId)`.
3. **Given** `type == 'event'` without an `id`, **When** tapped, **Then** routes to `EventsScreen` (the events list).
4. **Given** `type == 'diary'` or `type == 'FieldAnswer'`, **When** tapped, **Then** routes to `DiaryScreen`.
5. **Given** an unknown `type`, **When** tapped, **Then** routes to `NotificationsPage` (in-app inbox) so the tap is never silently lost.
6. **Given** `UserBloc.user == null`, **When** the tap fires, **Then** routing short-circuits — splash will handle the cold-start case correctly.
7. **Given** `UserBloc.user.isApproval == false`, **When** the tap fires, **Then** routing short-circuits — pending users cannot reach protected features via a push tap.

---

### User Story 3 — Register & refresh FCM device token (Priority: P1, infrastructure)

The device token must be on the server and stay fresh through reinstalls, restores, GMS updates, and the 270-day Google rotation.

**Acceptance Scenarios**:

1. **Given** first login, **When** `LoginImpl.login` fires, **Then** `FirebaseMessaging.getToken()` runs and `device_token` rides in the request body.
2. **Given** FCM rotates the token mid-session, **When** `messaging.onTokenRefresh` fires, **Then** [NotificationService](../../lib/core/notifications_service/notifications_service.dart#L59-L63) invokes the callback wired in `init_dependencies.dart` to `UserBloc.updateDeviceToken`.
3. **Given** logout, **When** `UserBloc._signOutCleanup` runs, **Then** `NotificationService.clearToken()` calls `messaging.deleteToken()` so the next user on the device cannot inherit pushes.

---

### Edge Cases

- **Background isolate Firebase init**: Android's background handler runs in a separate isolate. Re-initializing Firebase inside [notificationBackgroundHandler](../../lib/core/notifications_service/notifications_service.dart#L157-L169) is required; the `@pragma('vm:entry-point')` annotation prevents tree-shaking in AOT release builds. Both are present.
- **`type` field may be `null`** (string interpolation `type.toString()` on null → `"null"`). The "unknown" fallback catches this.
- **`sender` / `child` payloads as JSON-strings**: FCM flattens `data:` payloads to strings; the parser tolerates both encodings.
- **App is in terminated state**: `FirebaseMessaging.getInitialMessage()` retrieves the cold-start message; handled exactly once.
- **`subScribeToTopic()` is an empty stub** ([notifications_service.dart:80](../../lib/core/notifications_service/notifications_service.dart#L80)) — features.md (P1).
- **Universal Links / App Links** are not yet wired for the iOS / Android manifests — features.md (P1).
- **Notification list snack-bar reads the wrong state slice**: [notifications_page.dart:63](../../lib/features/notifications/notifications_page.dart#L63) reads `state.viewNotificationsState.error!.message` when the trigger was a change in `state.notificationsListState.error`. **Bug** — see [tasks.md T-fix-1](tasks.md).

## Requirements

### Functional Requirements

- **FR-001**: System MUST present an in-app inbox at `NotificationsPage` with pagination (10/page), pull-to-refresh, and infinite scroll within 25% of the bottom.
- **FR-002**: System MUST fetch pages via `GET auth/notifications?page=N` through `NetworkClient.handleRequest` returning `Either<Failure, List<NotificationModel>>`.
- **FR-003**: System MUST detect last page via `result.length != 10` and short-circuit further `FetchMoreNotifications` events.
- **FR-004**: System MUST handle FCM messages in three states (foreground, background, terminated) via [NotificationService.configureNotifications](../../lib/core/notifications_service/notifications_service.dart#L40-L67).
- **FR-005**: System MUST route notification taps via `NotificationHelper.handleNotificationTap` by inspecting `type` (alias `eventable_type`) and `id` (alias `eventable_id`).
- **FR-006**: System MUST honor the approval gate before deep-linking — `UserBloc.user.isApproval == false` short-circuits to no-op.
- **FR-007**: System MUST listen on `FirebaseMessaging.onTokenRefresh` and surface refreshed tokens to `UserBloc.updateDeviceToken` via the `FcmTokenRefreshHandler` callback wired in `init_dependencies.dart`.
- **FR-008**: System MUST `deleteToken()` on logout (best-effort, non-fatal on failure).
- **FR-009**: System MUST tolerate FCM `sender` / `child` payloads in both JSON-string and nested-object forms.
- **FR-010**: System MUST re-initialize Firebase inside the Android background handler (different isolate) and annotate it `@pragma('vm:entry-point')`.

### Localization Requirements

Keys referenced (all in pt/en/ar today):

| Key | Use site |
|---|---|
| `notifications` | app-bar title |
| `no_notifications` | empty state copy |

Notification body/title come from the server payload — no client localization. Date formatting via [CustomDateFormats.formatDayMonthYear](../../lib/core/utils/date_formats.dart). Server should localize content based on `Accept-Language` (or the user's chosen lang stored on the server).

### Backend Touchpoints

- **REST**: `GET auth/notifications?page=N` — paginated, 10 per page. Response: `{data: [NotificationModel...]}`.
- **FCM**: token registration via login bodies; refresh via `onTokenRefresh`; foreground/background/terminated handlers wired.
- **FCM payload contract** (`type` / `eventable_type` and `id` / `eventable_id`):
  - `chat` — payload also carries `sender` (ChatUser JSON) and optional `child` (ChildModel JSON), each in string or object form
  - `event` / `events` — optional `id`
  - `diary` / `FieldAnswer` — no payload args; routes to the diary screen
  - any other value — routes to in-app inbox
- **No Firestore in this feature** directly (chat handler hands off to chat feature which is Firestore-backed).

### Permissions & Approval Gate

- iOS / Android **notification permission** is requested by [NotificationService.askPermission](../../lib/core/notifications_service/notifications_service.dart#L26-L37) at first run (called from `configureNotifications`).
- **Approval gate** enforced inside `handleNotificationTap` — pending users cannot deep-link into protected features.

### Key Entities

- **`NotificationModel`** ([model](../../lib/features/notifications/models/notification_model.dart)) — `{id, title, image, body, date?, read?, notified?, eventable_id?, eventable_type?}`. All optional fields are typed `String?` with `validateString` defensive parsing. ⚠️ `eventable_id` / `eventable_type` are snake_case identifiers in Dart — would normally be camelCase.
- **`NotificationsListState`** — `{notifications: List<NotificationModel>, loading: LoadingType?, error: Failure?}` with named transitions `fetching`, `reloading`, `loadingMore`, `success`, `successMore`, `failed`.
- **`ViewNotificationState`** — `{id, success, loading, error}` for a per-notification "mark as read" flow. **Declared but unused.** `ViewNotification` event exists; no `on<ViewNotification>` handler.

## Success Criteria

- **SC-001**: The inbox renders within 1 second of tab open on a typical 4G connection.
- **SC-002**: A pushed `type: 'chat'` tap from terminated state opens the correct chat thread within 3 seconds of cold start.
- **SC-003**: After Google rotates the FCM token, the server receives the new token within one app session.
- **SC-004**: A pending-approval user tapping any push lands on `your_account_under_review` — never on a protected screen.

## Assumptions

- The backend sends notifications via FCM HTTP v1 with `data:` payloads (not just `notification:`). Otherwise the deep-link router never sees the routing fields when the app is in the background.
- The `data` payload always includes a usable `type` or `eventable_type` (the unknown-fallback catches genuinely-unknown types, but is not meant as the primary path).
- Token refresh latency is acceptable — if the user logs out before `onTokenRefresh` fires, the server still has the previous token registered (acceptable due to LGPD-aware `deleteToken` on logout).
