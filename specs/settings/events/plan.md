---
status: migrated
feature: settings/events
migrated_from: lib/features/settings/events/
migrated_date: 2026-05-14
---

# Implementation Plan: Events

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/events/spec.md](spec.md) and code in [lib/features/settings/events/](../../../lib/features/settings/events/).

## Summary

Events tab — the second-most-used surface for parents and teachers. Two viewing modes (calendar+day-events vs grouped-list) sharing one bloc. Listens on a global event bus for RSVP / creation signals to re-fetch. The screen has a known **P0 EventBus subscription leak** noted in [features.md#settings--b](../../features.md#settings--b).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0`.

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `EventsBloc extends Bloc<EventsEvent, EventsState>`.
- `equatable` — sealed `EventsEvent` + `EventsState` hierarchies.
- `dartz` — `Either<Failure, T>`.
- `intl` — `DateFormat('EE dd MMM,yyyy')`.
- `flutter_screenutil` — sizing.
- `get_it` — `di<EventsBloc>` factory via `EventsInjection`.
- `lib/core/event_bus.dart` — global bus for cross-feature signals.

**Storage**: none.

**Testing**: none.

**Target Platform**: iOS + Android, both flavors. Reached via `MainScreen` page id `events`, **not** from the settings shell despite the folder location.

**Project Type**: Flutter mobile feature with abstract repo + concrete impl + DI injection class.

**Performance Goals**: Day-list refresh ≤ 1-2s. Calendar widget should not rebuild more than necessary.

**Constraints**:

- The EventBus subscription must outlive a rebuild but not a `dispose`. Today it's re-created on every build — see T-fix-1.
- The `professorEvents` / `singleDayEvents` `ValueNotifier`s are mutated alongside bloc state — readers must not assume single source of truth.

**Scale/Scope**: 9 files, ~600 LOC.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/`, `data_source/`, `widgets/`, screen at root. ✓
- [x] **II. Dependency Direction** — imports `lib/core/*`, `lib/features/diary/models/school_item.dart`, `lib/features/home/widgets/event_item.dart`. The `home/widgets` reach-across is a smell. ⚠️
- [x] **III. Networking Contract** — `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — `LocalDatabaseRepo` injected but unused. Same pattern as announcements.
- [x] **V. Flavor Branching** — `isCurrentUserProfessor` is referenced in the repo's endpoint getter, but **both branches return the same string** — dead code (see tasks.md T-cleanup-2).
- [x] **VI. Localization** — `events`, `no_events`. Date format not localized.
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit (downstream of MainScreen).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h/.w/.csh/.csw/.sp/.r` + `context.colors.*` throughout. ✓

## Project Structure

### Documentation (this feature)

```text
specs/settings/events/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/events/
├── event_screen.dart                              # 🐛 EventBus leak at line 56
├── bloc/
│   ├── events_bloc.dart
│   ├── events_event.dart                          # sealed FetchDataEvent / FetchDayEvent / Fetched*
│   └── events_state.dart                          # sealed Initial / Error / Loading / Success
├── data_source/
│   ├── events_di.dart                             # EventsInjection
│   ├── events_impl.dart                           # concrete; query-param filter expansion
│   └── events_repo.dart                           # abstract + dead role-branch endpoint
└── widgets/
    ├── events_calendar.dart                       # calendar widget
    └── event_review_button.dart                   # calendar/list toggle button
```

### Cross-feature touch points

- [lib/features/home/widgets/event_item.dart](../../../lib/features/home/widgets/event_item.dart) — `EventItem` widget (shared with Home).
- [lib/features/diary/models/school_item.dart](../../../lib/features/diary/models/school_item.dart) — `SchoolItemType.parentType` / `.childType` for filter expansion.
- [lib/features/settings/accept_event/](../../../lib/features/settings/accept_event/) — RSVP / approval flow that emits `EventAcceptedOrRejected` on `eventBus`.
- [lib/core/event_bus.dart](../../../lib/core/event_bus.dart) — bus singleton.
- [lib/features/main/presentation/main_screen.dart:132](../../../lib/features/main/presentation/main_screen.dart#L132) — `PageID.events` mount point.
- [lib/core/notifications_service/notification_helper.dart](../../../lib/core/notifications_service/notification_helper.dart) — push deep-link target.

**Structure Decision**: standard abstract-repo + impl + injection pattern.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| EventBus subscription created inside `Builder.builder` ([event_screen.dart:56](../../../lib/features/settings/events/event_screen.dart#L56)) | Convenient access to the `BlocProvider`-scoped context. | **P0 bug.** Move to `initState` and store the context-provided bloc via `read`. **See tasks.md T-fix-1.** |
| Side-channel `ValueNotifier`s next to bloc state | Faster partial rebuilds without re-emitting `EventsState`. | A `MultiBlocSelector` + state with the right shape would obviate them. **See tasks.md T-fix-3.** |
| `_basicErrorHandling` extension dead | Boilerplate from sibling features. | Delete. **See tasks.md T-cleanup-1.** |
| Dead role-branch in `getEventsEndpoint` | Vestigial. | Delete; both branches equal. **See tasks.md T-cleanup-2.** |
| `LocalDatabaseRepo` unused dependency | Boilerplate. | Drop. **See tasks.md T-cleanup-3.** |
