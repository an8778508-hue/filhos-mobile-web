---
status: migrated
feature: notifications
migrated_from: lib/features/notifications/
migrated_date: 2026-05-14
---

# Implementation Plan: Notifications

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Two cooperating pieces:

1. **In-app inbox feature** at [lib/features/notifications/](../../lib/features/notifications/) — paginated REST list view (6 .dart files; bloc + events + state + model + repo + page).
2. **Core notifications service** at [lib/core/notifications_service/](../../lib/core/notifications_service/) (3 .dart files; service + tap-router + local-notification helper) — owns FCM lifecycle, foreground/background/terminated handlers, token refresh, and the deep-link router.

The split is intentional: the inbox is a "thin" feature with its own REST surface; FCM lifecycle is shared infrastructure that other features (chat, diary, events) depend on. The handler approval-gate (constitution principle VIII) is the load-bearing safety property.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `NotificationsBloc` is a real `Bloc<NotificationsEvents, NotificationsState>` (not Cubit)
- `firebase_messaging` 15.2 — FCM client; `getToken`, `onTokenRefresh`, `onMessage`, `onBackgroundMessage`, `onMessageOpenedApp`, `getInitialMessage`
- `firebase_core` 3.13 — required for background-isolate re-init
- `flutter_local_notifications` 19.2 — foreground notification presentation (channel + tap routing on Android)
- `permission_handler` 12.0 — `Permission.notification.request()` companion to `messaging.requestPermission`
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart)
- `flutter_screenutil` 5.9

**Storage**: HydratedBloc-backed `UserBloc.deviceToken` field (managed by [background_services/](../../lib/features/background_services/)). No Hive directly in this feature.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors. iOS needs `aps-environment` (set to `production` for release) and the `PrivacyInfo.xcprivacy` declaration of notification usage.

**Project Type**: Mixed — feature (`features/notifications/`) plus shared infrastructure (`core/notifications_service/`).

**Performance Goals**:

- Inbox page render ≤ 1 s on warm cache.
- FCM payload-to-tap-handler latency ≤ 100 ms in foreground.
- Cold-start deep-link (from terminated tap) ≤ 5 s on a typical 4G connection.

**Constraints**:

- Background isolate **must** re-init Firebase. Already done; preserve this through any refactor.
- `@pragma('vm:entry-point')` on the background handler is non-negotiable for AOT release.
- Notification permission must be requested *after* the user has privacy context (LGPD): currently called in `configureNotifications` which fires shortly after first launch — could be deferred to a more contextual moment.

**Scale/Scope**: 6 feature .dart files + 3 core .dart files. ~600 LOC combined.

## Constitution Check

- [x] **I. Feature-First Layout** — ⚠️ Layout variations:
  - `notifications_page.dart` lives at the feature root (not under `presentation/`).
  - `bloc/`, `repo/`, `models/` all at feature root (no `presentation/` wrapper).
  - Acceptable per [constitution principle I](../../.specify/memory/constitution.md) — mirrors the closest sibling style.
- [x] **II. Dependency Direction** — central registration. `NotificationsRepo` at [di.dart:73](../../lib/core/dependency_injection/di.dart#L73); `NotificationsBloc` at [di.dart:107](../../lib/core/dependency_injection/di.dart#L107). No feature-root `_di.dart` — matches constitution v1.2.0 central pattern. ✓
- [x] **III. Networking Contract** — `getNotificationsPaginated` uses `NetworkClient.handleRequest` returning `Either<Failure, List<NotificationModel>>`. ✓
- [x] **IV. Persistence Discipline** — no Hive in this feature; FCM token persistence is owned by `UserBloc` (HydratedCubit). ✓
- [x] **V. Flavor Branching** — no flavor branches. ✓
- [x] **VI. Localization** — `notifications` and `no_notifications` keys; server-supplied body/title. ✓
- [x] **VII. Chat Source of Truth** — N/A (notifications inbox is REST; chat surface is Firestore). The chat handler in `NotificationHelper` hands off to chat feature. ✓
- [x] **VIII. Approval Gate** — enforced in `handleNotificationTap` before any deep-link routing. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — ⚠️ minor drift: `Material(color: Colors.white)` ([notifications_page.dart:221](../../lib/features/notifications/notifications_page.dart#L221)) hardcoded. Should use `context.colors.*`. See [tasks.md T-fix-3](tasks.md).

## Project Structure

```text
lib/features/notifications/
├── bloc/
│   ├── notifications_bloc.dart           # Bloc<NotificationsEvents, NotificationsState>
│   ├── notifications_events.dart         # Fetch, FetchMore, Reload, ViewNotification (unused)
│   └── notifications_state.dart          # composed: NotificationsListState + ViewNotificationState
├── models/
│   └── notification_model.dart           # snake_case eventable_id / eventable_type
├── repo/
│   └── notifications_repo.dart           # NetworkClient.handleRequest → List<NotificationModel>
└── notifications_page.dart               # screen at feature root (variation)

lib/core/notifications_service/
├── notifications_service.dart            # configureNotifications, askPermission, onTokenRefresh, background handler
├── notification_helper.dart              # handleNotificationTap deep-link router with approval gate
└── local_notification_helper.dart        # flutter_local_notifications channel + payload routing
```

### Cross-feature touch points

- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — `UserBloc.updateDeviceToken` (token refresh sink) and `UserBloc.state.user.isApproval` (gate).
- **[lib/features/chat/](../../lib/features/chat/)** — `ChatScreen`, `ChatUser`, `ChildModel` referenced by `chat`-type taps.
- **[lib/features/diary/](../../lib/features/diary/)** — `DiaryScreen` + `ChildModel`.
- **[lib/features/settings/accept_event/](../../lib/features/settings/accept_event/)** — `AcceptEventScreen`.
- **[lib/features/settings/events/](../../lib/features/settings/events/)** — `EventsScreen`.
- **[lib/features/background_services/](../../lib/features/background_services/)** — `BackgroundServicesBloc` owns the `configureNotifications(onTokenRefresh: ...)` call.

**Structure Decision**: Two-tier (feature + core service) is intentional. The deep-link router must live in `core/` because it imports many features as navigation targets — placing it inside a feature would create circular import risk.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `NotificationHelper` in `core/` imports many features (chat, diary, settings, etc.) | The router needs to navigate to feature screens. Reverse direction (feature → router) creates circular deps. | Build a registry where each feature registers its own deep-link handler at startup. Worth doing if the deep-link surface grows; overkill today. See [tasks.md T-fix-4](tasks.md). |
| `notifications_page.dart` at feature root (no `presentation/` folder) | Mirror-closest-sibling — register, chat, and others vary similarly. | Standardizing now would just shuffle imports. Accepted. |
| `ViewNotificationState` + `ViewNotification` event are declared but unused | Originally planned mark-as-read flow that never shipped. | Delete or implement. See [tasks.md T-cleanup-1](tasks.md). |
| `IndexedStack(index: 0, children: [single child])` wrapper in the list view | Suggests filter (`all` vs `notRead`) was scaffolded but never finished. | Delete the wrapper; implement the filter; or keep the scaffold as a TODO. See [tasks.md T-cleanup-2](tasks.md). |
| Image field on `NotificationModel` is loaded but never rendered | Default bell icon used for every item. | Decide product intent: either render the image when present, or drop the field. See [tasks.md T-fix-2](tasks.md). |
