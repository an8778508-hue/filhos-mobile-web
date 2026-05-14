---
status: migrated
feature: search_for_filter
migrated_from: specs/features.md#search_for_filter--b
migrated_date: 2026-05-14
---

# Tasks: Search-for-Filter

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#search_for_filter--b](../features.md#search_for_filter--b).

## Migration summary

`search_for_filter` is a reusable picker built on top of `search`. It ships in production and is consumed by `core/components/sheets/filter_sheet.dart`. All work below is gap-closing or hygiene.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable.
- **[Story]**: US1 = picker, US2 = reusable API, US3 = empty/cleared state.

---

## Phase 1: Setup — built

- [x] **T-001** Feature folder under [lib/features/search_for_filter/](../../lib/features/search_for_filter/) mirrors small-feature shape.
- [x] **T-002** Bloc registered in [init_dependencies.dart:86](../../lib/init_dependencies.dart#L86). *(Drift: no feature-root DI class — see T-fix-DI.)*
- [x] **T-003** `LocalizationKeys.search` already in all three langs.

## Phase 2: Foundational — built

- [x] **T-010** `SearchForFilterBloc` reusing `SearchRepo.globalSearchForProfessor` ([search_for_filter_bloc.dart](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart)).
- [x] **T-011** States: `Initial/Loading/Succeed/Error` + dead `ChangeValueLoading/Succeed/ActivitiesLoading`.
- [x] **T-012** `SearchForFilterModelType` enum (`childOrParent` / `classType` / `teacher` / `level`).

## Phase 3: User Story 1 — Picker — built

- [x] **T-020** [US1] `SearchForFilterScreen` with `searchModelType` input.
- [x] **T-021** [US1] `SubmitSearchForFilter` event hits `SearchRepo.globalSearchForProfessor(query, isTeacher)`.
- [x] **T-022** [US1] Result filtered by `searchModelType` ([search_for_filter_screen.dart:121-131](../../lib/features/search_for_filter/search_for_filter_screen.dart#L121-L131)).
- [x] **T-023** [US1] Tapping a row `Navigator.pop`s the `SchoolItem` ([search_for_filter_screen.dart:97](../../lib/features/search_for_filter/search_for_filter_screen.dart#L97)).
- [x] **T-024** [US1] `ClearSearchForFilter` resets the in-memory list.

## Phase 4: User Story 2 — Reusable API — built (with drift)

- [x] **T-030** [US2] Component shape: `SearchForFilterScreen(searchModelType, hasInitial)` → `Future<SchoolItem?>`.
- [x] **T-031** [US2] Three consumer call sites in [filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart) at lines 92, 132, 172.
- [ ] **T-fix-API-1** Document the reusable API in this file (done in [spec.md User Story 2](spec.md#user-story-2---reusable-component-api-priority-p1)) and remove the dead `hasInitial` path.

## Phase 5: User Story 3 — Empty state — built

- [x] **T-040** [US3] Pre-search and post-clear render `EmptySearchResult`.

---

## Phase 6: Gaps & cleanups

### From features.md
- [ ] **T-fix-1** *(features.md)* Document the reusable API inputs/outputs — moved into [spec.md](spec.md) under "User Story 2"; consider also dropping a `README.md` next to the feature folder.
- [ ] **T-fix-2** *(features.md)* Persist last-used filters per `searchModelType` via the already-injected `LocalDatabaseRepo`. Box keys e.g. `search_for_filter:last:<type>`.

### Constitution drift fixes
- [ ] **T-fix-DI** Create [lib/features/search_for_filter/search_for_filter_di.dart](../../lib/features/search_for_filter/search_for_filter_di.dart) implementing `DependencyInjection`, move the bloc registration into it, and call `SearchForFilterInjection().init()` from `init_dependencies.dart` (instead of the direct `di.registerFactory` line).
- [ ] **T-fix-3** Replace catch-all `on<SearchForFilterEvent>` ([search_for_filter_bloc.dart:19](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart#L19)) with typed `on<Specific>` handlers.
- [ ] **T-fix-4** Surface `SearchForFilterItemsError` to the user — render an `ErrorScreen` with retry, mirroring `SearchScreen`'s behavior.
- [ ] **T-fix-5** Replace `Colors.white` in [search_for_filter_items_list.dart:22](../../lib/features/search_for_filter/widgets/search_for_filter_items_list.dart#L22) with `context.colors.background`.

### Code hygiene
- [ ] **T-cleanup-1** Delete the unused `SearchForFilterModel` class in [model/search_for_filter_model.dart](../../lib/features/search_for_filter/model/search_for_filter_model.dart) (keep only the enum + extensions). Update imports.
- [ ] **T-cleanup-2** Delete dead `SearchForFilterActivitiesLoading`, `ChangeValueLoading`, `ChangeValueSucceed` from [search_for_filter_state.dart](../../lib/features/search_for_filter/bloc/search_for_filter_state.dart).
- [ ] **T-cleanup-3** Delete `GetSearchForFilterItems` event and the commented-out handler block — neither is used; the only dispatcher is gated on `hasInitial` and the bloc handler is `// await _handleSearchForFilterItems(event, emit);`.
- [ ] **T-cleanup-4** Remove the `hasInitial` constructor argument from `SearchForFilterScreen` (no caller passes `true`).
- [ ] **T-cleanup-5** Decide on `classType`: either remove from the enum + callers, or wire it to a server endpoint. Today it returns `[]` unconditionally.
- [ ] **T-cleanup-6** Remove the large commented-out `_handleSearchForFilterItems` method in [search_for_filter_bloc.dart:50-62](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart#L50-L62).

### Tests (aspirational)
- [ ] **T-test-1** [P] [US2] Widget test: pushing the screen and tapping a row resolves the awaited push with a `SchoolItem`.
- [ ] **T-test-2** [P] [US1] Bloc test: `SubmitSearchForFilter` success / failure / clear sequence.

---

## Constitution Drift Fixes summary

- Missing feature-root DI class (T-fix-DI).
- Catch-all `on<SearchForFilterEvent>` → typed handlers (T-fix-3).
- Hardcoded `Colors.white` → theme token (T-fix-5).
- Dead state/event classes + unused `SearchForFilterModel` (T-cleanup-1/2/3).
- `classType` no-op branch (T-cleanup-5).

## Gaps Found

1. **No feature DI class**: only feature in scope without its own `*Injection`.
2. **Reusable API is undocumented at the code level** — caller has to read the screen source to know the input/output shape.
3. **`classType` is unimplemented** but exposed in the enum.
4. **`hasInitial` is a dead constructor argument** — handler commented out.
5. **`LocalSearch persistence is asked for but unwired** despite `LocalDatabaseRepo` already being injected.
6. **No error UI** — failures render as "no results".
