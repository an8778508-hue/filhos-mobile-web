---
status: migrated
feature: home
migrated_from: specs/features.md#home--b
migrated_date: 2026-05-14
---

# Tasks: Home

**Input**: [spec.md](spec.md), [plan.md](plan.md), and [features.md#home--b](../features.md#home--b).

**Tests**: No `test/` directory.

**Organization**: This is a **migration** of an existing 16-file feature. Story labels map to user stories in [spec.md](spec.md): US1 = parent dashboard, US2 = teacher dashboard, US3 = cross-feature reactive refresh, X = cross-cutting.

---

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/home/](../../lib/features/home/) with `bloc/`, `data_source/`, `models/`, `widgets/` (note singular `data_source/`)
- [x] T002 Localization keys for `hello`, `events`, `my_children`, `no_children`, `sections` already in [localization_keys.dart](../../lib/core/localization/localization_keys.dart)
- [x] T003 Register `HomeImpl` + `HomeBloc` via [home_di.dart](../../lib/features/home/data_source/home_di.dart) wired through [init_dependencies.dart](../../lib/init_dependencies.dart)

---

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `HomeModel` with `events: List<EventModel>` and `children: List<ChildModel>` (note JSON key is `childs`, not `children`)
- [x] T011 Define sealed `HomeEvent` (`HomeFetchDataEvent`, `ReloadHomeFetchDataEvent`, `HomeFetchedSuccessfullyEvent`) — the third is currently unused
- [x] T012 Define sealed `HomeState` (`HomeInitial`, `HomeLoading`, `HomeFetchedSuccessfully`, `HomeError`)
- [x] T013 Define `HomeRepo` abstract contract with role-resolved `homeEndpoint` getter
- [x] T014 Implement `HomeImpl` using `NetworkClient.handleRequest`, parsing `json['data']` → `HomeModel`

---

