---
status: migrated
feature: all_children
migrated_from: specs/features.md#all_children--p
migrated_date: 2026-05-14
---

# Tasks: All Children

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#all_children--p](../features.md#all_children--p).

## Migration summary

`all_children` ships and works on the **professores** flavor (entry-point gate), contrary to the features.md `· P` tag. It fetches `teacher/questions/data` and embeds `SearchBloc` for in-page filtering. Several drift/gap items remain.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable.
- **[Story]**: US1 = list, US2 = filter, US3 = detail.

---

## Phase 1: Setup — built

- [x] **T-001** Feature folder at [lib/features/all_children/](../../lib/features/all_children/).
- [x] **T-002** `AllChildrenInjection` at feature root, registered in [init_dependencies.dart:120](../../lib/init_dependencies.dart#L120). ✓
- [x] **T-003** Localization keys `all_children` + `search_by_child_name` present.

## Phase 2: Foundational — built

- [x] **T-010** `AllChildrenRepo` + `AllChildrenImpl` ([all_children_dc.dart](../../lib/features/all_children/data_source/all_children_dc.dart)).
- [x] **T-011** Sealed `AllChildrenState` (`Initial / Loading / Succeed(items) / Failed(failure)`).
- [x] **T-012** `AllChildrenBloc` with `GetAllChildren` handler.

## Phase 3: User Story 1 — List — built (with gap)

- [x] **T-020** [US1] Screen builds `MultiBlocProvider` with `AllChildrenBloc` + `SearchBloc`.
- [x] **T-021** [US1] `GetAllChildren` dispatched on bloc creation.
- [x] **T-022** [US1] `SchoolItemsList` renders the bootstrapped list.
- [ ] **T-fix-1** **Render `AllChildrenFailed`.** Today the screen only branches on `searchState`. Add an `else if (allChildrenState is AllChildrenFailed)` branch that renders an `ErrorScreen` with a retry that re-dispatches `GetAllChildren`.

## Phase 4: User Story 2 — In-page filter — built (with gap)

- [x] **T-030** [US2] Search field dispatches `GlobalSearch(query, isTeacher: context.isProfessors)` ([all_children_screen.dart:82-86](../../lib/features/all_children/presentation/all_children_screen.dart#L82-L86)).
- [x] **T-031** [US2] Result-merge: search children + parents replace the bootstrapped list whenever present.
- [x] **T-032** [US2] `EmptySearchResult` on zero-row, `ErrorScreen` on `SearchFailed`.
- [ ] **T-fix-2** **Debounce** the search field via [core/utils/debouncer.dart](../../lib/core/utils/debouncer.dart) (shared concern with [search T-fix-1](../search/tasks.md#from-featuresmd)).

## Phase 5: User Story 3 — Detail — built (with lossy mapping)

- [x] **T-040** [US3] Tap → `getDetailsFromSchoolItem(item)` → `ChildDetailsSheet.openSheet`.
- [ ] **T-fix-3** **Backfill the synthetic `ChildDetailsModel`.** Either (a) extend `SchoolItem` to carry the missing fields (`age`, `gender`, `birthday`, `series`), or (b) fetch the full `ChildDetailsModel` from a detail endpoint when the sheet opens. Avoid the current `item.id.toString()`-for-`age` placeholder.

---

## Phase 6: Gaps & cleanups

### From features.md
- [ ] **T-fix-4** *(features.md)* **Show enrollment status badge per child.** Requires either a backend field on `SchoolItem` or a per-child enrollment fetch. Decide and wire.
- [ ] **T-fix-5** *(features.md)* **Allow re-ordering** for accounts with many children. Likely needs a server-side `display_order` field and a drag-handle in `SchoolItemsList`.

### Constitution drift fixes
- [ ] **T-fix-6** **Resolve flavor-doc discrepancy.** features.md says parents (`· P`); the only entry-point is `if (context.isProfessors)` and the endpoint is `teacher/questions/data`. Either fix features.md (change tag to `· T`) or wire a parents-side variant. Today the spec assumes the code is correct — verify with product team.
- [ ] **T-fix-7** Replace catch-all `on<AllChildrenEvent>` ([all_children_bloc.dart:17](../../lib/features/all_children/presentation/bloc/all_children_bloc.dart#L17)) with typed `on<GetAllChildren>`.
- [ ] **T-fix-8** Replace `Colors.white` / `Colors.black` literals ([all_children_screen.dart:41, 92, 107, 115](../../lib/features/all_children/presentation/all_children_screen.dart#L41)) with `context.colors.*` tokens.

### Code hygiene
- [ ] **T-cleanup-1** Remove the `false && !validList(items)` always-false flag at [all_children_screen.dart:106, 113](../../lib/features/all_children/presentation/all_children_screen.dart#L106). Either delete the `showAllChildren` parameter from `SchoolItemsList` calls here or pick a real condition.
- [ ] **T-cleanup-2** Audit `hasNotification: true` on the app bar — typically settings sub-screens do not need a notifications badge. Confirm and adjust.

### Tests (aspirational)
- [ ] **T-test-1** [P] [US1] Bloc test: `GetAllChildren` success / failure mapping.
- [ ] **T-test-2** [P] [US2] Widget test: search dispatch & result-merge.
- [ ] **T-test-3** [P] [US3] Widget test: tap → sheet open with the synthesized model.

---

## Constitution Drift Fixes summary

- Doc-vs-code flavor discrepancy (T-fix-6).
- Catch-all `on<AllChildrenEvent>` → typed handler (T-fix-7).
- `Colors.white` / `Colors.black` literals → theme tokens (T-fix-8).
- Always-false `showAllChildren` flag (T-cleanup-1).

## Gaps Found

1. **`AllChildrenFailed` is invisible** — no error UI for a failed bootstrap fetch.
2. **Synthetic `ChildDetailsModel`** loses real `age` / `gender` / `birthday` / `series`; uses `item.id.toString()` as `age`.
3. **Search not debounced** — same as `search` feature.
4. **Enrollment status badge** missing; data path unclear.
5. **Re-ordering** missing.
6. **Doc-vs-code flavor mismatch** — features.md says parents, implementation is teachers.
