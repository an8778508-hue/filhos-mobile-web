---
status: migrated
feature: search
migrated_from: specs/features.md#search--b
migrated_date: 2026-05-14
---

# Tasks: Search

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#search--b](../features.md#search--b).

## Migration summary

`search` was migrated as-is on 2026-05-14. The feature ships and is used by `SearchScreen` (from home) and `AllChildrenScreen` (embedded). All work below is gap-closing — the feature is functional today.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel.
- **[Story]**: US1 = teacher child-search, US2 = global search, US3 = professor lookup, X = cross-cutting.

---

## Phase 1: Setup — built

- [x] **T-001** Feature folder under [lib/features/search/](../../lib/features/search/) mirrors the smaller-feature shape (no `presentation/widgets/`).
- [x] **T-002** `SearchInjecion` (typo) registered in [init_dependencies.dart:118](../../lib/init_dependencies.dart#L118).
- [x] **T-003** Localization key `search_by_child_name` exists in all three langs.

## Phase 2: Foundational — built

- [x] **T-010** `SearchRepo` contract + `SearchImpl` returning `Either<Failure, T>` via `NetworkClient.handleRequest` ([search_dc.dart](../../lib/features/search/data_sources/search_dc.dart)).
- [x] **T-011** Models: `GlobalSearchResult` ([global_search.dart](../../lib/features/search/models/global_search.dart)); rows reuse the shared `SchoolItem`.
- [x] **T-012** `SearchBloc` with `Initial/Loading/Succeed/Failed/EmptySearchState` ([search_bloc.dart](../../lib/features/search/bloc/search_bloc.dart)).

## Phase 3: User Story 1 — Teacher child-search — built

- [x] **T-020** [US1] `SearchScreen` form + `SearchField` + back chevron + `ProfessorQuestions` navigation on tap.
- [x] **T-021** [US1] `ChildSearch` event hits `GET teacher/timeline/?q=…`.
- [x] **T-022** [US1] `ClearSearch` event resets in-memory state.
- [x] **T-023** [US1] `SearchFailed` renders `ErrorScreen` with working retry.
- [x] **T-024** [US1] Empty result renders `EmptySearchResult`.

## Phase 4: User Story 2 — Global search — built (with gaps)

- [x] **T-030** [US2] `GlobalSearch(query, isTeacher)` event; `isTeacher` is fed from `context.isProfessors` at the call site in `AllChildrenScreen`.
- [x] **T-031** [US2] Repo branches on `isTeacher` between `/teacher/timeline/` and `/parent/timeline`.
- [x] **T-032** [US2] Tolerant parser handles both flat-list and categorized-object response shapes.

## Phase 5: User Story 3 — Professor lookup — built but unwired

- [x] **T-040** [US3] `ProfessorSearch` event + `_professorSearch` handler + repo method `professorSearch(query)` hitting `teacher/teacher-search?q=…`.
- [ ] **T-fix-DEAD** [US3] **No UI dispatcher** for `ProfessorSearch` anywhere in the codebase. Either remove the event + handler + endpoint or wire a UI surface that uses it.

---

## Phase 6: Gaps & cleanups

### From features.md
- [ ] **T-fix-1** *(features.md)* Debounce the query — wire [lib/core/utils/debouncer.dart](../../lib/core/utils/debouncer.dart) into `SearchField.onSearch` (or add an `onChanged` hook) on both `SearchScreen` and `AllChildrenScreen` so live typing doesn't hammer the backend.
- [ ] **T-fix-2** *(features.md)* Show recent searches — persist last N queries (per `isTeacher` mode) via `LocalDatabaseRepo`; render before any keystroke.

### Constitution drift fixes
- [ ] **T-fix-3** Replace catch-all `on<SearchEvent>` ([search_bloc.dart:18](../../lib/features/search/bloc/search_bloc.dart#L18)) with typed `on<ChildSearch>`, `on<GlobalSearch>`, `on<ProfessorSearch>`, `on<ClearSearch>` — matches the chat fix and the constitution's typed-handler guidance.
- [ ] **T-fix-4** Move the search results into typed `SearchSucceed(items)` / `GlobalSearchSucceed(result)` states instead of holding them as bloc fields read from outside the BlocBuilder closure.

### Code hygiene
- [ ] **T-cleanup-1** Remove stray `debugPrint('sssssssssssssssssssssssssssss')` in [search_bloc.dart:43](../../lib/features/search/bloc/search_bloc.dart#L43) and `debugPrint('dddddddddddddddddddddddddddddddddd')` in [search_dc.dart:98](../../lib/features/search/data_sources/search_dc.dart#L98).
- [ ] **T-cleanup-2** Rename class `SearchInjecion` → `SearchInjection` ([search_di.dart:6](../../lib/features/search/search_di.dart#L6)) and update its registration site at [init_dependencies.dart:118](../../lib/init_dependencies.dart#L118).
- [ ] **T-cleanup-3** Remove the dead `ShowEmptySearch` event ([search_event.dart:31](../../lib/features/search/bloc/search_event.dart#L31)) and its handler ([search_bloc.dart:32-34](../../lib/features/search/bloc/search_bloc.dart#L32-L34)) — no dispatcher in the repo.
- [ ] **T-cleanup-4** Remove the large commented-out `globalSearchForProfessor` block in [search_dc.dart:45-77](../../lib/features/search/data_sources/search_dc.dart#L45-L77) (kept "for reference"). Use git history instead.
- [ ] **T-cleanup-5** Replace `const Color(0xffeceef1)` in [search_screen.dart:74](../../lib/features/search/presentation/search_screen.dart#L74) with a `context.colors.*` token.

### Gap (flavor honesty)
- [ ] **T-fix-5** Decide whether `SearchScreen` should be reachable from the parents-flavor home. Today the icon at [home_screen.dart:113](../../lib/features/home/home_screen.dart#L113) is unconditional and the screen always fires `ChildSearch` (teacher endpoint). Options: (a) gate the icon on `context.isProfessors`, or (b) make the screen dispatch `GlobalSearch(isTeacher: context.isProfessors)` like `AllChildrenScreen` does.

### Tests (aspirational — no `test/` directory exists today)
- [ ] **T-test-1** [P] [US1] Bloc test: `ChildSearch` success / empty / failure mapping.
- [ ] **T-test-2** [P] [US2] Repo test: tolerant parser for flat-list + categorized-object response shapes.

---

## Constitution Drift Fixes summary

- Catch-all `on<SearchEvent>` → typed handlers (T-fix-3).
- Hardcoded `Color(0xffeceef1)` → theme token (T-cleanup-5).
- Stray debug prints (T-cleanup-1).
- Dead event/handler/endpoint paths (T-fix-DEAD, T-cleanup-3).
- Class-name typo `SearchInjecion` → `SearchInjection` (T-cleanup-2).

## Gaps Found

1. **Endpoint reuse**: `/teacher/timeline/` is used by both `ChildSearch` and `GlobalSearch(isTeacher: true)`, with different parse paths in the repo. Fragile if the backend ever standardizes one shape.
2. **`ProfessorSearch` is dead UI-side**: the event + handler + endpoint exist; no caller. Either remove or wire it.
3. **`SearchScreen` flavor honesty**: fires teacher endpoint even on parents flavor.
4. **Debounce + recent searches**: both flagged in features.md, neither implemented.
5. **No tests**: not blocking per repo-wide stance, recorded as aspirational.