## Phase 3: User Story 1 — Parent dashboard (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Parent-only `HomeCardsList` (per-child summary cards) gated by `context.isParents`
- [x] T021 [US1] Parent-only `ChildrenMenus` (today's menus rendered via embedded `DiaryBloc(GetMenus)`)
- [x] T022 [US1] Parent-only `my_children` horizontal list with empty-state via `EmptyWidget(no_children)`
- [x] T023 [US1] `HomeChildItem.onTap` navigates to `DiaryScreen(child: child)`
- [x] T024 [US1] Shared events horizontal row gated by `events.isNotEmpty`

---

## Phase 4: User Story 2 — Teacher dashboard (P1) — ✅ Complete

- [x] T030 [US2] Teacher-only search button in `MyAppBar.actionWidget` → `WidgetFunctions.navigateTo(SearchScreen)`
- [x] T031 [US2] Teacher-only home-sections 2-column grid driven by `ConfigSelector(selector: homeSections)`
- [x] T032 [US2] `getAlarms(context)` lifecycle: fires from `initState` and `AppLifecycleState.resumed`; internal `if (context.isProfessors)` gate makes it a no-op for parents

---

## Phase 5: User Story 3 — Cross-feature reactive refresh (P2) — ✅ Complete (with UX gap)

- [x] T040 [US3] `HomeBloc` uses `EventBlocListener.listen((event) { ... })` to subscribe to global `eventBus`
- [x] T041 [US3] On `EventAcceptedOrRejected` or `EventAdded`, dispatch `ReloadHomeFetchDataEvent(completer: null)`
- [x] T042 [US3] Pull-to-refresh via `RefreshIndicator` + `Completer<void>` plumbed through `ReloadHomeFetchDataEvent.completer`

---

## Phase 6: Gaps & cleanups

### Bugs / drift

- [ ] **T-fix-1** **(P2)** [US2] *(from [features.md#home--b](../features.md#home--b))* `getAlarms(context)` post-await safety:
  - `getAlarms` wrapper at [alarm_manager.dart:18-27](../../lib/core/utils/alarm_manager/alarm_manager.dart#L18-L27) schedules `di<AlarmManager>().getAlarms(context)` via `Debouncer.runLazy(500)`.
  - In the 500 ms window, the user may navigate away (Home unmounted, `context` stale).
  - The inner `AlarmManager.getAlarms` does check `context.mounted` before each `setAlarm` ([alarm_manager.dart:54](../../lib/core/utils/alarm_manager/alarm_manager.dart#L54)), but the API request itself fires regardless.
  - **Fix**: add `if (!context.mounted) return;` at the start of the `Debouncer.runLazy` lambda body, before the `if (context.isProfessors)` check.

- [ ] **T-fix-2** **(P2)** [US3] `EventAcceptedOrRejected` / `EventAdded` dispatching `ReloadHomeFetchDataEvent(silent: false)` causes the screen to blank during the reactive refresh — emits `HomeLoading()` ([home_bloc.dart:42](../../lib/features/home/bloc/home_bloc.dart#L42)). Change the listener at [home_bloc.dart:22-26](../../lib/features/home/bloc/home_bloc.dart#L22-L26) to pass `silent: true` so the existing content stays on screen during the reactive re-fetch.

### Carried forward from features.md

- [x] **T-feat-1** **(P0)** *(from [features.md#home--b](../features.md#home--b))* Replace `mainKey.currentContext`-based endpoint selection in `home_repo.dart:8`. *Fixed 2026-05-14: uses `isCurrentUserProfessor` from `core/user/current_role.dart`.*

- [ ] **T-feat-2** **(P2)** *(from [features.md#home--b](../features.md#home--b))* `getAlarms(context)` post-await safety — see T-fix-1.

- [ ] **T-feat-3** **(P2)** *[P]* *(from [features.md#home--b](../features.md#home--b))* Make the active child unmistakable — large avatar, name, and a clear switcher. Today the parent sees a horizontal list of equal-sized `HomeChildItem` cards with no "active" indicator.

- [ ] **T-feat-4** **(P2)** *[T]* *(from [features.md#home--b](../features.md#home--b))* Surface class-level summaries on the teacher dashboard — children present today, activities pending, RSVPs needing review.

- [x] **T-feat-5** *[B]* *(from [features.md#home--b](../features.md#home--b))* Pull-to-refresh on the home feed — **already implemented**. RefreshIndicator wraps the scroll view at [home_screen.dart:128-132](../../lib/features/home/home_screen.dart#L128-L132). Tracking as `[x]` and noting in features.md.

### Code hygiene / Constitution drift fixes

- [ ] **T-cleanup-1** [X] Rename `lib/features/home/data_source/` → `lib/features/home/data_sources/` (plural) to align with sibling features. Move `home_di.dart` to the feature root (`lib/features/home/home_di.dart`) to align with the [constitution principle II](../../.specify/memory/constitution.md). Project-wide grep-and-replace.

- [ ] **T-cleanup-2** [X] Remove the unused `LocalDatabaseRepo localDatabaseRepo` constructor parameter from [home_bloc.dart](../../lib/features/home/bloc/home_bloc.dart) and update the DI registration in [home_di.dart:15-18](../../lib/features/home/data_source/home_di.dart#L15-L18).

- [ ] **T-cleanup-3** [X] Either wire up `HomeFetchedSuccessfullyEvent` or drop it from the sealed `HomeEvent` hierarchy ([home_event.dart:19](../../lib/features/home/bloc/home_event.dart#L19)). Dead enum value today.

- [ ] **T-cleanup-4** [X] Either restore or delete the commented-out empty-state at [home_screen.dart:176-179](../../lib/features/home/home_screen.dart#L176-L179) — `EmptyWidget(no_events)`. Keep or remove; don't leave dangling.

- [ ] **T-cleanup-5** [X] Remove the commented-out `sections` field in [home_model.dart](../../lib/features/home/models/home_model.dart) — sections come from `ConfigCubit.homeSections`, not from the API.

- [ ] **T-cleanup-6** [X] Untangle the double-read of the user model at [home_screen.dart:98-104](../../lib/features/home/home_screen.dart#L98-L104): `UserSelector(selector: (s) => s.user, builder: (context, user) { final user = UserBloc.get.state.user; ... })` — the inner `user` shadows the captured one. Keep `UserSelector` (so the app bar rebuilds on user changes) and drop the inner re-read.

- [ ] **T-cleanup-7** [X] Remove `print('HomeFetchDataEvent $homeModel')` at [home_bloc.dart:52](../../lib/features/home/bloc/home_bloc.dart#L52). Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about 146 print/debugPrint calls.

- [ ] **T-cleanup-8** [X] In `HomeBloc`, the `on<HomeEvent>` handler ([home_bloc.dart:28-57](../../lib/features/home/bloc/home_bloc.dart#L28-L57)) is the same catch-all anti-pattern as chat and diary. Replace with typed `on<HomeFetchDataEvent>` + `on<ReloadHomeFetchDataEvent>`. Use `transformer: droppable()` on `ReloadHomeFetchDataEvent` to coalesce burst refreshes from `eventBus`.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `HomeFetchDataEvent` triggers a `parent/home` request when `isCurrentUserParent` is true.
- [ ] **T-test-2** [P] [US2] Bloc test: `HomeFetchDataEvent` triggers a `teacher/home` request when `isCurrentUserProfessor` is true.
- [ ] **T-test-3** [P] [US3] Bloc test: `EventAdded` event-bus signal dispatches a `ReloadHomeFetchDataEvent`.
- [ ] **T-test-4** [P] [US3] After T-fix-2, the reactive `ReloadHomeFetchDataEvent` must not emit `HomeLoading` — verify the previous `HomeFetchedSuccessfully(oldModel)` state is preserved during the re-fetch.
- [ ] **T-test-5** [P] [US1] Widget test: empty `homeModel.children` shows `EmptyWidget(no_children)` for parents.
- [ ] **T-test-6** [P] [US2] Widget test: empty `config.homeSections` suppresses the entire sections block (header + grid) for teachers.

---

## Constitution Drift Summary

| Drift | Site | Status |
|---|---|---|
| `mainKey.currentContext` in repo | [home_repo.dart:8](../../lib/features/home/data_source/home_repo.dart#L8) | ✅ Fixed 2026-05-14 — now `isCurrentUserProfessor` |
| `data_source/` (singular) instead of `data_sources/` | [data_source/](../../lib/features/home/data_source/) | Open — T-cleanup-1 |
| `home_di.dart` under `data_source/` instead of feature root | [data_source/home_di.dart](../../lib/features/home/data_source/home_di.dart) | Open — T-cleanup-1 |
| Unused `LocalDatabaseRepo` constructor parameter | [home_bloc.dart](../../lib/features/home/bloc/home_bloc.dart) | Open — T-cleanup-2 |
| Catch-all `on<HomeEvent>` handler | [home_bloc.dart:28](../../lib/features/home/bloc/home_bloc.dart#L28) | Open — T-cleanup-8 |
| `print` call in bloc | [home_bloc.dart:52](../../lib/features/home/bloc/home_bloc.dart#L52) | Open — T-cleanup-7 |
| Commented-out empty-state + `sections` field | screen + model | Open — T-cleanup-4, T-cleanup-5 |
| Shadowed `user` variable | [home_screen.dart:98-104](../../lib/features/home/home_screen.dart#L98-L104) | Open — T-cleanup-6 |

## Gaps Found

1. **Reactive refresh blanks the screen** (T-fix-2) — `EventAdded` / `EventAcceptedOrRejected` re-fetches with `silent: false`, dropping the user back to the loading spinner momentarily.
2. **`getAlarms(context)` post-await safety** (T-fix-1) — the outer wrapper doesn't check `context.mounted` after the 500 ms debounce; the inner per-alarm loop does.
3. **Catch-all `on<HomeEvent>` anti-pattern** (T-cleanup-8) — same as chat/diary; should be typed handlers with `droppable()` on reload.
4. **Dead constructor injection** (T-cleanup-2) — `LocalDatabaseRepo` is injected and never used.
5. **Dead enum variant** (T-cleanup-3) — `HomeFetchedSuccessfullyEvent`.
6. **Commented-out code** (T-cleanup-4, T-cleanup-5) — empty-state for events, `sections` field.
7. **Directory naming inconsistency** (T-cleanup-1) — `data_source/` (singular).
8. **Active-child not visually distinct** in the parent dashboard (T-feat-3).
9. **No teacher class summaries** (T-feat-4).

## Notes

- The `mainKey.currentContext` → `isCurrentUserProfessor` fix in [home_repo.dart:8](../../lib/features/home/data_source/home_repo.dart#L8) is the headline P0 closure for this feature, attributable to the cross-feature `mainKey` sweep tracked under [features.md cross-feature tasks](../features.md#cross-feature-tasks).
- Pull-to-refresh is already implemented — features.md lists it as `[ ]` but the code at [home_screen.dart:128](../../lib/features/home/home_screen.dart#L128) shows it shipped. Update [features.md](../features.md#home--b) accordingly.
- `ChildrenMenus` embeds its own `DiaryBloc(GetMenus)` inside the home — strongly coupled to the diary feature; consider whether the menu data should live in the home payload instead of a separate diary call.
