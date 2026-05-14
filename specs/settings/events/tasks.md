---
status: migrated
feature: settings/events
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: Events

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/events/](../../../lib/features/settings/events/) with `bloc/`, `data_source/`, `widgets/`.
- [x] T002 Add localization keys (`events`, `no_events`).
- [x] T003 Register `EventsInjection().init()` at [di.dart:121](../../../lib/core/dependency_injection/di.dart#L121).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define sealed `EventsEvent` (`FetchDataEvent`, `FetchDayEvent`, `Fetched*`) and `EventsState`.
- [x] T011 Define abstract `EventsRepo` + concrete `EventsImpl`.
- [x] T012 Implement `getProfessorEvents(filterModel, {featured})` with full filter query-string expansion.
- [x] T013 Implement `getProfessorDayEvents(date, filterModel)` calling `GET events?date=Y-M-D`.

## Phase 3: User Story 1 — Browse events (P1) 🎯 MVP — ✅ Complete (with P0 bug)

- [x] T020 [US1] Implement [event_screen.dart](../../../lib/features/settings/events/event_screen.dart) with calendar + day-events list.
- [x] T021 [US1] Wire `BlocProvider(lazy: false)` to fire `FetchDayEvent` + `FetchDataEvent` on mount.
- [x] T022 [US1] Implement calendar tap → `FetchDayEvent(date, filterModel)`.
- [x] T023 [US1] Implement view-mode toggle (`eventWithImage`) between calendar and list views.
- [x] T024 [US1] Render filter chips removable via `removeTeacher() / removeLevel() / removeParent()`.

## Phase 4: User Story 2 — Pull-to-refresh (P2) — ✅ Complete

- [x] T030 [US2] Wire `RefreshIndicator.onRefresh` to re-fire whichever fetch matches the current view.

---

## Phase 5: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P0)** *(from [features.md#settings--b](../../features.md#settings--b))* **EventBus subscription leak.** `_sub = eventBus.on().listen(...)` lives inside the `Builder.builder` at [event_screen.dart:55-62](../../../lib/features/settings/events/event_screen.dart#L55-L62) and is recreated on every rebuild — earlier subscriptions are not cancelled because the assignment overwrites the reference but the underlying stream subscription is not disposed. Move the listener to `initState` (or `didChangeDependencies` if it needs `BlocProvider.of`) and cancel any prior subscription before reassigning.

- [ ] **T-fix-2** **(P2)** *(from [features.md#settings--b](../../features.md#settings--b))* Surface **upcoming RSVPs** and **history** as sub-views.

- [ ] **T-fix-3** **(P2)** Migrate the `ValueNotifier<List<EventModel>>`, `ValueNotifier<bool>`, `ValueNotifier<Failure?>` shadow-state into the `EventsState` itself. The side-channel notifiers make readers ambiguous and bypass the `equatable` props.

- [ ] **T-fix-4** **(P2)** Replace the catch-all `on<EventsEvent>` + internal `is` check with typed `on<FetchDataEvent>` / `on<FetchDayEvent>` handlers.

- [ ] **T-fix-5** **(P2)** Localize date headers (same as announcements).

### Code hygiene

- [ ] **T-cleanup-1** Delete the unused `_basicErrorHandling` extension at the bottom of [events_impl.dart](../../../lib/features/settings/events/data_source/events_impl.dart).
- [ ] **T-cleanup-2** Delete the dead role-branch in [events_repo.dart:9-12](../../../lib/features/settings/events/data_source/events_repo.dart#L9-L12) — `professorsEventEndpoint` and `parentsEventsEndpoint` both equal `"events"`. Pick one constant.
- [ ] **T-cleanup-3** Drop the `LocalDatabaseRepo` constructor dependency on `EventsBloc` — injected but never used.
- [ ] **T-cleanup-4** Remove `debugPrint('sssssssssssssssssssssss')` at [events_bloc.dart:51](../../../lib/features/settings/events/bloc/events_bloc.dart#L51).
- [ ] **T-cleanup-5** Delete commented add-button block and `Add` callback at [event_screen.dart:69-74](../../../lib/features/settings/events/event_screen.dart#L69-L74) — event creation is not a mobile-side flow.
- [ ] **T-cleanup-6** Once T-fix-1 lands, remove the `_sub?.cancel()` from `dispose` is OK (it would actually be the only correct cancel call). Verify only one stream is alive.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `FetchDayEvent` success populates `singleDayEvents` exactly once.
- [ ] **T-test-2** [P] Widget test confirming a single bus listener fires `onEventAcceptedOrRejected` exactly once per rebuild (regression for T-fix-1).
- [ ] **T-test-3** [P] [US1] Filter-chip removal re-fires the active fetch.

---

## Phase 6: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze` after fixes.
- [ ] **TX02** Manual test: subscribe → accept event from `accept_event` → verify single re-fetch (regression test for T-fix-1).

---

## Constitution Drift Fixes

- [ ] EventBus subscription leak — Principle X / common-sense.
- [ ] Side-channel `ValueNotifier` state — Principle (state discipline).
- [ ] Dead role-branch in endpoint constants.
- [ ] Reach into `lib/features/home/widgets/event_item.dart` from `settings/events/` — Principle II (cross-feature import). Move `EventItem` to a shared location if it's truly cross-feature, or keep duplication intentional.

## Gaps Found

- **EventBus listener leak (P0)** — the most-cited bug in this whole settings tree.
- **Side-channel `ValueNotifier` state** living alongside bloc.
- **`debugPrint('sssssss')`** spam.
- **Date headers not localized.**

## Notes

- The events screen is the **bottom-nav events tab** (via `MainScreen` `PageID.events`), not a Settings row. The Settings row has been commented out for a long time.
- `lib/features/settings/accept_event/` is the RSVP / approval flow downstream of `EventItem` taps; it emits `EventAcceptedOrRejected` on `eventBus`, which this screen listens for.
