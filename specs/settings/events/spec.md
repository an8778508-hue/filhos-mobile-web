---
status: migrated
feature: settings/events
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: Events

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/events/](../../../lib/features/settings/events/) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both. Same screen for parents and teachers; differences live in the destination flows (RSVP / approval) under [settings/accept_event/](../../../lib/features/settings/accept_event/).
- **Flavor-conditional behavior**: the screen itself has no `context.isParents` / `context.isProfessors` branching. Filtering uses `FilterModel` (server-side filter parameters). Add button was previously gated to teachers but is now commented out ([event_screen.dart:69-74](../../../lib/features/settings/events/event_screen.dart#L69-L74)).
- **Server role implication**: `EventsRepo.getEventsEndpoint` switches between `professorsEventEndpoint` / `parentsEventsEndpoint` via `isCurrentUserProfessor` — but **both constants resolve to `"events"`** ([events_repo.dart:9-11](../../../lib/features/settings/events/data_source/events_repo.dart#L9-L11)). The branch is dead. Server routes by token.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse events by day (calendar view) (Priority: P1) 🎯 MVP

A user opens the Events tab (from `MainScreen` `PageID.events`, not from Settings), sees a calendar, picks a date, and sees events for that day rendered as `EventItem` cards.

**Why this priority**: Core use case for both flavors. Events drive parent attendance and teacher logistics.

**Independent Test**:
1. Launch either flavor → bottom-nav `events` tab.
2. `FetchDayEvent(date: DateTime.now())` and `FetchDataEvent` fire on screen mount.
3. Calendar renders; tapping a date triggers `FetchDayEvent(date)`.
4. Day-events list shows `EventItem` cards.

**Acceptance Scenarios**:

1. **Given** a user opens the screen, **When** the `BlocProvider(lazy: false)` initializes, **Then** both `FetchDayEvent(DateTime.now())` and `FetchDataEvent` fire concurrently.
2. **Given** a user picks a calendar date, **When** `onPressed(DateTime date)` fires, **Then** the `dateTime` notifier updates and `FetchDayEvent(date, filterModel)` triggers `GET events?date=YYYY-M-D`.
3. **Given** the day-events list returns, **When** `singleDayEvents.value` updates, **Then** each event renders as `EventItem(eventModel: event, withImage: true)`.
4. **Given** the day-events list is empty, **When** `events.isEmpty`, **Then** `EmptyWidget(no_events, event_icon)` renders.
5. **Given** the user toggles to the **list-mode** button (`tab_2` icon), **When** `eventWithImage = false`, **Then** the screen shows `professorEvents` (grouped by date headers) instead of the calendar.
6. **Given** a filter is applied via `FilterSheet.openSheet`, **When** the user closes the sheet with a non-null filter, **Then** the active fetch is re-triggered with the new `FilterModel`.

### User Story 2 - Refresh events list (Priority: P2)

Pull-to-refresh re-fetches the currently displayed view (day or list).

**Acceptance Scenarios**:

1. **Given** the calendar view is active, **When** the user pulls to refresh, **Then** `FetchDayEvent(date: dateTime.value, filterModel)` fires.
2. **Given** the list view is active, **When** the user pulls to refresh, **Then** `FetchDataEvent(filterModel)` fires.

### Edge Cases

- **🐛 (P0) EventBus subscription leak** ([event_screen.dart:55-62](../../../lib/features/settings/events/event_screen.dart#L55-L62)) — `_sub = eventBus.on().listen(...)` is created inside the `Builder.builder` callback. Every rebuild creates a new subscription **without cancelling the previous** — only the most-recently-assigned subscription is captured. Listeners pile up; `EventAcceptedOrRejected` / `EventAdded` fire the same handler many times. Tracked in [features.md#settings--b](../../features.md#settings--b) and [tasks.md T-fix-1](tasks.md). Move into `initState`.
- **Identical endpoint constants for both roles** — see Flavor Scope.
- **Add button gated to teachers** is commented ([event_screen.dart:69-74](../../../lib/features/settings/events/event_screen.dart#L69-L74)); event creation lives elsewhere (probably backend admin / dashboard).
- **Filter button is `filterButton: false`** so the filter UI is hidden by default; `filterFunction` still wired up but unreachable from the UI.
- **`emit(EventsLoadingState())` runs twice on screen mount** because both `FetchDayEvent` and `FetchDataEvent` fire from `BlocProvider.create` and each emits loading state.
- **Catch-all `on<EventsEvent>`** with internal `is` checks — discouraged.
- **`debugPrint('sssssssssssssssssssssss')`** at [events_bloc.dart:51](../../../lib/features/settings/events/bloc/events_bloc.dart#L51) — debug spam.
- **`ValueNotifier` state lives alongside `Bloc` state** — `professorEvents`, `singleDayEvents`, `*Loading`, `*Failure` notifiers are mutated inside event handlers in addition to emitting bloc state. Mixing two state systems makes reads confusing.
- **Approval gate**: implicit (downstream of MainScreen).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render an `EventsCalendar` widget seeded with `DateTime.now()` and a single-day event list below it.
- **FR-002**: System MUST fetch the day events via `GET events?date=YYYY-M-D` on screen mount and on every calendar date tap.
- **FR-003**: System MUST fetch the grouped list of events via `GET events` (with optional filter params) for the list-view toggle.
- **FR-004**: System MUST support filtering by parent/child, level, and teacher via `FilterModel` query parameters (`filter[child][]`, `filter[parent][]`, `filter[level][]`, `filter[teacher][]`).
- **FR-005**: System MUST render `EventItem` cards (with `withImage` controlled by the calendar-vs-list toggle).
- **FR-006**: System MUST listen on `eventBus` for `EventAcceptedOrRejected` / `EventAdded` and re-fetch the active view when those fire.
- **FR-007**: System MUST cancel the `EventBus` subscription on dispose. **Today not enforced because the subscription is recreated on every build.**

### Localization Requirements

| Key | Use site |
|---|---|
| `events` | app bar title |
| `no_events` | empty state |

Date headers use hardcoded `EE dd MMM,yyyy` — not locale-aware.

### Backend Touchpoints

- **REST endpoints**:
  - `GET events` — list with optional filters `is_feature, filter[child][], filter[parent][], filter[level][], filter[teacher][]`.
  - `GET events?date=YYYY-M-D` — single-day events.
- **Headers**: standard.
- **Firebase**: not used.
- **Firestore**: not used.
- **EventBus** ([lib/core/event_bus.dart](../../../lib/core/event_bus.dart)) — listens for `EventAcceptedOrRejected` (emitted from accept_event RSVP flow) and `EventAdded` (emitted when an event is created).

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit).
- No device permissions.

### Key Entities

- **`EventModel`** ([lib/core/models/event_model.dart](../../../lib/core/models/event_model.dart)) — full event entity (startDate, endDate, requireApproval, …).
- **`EventGenericModel`** ([lib/core/models/event_generic_model.dart](../../../lib/core/models/event_generic_model.dart)) — date-grouped wrapper `{date, events: List<EventModel>}` used in list view.
- **`FilterModel`** ([lib/core/components/sheets/filter_sheet.dart](../../../lib/core/components/sheets/filter_sheet.dart)) — `{teacher, levels, parentOrChild}` filter selectors.
- **`EventBus` events**: `EventAcceptedOrRejected`, `EventAdded`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Day-event list updates within 1-2s of a calendar tap.
- **SC-002**: After T-fix-1, the bus listener fires exactly once per `EventAcceptedOrRejected` regardless of how many times the screen has rebuilt.
- **SC-003**: Filter chips removed from the chip list correctly re-fire the active fetch.
- **SC-004**: Empty state renders without crash.

## Assumptions

- The `events` endpoint is the same path for parents and teachers; the server uses the auth token to route.
- `FilterModel` query-string contract is server-supported.
- The active view (`eventWithImage` boolean) lives in widget state — switching tabs resets it to `true`.
- Event creation is not user-driven from this screen today; commented-out add button reflects that.
