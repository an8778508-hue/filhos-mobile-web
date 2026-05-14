---
status: migrated
feature: background_services
migrated_from: lib/features/background_services/
migrated_date: 2026-05-14
---

# Implementation Plan: Background Services

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/background_services/spec.md](spec.md) and code in [lib/features/background_services/](../../lib/features/background_services/).

## Summary

`BackgroundServicesBloc` is a one-shot orchestrator dispatched from the two post-login mount points (`MainScreen`, `YourAccountUnderReviewScreen`). On a single `CallServices` event it (a) wires FCM handlers via `NotificationService.configureNotifications` with an `onTokenRefresh` callback, (b) kicks off `ChatBloc.GetLastMessages`, (c) refreshes `UserBloc` from server, (d) PUTs the current FCM device token.

The state machine is intentionally trivial — `BackgroundServicesInitial` is the only state and never changes. This is **infrastructure code**, not a user-facing feature.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `BackgroundServicesBloc` is a `Bloc<E, S>` (not a Cubit, even though there is one event and one state — see Complexity Tracking).
- `get_it` 8 — `BackgroundServicesInjection` registered in [lib/init_dependencies.dart](../../lib/init_dependencies.dart).
- `firebase_messaging` 15.2 — via `NotificationService` (`core/notifications_service/`).
- `equatable` — event/state equality.

**Storage**: none directly. `UserBloc` HydratedBloc state is mutated via `getUserData`.

**Testing**: none today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile **infrastructure** feature; no presentation layer.

**Performance Goals**: `CallServices` returns control to the UI thread within ~100 ms (everything but `await getUserData()` is fire-and-forget). The await is acceptable because the screen is already painted.

**Constraints**:

- Must run on every mount of `MainScreen` / `YourAccountUnderReviewScreen` regardless of `UserBloc` hydration state — early-return after wiring `configureNotifications`, never *before*.
- Must not block the UI; `chatBloc.add(...)` and `userBloc.updateDeviceToken()` are not awaited.
- Must coexist with the cross-feature [splash bootstrap gap](../features.md#splash--b) — splash currently kicks off `getUserData` before `UserBloc` finishes hydrating; if that's later corrected, this bloc still runs `getUserData` once more on `MainScreen` and that's fine.

**Scale/Scope**: 4 .dart files (`bloc/{event,state,bloc}.dart` + `background_services_di.dart`).

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/background_services/` with `bloc/` and `background_services_di.dart` at the feature root. Matches constitution. ✓
- [x] **II. Dependency Direction** — imports `core/notifications_service`, `core/user`, `core/dependency_injection`, and `features/chat/presentation/bloc/chat_bloc.dart`. The chat-bloc cross-feature import is the only non-core dep — accepted because this bloc is *the* orchestrator and must reach into other features by design.
- [x] **III. Networking Contract** — no direct REST; downstream calls go through `NetworkClient`. ✓
- [x] **IV. Persistence Discipline** — no direct Hive use. ✓
- [x] **V. Flavor Branching** — no `mainKey.currentContext` usage. ✓
- [x] **VI. Localization** — N/A (no user strings).
- [x] **VII. Chat Source of Truth** — N/A directly; defers to chat feature.
- [x] **VIII. Approval Gate** — by design **runs before the gate**; this is the bloc that *refreshes* `isApproval`.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — N/A.

## Project Structure

### Documentation (this feature)

```text
specs/background_services/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/background_services/
├── background_services_di.dart                # BackgroundServicesInjection.init()
└── bloc/
    ├── background_services_bloc.dart          # Bloc<E, S>; the only logic site
    ├── background_services_event.dart         # sealed CallServices : BackgroundServicesEvent
    └── background_services_state.dart         # sealed BackgroundServicesInitial : BackgroundServicesState
```

### Cross-feature touch points

- [lib/core/notifications_service/notifications_service.dart](../../lib/core/notifications_service/notifications_service.dart) — `configureNotifications({onTokenRefresh})`, `clearToken()`.
- [lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart) — `getUserData`, `updateDeviceToken`, `_signOutCleanup`.
- [lib/features/chat/presentation/bloc/chat_bloc.dart](../../lib/features/chat/presentation/bloc/chat_bloc.dart) — `GetLastMessages` event handler.
- [lib/features/main/presentation/main_screen.dart](../../lib/features/main/presentation/main_screen.dart) — `CallServices()` dispatch.
- [lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart) — `CallServices()` dispatch.

**Structure Decision**: Keep current layout. The lack of a `presentation/` folder is correct for a no-UI orchestrator.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `Bloc<E, S>` with one event and one immutable state | Future events (e.g., explicit `RefreshUser`, `StartApprovalPoll`) are planned; the `Bloc` shape leaves room for `on<...>` typed handlers. | Cubit with a single `call()` method is leaner; but a `Bloc` matches the open-event design and is one factory more. Acceptable. |
| Mount-driven cadence (no `Timer.periodic`) | Avoids battery / backend cost of always-on polling; the user *will* re-mount in normal app usage. | Add a polling timer for `YourAccountUnderReviewScreen` only — see [tasks.md T-fix-2](tasks.md). |
| `configureNotifications` re-wired on every `CallServices` | Simpler than tracking a "wired once" flag in the singleton. | Cache the wired flag inside `NotificationService` — see [tasks.md T-fix-3](tasks.md). |
| `chatBloc.add(GetLastMessages())` from a non-chat bloc | The orchestrator pattern intentionally crosses features. | Move the trigger inside `ChatBloc.initState` of a chat-list screen; rejected because the chat list is fetched lazily on tab-open today and stale data is a known UX gap. |
