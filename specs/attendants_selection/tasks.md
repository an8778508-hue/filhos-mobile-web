---
status: migrated
feature: attendants_selection
migrated_from: specs/features.md#attendants_selection--b
migrated_date: 2026-05-14
---

# Tasks: Attendants Selection

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#attendants_selection--b](../features.md#attendants_selection--b).

**Tests**: No `test/` directory; tests aspirational.

## Migration summary

Scaffolded UI (search + list + error/empty states) reusing `DiaryBloc` and `SearchBloc`. **The actual multi-select half** — selection state, "already invited" indicator, confirm CTA — **is not implemented**. **No caller** wires this screen. Resolve the naming collision with [select_attendants](../select_attendants/) before fleshing out further work.

---

## Phase 1: Setup — Partial

- [x] T001 Create [lib/features/attendants_selection/](../../lib/features/attendants_selection/)
- [x] T002 Reserve localization keys `select_attendants` ([localization_keys.dart:199](../../lib/core/localization/localization_keys.dart#L199)) and `search_by_child_name` ([localization_keys.dart:194](../../lib/core/localization/localization_keys.dart#L194))
- [x] T003 PT / EN translations present (inherited from diary's search field)
- [ ] T004 AR translation — verify per [features.md cross-feature task](../features.md#cross-feature-tasks)

## Phase 2: Foundational — Partial

- [x] T010 Build the screen scaffold consuming `DiaryBloc` + `SearchBloc` via `MultiBlocProvider`
- [ ] T011 **Resolve naming collision** with [select_attendants](../select_attendants/) — see [select_attendants/tasks.md T-fix-1](../select_attendants/tasks.md#architectural-drift). **Blocks meaningful follow-up work.**
- [ ] T012 Define a dedicated `AttendantsRepository` returning `Either<Failure, List<AttendantModel>>` via `NetworkClient.handleRequest` (or confirm `DiaryBloc.GetSchoolItems` is the right contract and document why).
- [ ] T013 Define `AttendantsSelectionBloc` (Cubit) holding `Set<int> selectedIds` + `bool isLoading` + `Failure?` + `List<AttendantModel> available` + `Set<int> alreadyInvited`.

## Phase 3: User Story 1 — Multi-select (P1) MVP — Partial

- [x] T020 [US1] Search field at top wired to `SearchBloc.ChildSearch` / `ClearSearch`
- [x] T021 [US1] Loading state when any bloc is loading or `DiaryBloc` is in `DiaryInitial`
- [x] T022 [US1] Empty search result → `EmptySearchResult` widget
- [x] T023 [US1] Search results render via `SchoolItemsList(items: searchItems, ...)`
- [x] T024 [US1] Full list render via `SchoolItemsList(items: items, ...)` when no search active
- [x] T025 [US1] `SchoolItemsError` → `ErrorScreen` with `onRetry: () => DiaryBloc.add(GetSchoolItems())`
- [x] T026 [US1] `SearchFailed` → `ErrorScreen` with `onRetry: () => SearchBloc.add(ChildSearch(query: ...))`
- [ ] **T-impl-1** [US1] **Implement selection state.** Today `onSchoolItemsPressed: (item) {}` is a no-op ([lines 104, 111](../../lib/features/attendants_selection/attendants_selection_screen.dart#L104)). Add `Set<int> _selectedIds`, toggle on tap, render a check icon on selected rows, add a "Confirm" CTA at the bottom that does `Navigator.pop(context, _selectedIds.toList())`.

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Architectural drift

- [ ] **T-fix-1** **(P1)** [architecture] **Resolve the naming collision** with [select_attendants](../select_attendants/). See [select_attendants/tasks.md T-fix-1](../select_attendants/tasks.md#architectural-drift). The recommendation in that file is to keep `attendants_selection` (since this scaffold is richer) and delete `select_attendants/` — but the team should confirm based on whether the two are meant to be **children-only** vs **people-only** pickers. **Blocks T-impl-1.**

- [ ] **T-fix-2** **(P2)** [architecture] **Introduce a dedicated `AttendantsRepository`** instead of reusing `DiaryBloc.GetSchoolItems`. Today this screen is tightly coupled to internal diary contracts; if diary changes its list shape, this picker breaks silently. Use `isCurrentUserProfessor` to pick the role-aware endpoint inside the repo.

### Functional gaps (from features.md)

- [ ] **T-fix-3** *(from [features.md](../features.md#attendants_selection--b))* **Distinguish "already invited" vs "available" states.** The caller will pass an `alreadyInvitedIds` set; render those rows with a different background + a disabled / "already invited" badge; either don't allow toggling them or pre-check them and disable the toggle.

- [ ] **T-fix-4** **Localization copy mismatch.** Either:
  - Confirm this picker really *is* child-oriented (in which case the feature description in [features.md](../features.md#attendants_selection--b) should be updated to say "children", not "teachers/guardians"), or
  - Rename to generic copy: replace `search_by_child_name` with a new `search_by_name` key, and decide whether `select_attendants` is the right title or if `attendants` / `invite_attendants` is clearer.

### Code hygiene

- [ ] **T-cleanup-1** Remove the `false && ` typo in `showAllChildren: false && !validList(searchItems)` at [line 103](../../lib/features/attendants_selection/attendants_selection_screen.dart#L103). The expression is always `false`; either fix the intent or drop the dead branch.

- [ ] **T-cleanup-2** Remove the `Builder` wrapper at [line 56](../../lib/features/attendants_selection/attendants_selection_screen.dart#L56). The children below `MultiBlocProvider` already have access to the providers' context through the closure.

- [ ] **T-cleanup-3** Move [attendants_selection_screen.dart](../../lib/features/attendants_selection/attendants_selection_screen.dart) into a `presentation/` subdirectory once any sibling code (bloc / repo) is added.

- [ ] **T-cleanup-4** `_searchController` is created/disposed but its current value is read in only one place (the retry button). Use a `ValueListenableBuilder` or move to the new `AttendantsSelectionBloc` once introduced.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test: on mount, `GetSchoolItems` dispatches.
- [ ] **T-test-2** [P] [US1] Widget test: search debounce-fires `ChildSearch(query)` with non-empty value.
- [ ] **T-test-3** [P] [US1] Widget test: empty search result renders `EmptySearchResult`.
- [ ] **T-test-4** [P] [US1] Widget test (post-T-impl-1): tapping a row toggles its selection; confirm CTA pops with the right `List<int>`.
- [ ] **T-test-5** [P] [US1] Widget test (post-T-fix-3): "already invited" rows render with a distinct affordance.

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-cleanup-*
- [ ] **TX02** [X] Wire the picker from at least one real caller (event invitation or form `attendants` field type) so the integration is exercised
- [ ] **TX03** [X] Once T-fix-1 is resolved, delete the parallel directory (`select_attendants/` or `attendants_selection/`) and update [features.md](../features.md)

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| T-fix-1 | Two parallel features with overlapping names | Medium (P1) — blocks work |
| T-fix-2 | Cross-feature coupling to `DiaryBloc` instead of a dedicated repo | Medium (P2) |
| T-fix-3 | "Already invited" vs "available" not surfaced | Medium |
| T-fix-4 | Child-oriented localization keys for a people-oriented picker | Low-medium |

## Gaps Found

- **Multi-select state is missing** (T-impl-1) — taps are no-ops; the screen renders a list but cannot return a selection.
- **No caller wired** — grep returns zero references to `AttendantsSelectionScreen` outside its own file.
- **Naming collision** with [select_attendants](../select_attendants/) is unresolved (T-fix-1).
- **Cross-feature import** of `DiaryBloc` + `SchoolItemsList` couples this picker to the diary feature's internals (T-fix-2).
- **"Already invited" distinction missing** (T-fix-3).
- **Localization copy mismatch** between features.md description and the reused localization keys (T-fix-4).
- **`false && ` typo** in a `SchoolItemsList` prop (T-cleanup-1).

## Notes

- This is a **migration** of an existing (scaffolded) feature. The `[x]` items are limited to the UI scaffolding that exists today; the multi-select intent is documented but not implemented.
- The team needs to decide between this feature and [select_attendants](../select_attendants/) **before** any meaningful implementation. The migration intentionally surfaces this as the blocking decision.
- This feature has the closest analog to a "real" implementation among the two parallel directories — recommend keeping this one and deleting `select_attendants/` (subject to team confirmation about the children-vs-people distinction).
