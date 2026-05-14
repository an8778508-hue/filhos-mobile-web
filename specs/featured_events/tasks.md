---
status: migrated
feature: featured_events
migrated_from: specs/features.md#featured_events--b
migrated_date: 2026-05-14
---

# Tasks: Featured Events

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#featured_events--b](../features.md#featured_events--b).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

**Organization**: This is a **migration** of an existing feature. Most implementation tasks are already done (`[x]`).

## Migration summary

- 4 .dart files mapped: `bloc/featured_events_bloc.dart`, `bloc/featured_events_state.dart`, `featured_events_screen.dart`, `featured_events_screen_old.dart` (legacy, unreferenced).
- DI registration discovered in [core/dependency_injection/di.dart:125](../../lib/core/dependency_injection/di.dart#L125), not in a per-feature `featured_events_di.dart`.
- Sole mount/trigger: [main_screen.dart:38, 50-62](../../lib/features/main/presentation/main_screen.dart#L38).
- Hive key: `seen_featured_events` ([local_db_repo.dart:55](../../lib/core/local_db/local_db_repo.dart#L55)).

## Phase 1: Setup — ✅ Complete

- [x] **T-001**: Create feature directory [lib/features/featured_events/](../../lib/features/featured_events/) with `bloc/` and root screen.
- [x] **T-002**: Add `seenFeaturedEvents` key + reader/writer support to `LocalDatabaseRepo`.
- [x] **T-003**: Register `FeaturedEventsBloc` factory in DI.
- [x] **T-004**: Provide `FeaturedEventsBloc` in `MainScreen.providers` ([main_screen.dart:67](../../lib/features/main/presentation/main_screen.dart#L67)).

## Phase 2: User Story 1 — Surface unseen featured events (P1) — ✅ Complete

- [x] **T-010**: Implement `FeaturedEventsBloc.fetch()` → `eventsRepo.getProfessorEvents(null, featured: true)` returning `Either<Failure, List<EventGenericModel>>` ([featured_events_bloc.dart:14-26](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L14-L26)).
- [x] **T-011**: Flatten `List<EventGenericModel>` to `List<EventModel>` and filter out previously seen IDs.
- [x] **T-012**: Persist seen IDs to Hive via `LocalDatabaseRepo` and keep an in-memory mirror.
- [x] **T-013**: Wire `MainScreen.initState` to trigger `fetch()` and listen to state via `BlocListener` to `FeaturedEventsScreen.open(context)`.

## Phase 3: User Story 2 — Details / image-viewer hooks (P2) — ✅ Complete

- [x] **T-020**: `Details` CTA caches the current id, pushes `AcceptEventScreen`, and on return calls `nextPage()`.
- [x] **T-021**: Tapping the card's image opens `PhotoViewer` with `photo_view` zoom + hero animation tag.
- [x] **T-022**: `Skip` and `Remind later` advance the page; `Skip` also caches.
- [x] **T-023**: Auto-close the dialog when the filtered list becomes empty ([main_screen.dart:58-62](../../lib/features/main/presentation/main_screen.dart#L58-L62)).

## Phase 4: Gaps & cleanups

### Constitution drift fixes

- [ ] **T-fix-1** [housekeeping] **Carry-over from [features.md `## featured_events · B`](../features.md#featured_events--b)**: "Track 'seen' featured events in Hive (`seenFeaturedEvents`) to dedupe badges." Status: **already implemented** in code ([featured_events_bloc.dart:30-37](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L30-L37)) — features.md bullet is stale and should be ticked. *Action: mark complete in features.md.*

- [ ] **T-fix-2** [P2] **Carry-over from [features.md `## featured_events · B`](../features.md#featured_events--b)**: "Add empty/error states." Today the bloc swallows `Left(Failure)` by emitting `asFailed(l)` but no UI consumes the error state; the dialog simply never opens. Add a Snackbar (or silent log) on failure, and consider a "no upcoming featured events" empty state if the marketing team ever wants one.

- [ ] **T-fix-3** [P2] Extract DI registration into a dedicated `lib/features/featured_events/featured_events_di.dart` implementing `DependencyInjection`, and call it from [lib/init_dependencies.dart](../../lib/init_dependencies.dart) — mirrors the constitution's feature-first DI convention.

- [ ] **T-fix-4** [P2] Replace `Colors.black12` ([featured_events_screen.dart:158](../../lib/features/featured_events/featured_events_screen.dart#L158)) and `Colors.black38` ([featured_events_screen.dart:170](../../lib/features/featured_events/featured_events_screen.dart#L170)) with `context.colors.*` to align with the cross-feature [hardcoded colors sweep](../features.md#cross-feature-tasks).

- [ ] **T-fix-5** [P3] Expire seen-IDs after N days (e.g., 90) so that schools that recycle ids don't permanently silence a future featured event. Optional; coordinate with backend on id-stability contract first.

### Code hygiene

- [ ] **T-cleanup-1** Delete [lib/features/featured_events/featured_events_screen_old.dart](../../lib/features/featured_events/featured_events_screen_old.dart). Grep confirms no imports reference it.

- [ ] **T-cleanup-2** Remove stray `print` at [featured_events_screen.dart:130](../../lib/features/featured_events/featured_events_screen.dart#L130) and the imports it brought along (`global_functions` is also used elsewhere; only the call site needs removing). Part of the cross-feature [logger task](../features.md#cross-feature-tasks).

- [ ] **T-cleanup-3** Move `featuredDialogOpened` flag from `MainScreen` into the bloc's state. Today the flag lives in the screen's `State` object and is the only safeguard against double-open; relocating it removes a stateful side channel.

### Tests (aspirational)

- [ ] **T-test-1** [P] Cubit test for `FeaturedEventsBloc.fetch()` covering: fresh device (no seen ids), all-seen filter, repo failure.
- [ ] **T-test-2** [P] Cubit test for `cache(id)` round-trip with `LocalDatabaseRepo` mocked.
- [ ] **T-test-3** Widget test for the dialog open/close lifecycle via the `BlocListener` in `MainScreen`.

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** [X] After T-fix-3 (DI extraction) run `flutter analyze`; expect no new warnings.
- [ ] **TX02** [X] Smoke-build both flavors and verify the carousel opens with a seeded featured event on each.

## Dependencies & Execution Order

- **Phases 1–3 are complete.**
- **Phase 4** order:
  1. T-cleanup-1 (delete dead file) — zero risk.
  2. T-cleanup-2 (drop stray `print`) — zero risk.
  3. T-fix-3 (DI extraction) — mechanical, mirrors siblings.
  4. T-fix-2 (empty/error states) — needs design input.
  5. T-fix-4 (hardcoded colors) — part of broader sweep.
  6. T-cleanup-3 + T-fix-5 — optional.

## Gaps found

- The legacy `featured_events_screen_old.dart` is dead code with an additional `TextHtml` description rendering and a date/range header that the active screen lacks. If the design team wants to keep that richer card layout, the active screen should adopt those blocks before deleting the legacy file. See [tasks.md T-cleanup-1](#code-hygiene).
- The repository call relies on the `events` endpoint being writable from both flavors. If the backend ever splits this into `parent/events` vs `professors/events`, [events_repo.dart:9-10](../../lib/features/settings/events/data_source/events_repo.dart#L9-L10) must change before this feature can keep working.
- No analytics event today on "featured event surfaced" or "details tapped". If marketing wants to measure CTR, add a `firebase_analytics` event (part of the cross-feature [analytics task](../features.md#cross-feature-tasks)).
