---
status: migrated
feature: main
migrated_from: specs/features.md#main--b
migrated_date: 2026-05-14
---

# Tasks: Main (Tab Shell)

**Input**: [spec.md](spec.md), [plan.md](plan.md), and [features.md#main--b](../features.md#main--b).

**Tests**: No `test/` directory.

**Organization**: This is a **migration** of an existing 6-file feature. Story labels map to user stories in [spec.md](spec.md): US1 = render tab shell, US2 = featured events dialog, US3 = mount side-effects, X = cross-cutting.

---

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/main/](../../lib/features/main/) with `bloc/` and `presentation/{widgets/}`
- [x] T002 Register `MainBloc` factory via central [init_dependencies.dart](../../lib/init_dependencies.dart) — ⚠️ no feature-root `main_di.dart`. See T-cleanup-2.
- [x] T003 Declare `PageID` enum in [core/config/config.dart:160](../../lib/core/config/config.dart#L160) and `BottomBarItemModel` parser
- [x] T004 `bottom_navy_bar: ^6.1.0` added to [pubspec.yaml:52](../../pubspec.yaml#L52) — ⚠️ not imported anywhere in `lib/features/main/`. See T-cleanup-3.

---

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define sealed `MainEvent` (`ChangePage(id)`) and sealed `MainState` (`MainInitial`, `ChangePageLading` [sic], `ChangePageSucceed(selectedPage)`) in [bloc/](../../lib/features/main/bloc/)
- [x] T011 Implement `MainBloc` with `currentId: String` instance field + 100 ms `Future.delayed` between `ChangePageLading` and `ChangePageSucceed`
- [x] T012 Build [CustomBottomNavigation](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart) driven by `ConfigSelector(selector: bottomBar)`
- [x] T013 Build [BottomNavigationItemWidget](../../lib/features/main/presentation/widgets/bottom_navigation_item.dart) with notification-badge support (used by settings tab for unread chats)
- [x] T014 Build [MainScreen](../../lib/features/main/presentation/main_screen.dart) — Scaffold + PageView + listeners + side-effects

---

## Phase 3: User Story 1 — Render tab shell from remote config (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] `ConfigSelector(selector: bottomBar)` wraps both the `PageView` and the `CustomBottomNavigation`
- [x] T021 [US1] `MainScreen.getWidgetFromBottomBar(id)` maps `PageID.{home,diary,events,settings}` to the four destination widgets
- [x] T022 [US1] Unknown ids render `Placeholder()`
- [x] T023 [US1] Empty `config.bottomBar` falls back to `[HomeScreen()]` and renders no bottom nav
- [x] T024 [US1] `ChangePage(id)` no-ops when `id == currentId`
- [x] T025 [US1] `BlocConsumer.listener` on `ChangePageSucceed` updates `_bottomNavId` and calls `_pageController.jumpToPage(index)`
- [x] T026 [US1] Every `PageView` child wrapped in `TrueAutomaticKeepAlive` so per-tab state survives switches
- [x] T027 [US1] Settings-tab notification badge shows `ChatBloc.unReadMessagesCount` via `context.watch<ChatBloc>()`

---

## Phase 4: User Story 2 — Featured events dialog (P2) — ✅ Complete

- [x] T030 [US2] `FeaturedEventsBloc.fetch()` dispatched in `initState`
- [x] T031 [US2] `BlocListener<FeaturedEventsBloc, FeaturedEventsState>` opens `FeaturedEventsScreen` when `eventsState.data` is non-empty and `featuredDialogOpened` is false
- [x] T032 [US2] Dialog closed via `Navigator.pop()` when the list becomes empty
- [x] T033 [US2] `featuredDialogOpened` guard prevents re-opening within the same session

---

## Phase 5: User Story 3 — Mount side-effects (P2) — ✅ Complete

- [x] T040 [US3] `BackgroundServicesBloc.add(CallServices())` dispatched in `initState`
- [x] T041 [US3] `ensureTrackingPermission()` called via `addPostFrameCallback` (idempotent, no-op on non-iOS)

---

## Phase 6: Gaps & cleanups

### Carried forward from features.md

- [x] **T-feat-1** *(from [features.md#main--b](../features.md#main--b))* Document the tab order per flavor (parents vs. teachers) — **Resolved**: both flavors share the same default `PageID` ordering (`home, diary, events, settings`). The tab list is fully remote-config-driven; differentiation happens at the Firestore `config/*` document layer, not in app code. Documented in [spec.md FR-004 + Edge Cases](spec.md#functional-requirements). If the two flavors' config documents ever diverge, that should be tracked in the config repo, not here.

- [ ] **T-feat-2** **(P1)** *(from [features.md#main--b](../features.md#main--b))* Add a guard so background pushes don't switch tabs while the user is mid-flow. Today any push deep-link that reaches `MainScreen` and dispatches `ChangePage` will fire even if the user is mid-typing in a form. See T-fix-1.

### Bugs / drift

- [ ] **T-fix-1** **(P1)** [US1] Mid-flow tab-switch guard:
  - Push deep-links reach `MainScreen` via [lib/features/notifications/notification_helper.dart](../../lib/features/notifications/notification_helper.dart) which can dispatch `MainBloc.add(ChangePage(id))` while the user is in an active form or chat composition.
  - **Fix**: introduce a "dirty flag" surface — either a `MainBloc.requestPageChange(id)` method that consults the currently-rendered tab's bloc state (via a registry) before dispatching, OR a `WillTabChange` guard via a `Provider` from each tab. Coordination cost across `add_form`, `chat`, and any other in-flight surfaces. Discuss before implementing.

- [ ] **T-fix-2** **(P2)** [US1] `_pageController` is `late final` but **not disposed** in `_MainScreenState.dispose()`. Memory leak risk on hot-reload / rebuild. Add `_pageController.dispose()`.

- [ ] **T-fix-3** **(P2)** [US1] Empty `config.bottomBar` fallback leaves the user stranded on home with no bottom nav. Add a defensive empty-state widget OR ensure `ConfigCubit` never emits an empty `bottomBar` (validate in the config parser).

- [ ] **T-fix-4** **(P2)** [US1] Unknown `BottomBarItemModel.id` renders `Placeholder()` silently. Either log a Crashlytics non-fatal so we detect config-vs-app version drift, or render an empty-state widget that says "Update the app to see this section".

- [ ] **T-fix-5** **(P3)** [US1] `Future.delayed(Duration(milliseconds: 100))` in [main_bloc.dart:15](../../lib/features/main/bloc/main_bloc.dart#L15) — intentional UX padding, but undocumented. Add a one-line comment explaining the purpose, or remove if no consumer relies on `ChangePageLading` rendering.

- [ ] **T-fix-6** **(P3)** [US1] `MainBloc.currentId` lives outside the state hierarchy. Fold it into `MainInitial(currentId)` / `ChangePageSucceed(selectedPage)` so the state alone is enough for any consumer to read the current tab. Breaks the typo'd `ChangePageLading` name — see T-cleanup-5.

### Code hygiene / Constitution drift fixes

- [ ] **T-cleanup-1** [X] Replace hardcoded `Colors.white` at [main_screen.dart:68](../../lib/features/main/presentation/main_screen.dart#L68) and [:73](../../lib/features/main/presentation/main_screen.dart#L73) with `context.colors.background`. [Constitution principle X](../../.specify/memory/constitution.md) violation.

- [ ] **T-cleanup-2** **(P1)** [X] Move `MainBloc` registration from the central [init_dependencies.dart](../../lib/init_dependencies.dart) into a new feature-root `lib/features/main/main_di.dart` implementing `DependencyInjection`. Wire through `init_dependencies.dart`. Aligns with [constitution principle II](../../.specify/memory/constitution.md). Same pattern as `add_form` (T-cleanup-1 in [../add_form/tasks.md](../add_form/tasks.md)).

- [ ] **T-cleanup-3** [X] `bottom_navy_bar: ^6.1.0` is declared in [pubspec.yaml:52](../../pubspec.yaml#L52) but not imported anywhere under `lib/features/main/` (or anywhere else searched). Either:
  - Remove the dependency, OR
  - Adopt the package and replace `CustomBottomNavigation` with `BottomNavyBar` ([https://pub.dev/packages/bottom_navy_bar](https://pub.dev/packages/bottom_navy_bar)) — note the features.md description "Tab shell with `bottom_navy_bar`" suggests this was once the intent.

- [ ] **T-cleanup-4** [X] Promote `EventsScreen` from [lib/features/settings/events/event_screen.dart](../../lib/features/settings/events/event_screen.dart) to a top-level feature `lib/features/events/`. Events is a top-level bottom-nav destination, not a settings sub-feature. Coordinated rename. [features.md settings task](../features.md#settings--b) mentions an unrelated `event_screen.dart` EventBus subscription leak — separate concern.

- [ ] **T-cleanup-5** [X] Rename sealed state `ChangePageLading` → `ChangePageLoading` in [main_state.dart:12](../../lib/features/main/bloc/main_state.dart#L12). Touches `main_state.dart` only (no external listeners on the state class today).

- [ ] **T-cleanup-6** [X] `pageController.jumpToPage(index)` in `_MainScreenState.jumpToPage` uses `Config.get.bottomBar.indexWhere(...)` ([main_screen.dart:117](../../lib/features/main/presentation/main_screen.dart#L117)) directly from a singleton, while the rendered `PageView` resolves items via the `ConfigSelector`. If the config changes mid-session, the two could diverge. Read from the same `ConfigSelector` value passed to `BlocConsumer.builder`.

- [ ] **T-cleanup-7** [X] Refactor `_MainScreenState` state management — `_bottomNavId` (widget) + `currentId` (bloc instance field) + `ChangePageSucceed.selectedPage` (state) is three sources of truth for the same value. Combined fix with T-fix-6.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `ChangePage(id: same)` is a no-op (no state emission).
- [ ] **T-test-2** [P] [US1] Bloc test: `ChangePage(id: different)` emits `ChangePageLading` → 100 ms delay → `ChangePageSucceed(selectedPage: id)`, and updates `currentId`.
- [ ] **T-test-3** [P] [US1] Widget test: empty `config.bottomBar` falls back to `[HomeScreen()]` with no `bottomNavigationBar`.
- [ ] **T-test-4** [P] [US1] Widget test: unknown `id` in `bottomBar` renders `Placeholder()` in that slot.
- [ ] **T-test-5** [P] [US2] Widget test: `FeaturedEventsBloc` emitting non-empty data triggers `FeaturedEventsScreen.open` exactly once even on repeat emissions.
- [ ] **T-test-6** [P] [US1] Widget test: 3 unread chats render a "3" badge on the settings tab.
- [ ] **T-test-7** [P] [US1] Tab-state-preservation test: type into a form on `diary`, switch to `home`, back to `diary` → input is preserved (verifies `TrueAutomaticKeepAlive`).

---

## Constitution Drift Summary

| Drift | Site | Status |
|---|---|---|
| Central DI registration instead of feature-root `main_di.dart` | [init_dependencies.dart](../../lib/init_dependencies.dart) | Open — T-cleanup-2 |
| Hardcoded `Colors.white` background | [main_screen.dart:68,73](../../lib/features/main/presentation/main_screen.dart#L68) | Open — T-cleanup-1 |
| `bottom_navy_bar` declared in pubspec, never used | [pubspec.yaml:52](../../pubspec.yaml#L52) | Open — T-cleanup-3 |
| Three sources of truth for current tab (`_bottomNavId`, `MainBloc.currentId`, `ChangePageSucceed.selectedPage`) | screen + bloc + state | Open — T-fix-6 + T-cleanup-7 |
| Typo `ChangePageLading` | [main_state.dart:12](../../lib/features/main/bloc/main_state.dart#L12) | Open — T-cleanup-5 |
| Missing `_pageController.dispose()` | [main_screen.dart](../../lib/features/main/presentation/main_screen.dart) | Open — T-fix-2 |

## Gaps Found

1. **No mid-flow push guard** (T-fix-1, T-feat-2) — a background push deep-link can yank the user out of an in-progress form.
2. **`_pageController` not disposed** (T-fix-2) — memory leak on rebuild.
3. **Empty / unknown `bottomBar` ids silently degrade** (T-fix-3, T-fix-4) — no logging or empty-state copy.
4. **Three sources of truth for current tab** (T-fix-6, T-cleanup-7).
5. **Typo in state class name** `ChangePageLading` (T-cleanup-5).
6. **Hardcoded color** violates theming discipline (T-cleanup-1).
7. **Central DI registration** violates feature-root convention (T-cleanup-2) — same as `add_form`.
8. **Dead `bottom_navy_bar` dependency** (T-cleanup-3) — features.md description is inaccurate.
9. **`EventsScreen` under `settings/events/`** despite being a top-level bottom-nav destination (T-cleanup-4).
10. **Undocumented 100 ms `Future.delayed`** in the bloc (T-fix-5).

## Deviation from features.md expectations

- features.md describes `main` as "Tab shell with `bottom_navy_bar`". **Reality**: the bottom bar is a custom widget ([CustomBottomNavigation](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart)); `bottom_navy_bar` is declared in pubspec but never imported. Suggest updating features.md to "Tab shell with custom bottom nav (CustomBottomNavigation)" OR adopting the package per T-cleanup-3.
- features.md asks "Document the tab order per flavor (parents vs. teachers)". **Reality**: tab order is the same in both flavors today (both consume the same `PageID` ordering driven by remote config). The per-flavor distinction lives in Firestore `config/*` documents — flagged as resolved via T-feat-1.

## Notes

- This is the smallest feature in the migration scope (6 files). Most "work" is doc-level — documenting the surprising bits (3 sources of truth, dead pubspec entry, `ChangePageLading` typo, missing dispose).
- The catch-all `on<MainEvent>` handler ([main_bloc.dart:11-18](../../lib/features/main/bloc/main_bloc.dart#L11-L18)) is the same anti-pattern as chat / diary / home; for this feature it's particularly low-impact because there's only one event type. Not worth a typed rewrite unless paired with the broader project-level refactor.
