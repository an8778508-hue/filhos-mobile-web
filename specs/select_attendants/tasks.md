---
status: migrated
feature: select_attendants
migrated_from: specs/features.md#select_attendants--b
migrated_date: 2026-05-14
---

# Tasks: Select Attendants

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#select_attendants--b](../features.md#select_attendants--b).

**Tests**: No `test/` directory; tests would be added alongside implementation.

## Migration summary

Feature is **a `Placeholder()` widget** ([select_attendants_screen.dart](../../lib/features/select_attendants/select_attendants_screen.dart)). The migration documents the intended contract and the naming collision with [attendants_selection](../attendants_selection/) that should be resolved first. No `[x]` tasks beyond directory creation.

---

## Phase 1: Setup — Partial

- [x] T001 Create [lib/features/select_attendants/](../../lib/features/select_attendants/)
- [x] T002 Reserve localization key `select_attendants` at [localization_keys.dart:199](../../lib/core/localization/localization_keys.dart#L199)
- [ ] T003 Add PT / EN / AR translations for any new keys when implemented (`select_all_in_class`, `no_children_available`, etc.)

## Phase 2: Foundational — Not started

- [ ] T010 Decide naming: keep `select_attendants` or `attendants_selection`. **One picker per concern.** See T-fix-1.
- [ ] T011 Define `AttendantSelection` result type (likely `List<int>` of child IDs).
- [ ] T012 Define `SelectAttendantsRepository` returning `Either<Failure, List<ChildDetailsModel>>` via `NetworkClient.handleRequest`.
- [ ] T013 Define `SelectAttendantsBloc` (Cubit) with states for loading / loaded(children, selectedIds) / failure.

## Phase 3: User Story 1 — Choose attending children (P1) MVP — Not started

- [ ] T020 [US1] Implement the screen: child rows with toggles, source from role-aware endpoint via `isCurrentUserProfessor`
- [ ] T021 [US1] Add a "select all in class" CTA visible only when `isCurrentUserProfessor == true` *(from [features.md task](../features.md#select_attendants--b))*
- [ ] T022 [US1] Pop the selection back to caller via `Navigator.pop(context, List<int>)`
- [ ] T023 [US1] Distinguish "already invited" vs "available" rows (shared requirement with [attendants_selection](../attendants_selection/spec.md))

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Architectural drift

- [ ] **T-fix-1** **(P1)** [architecture] **Resolve the naming collision** with [attendants_selection](../attendants_selection/). Today both directories exist, both are stubs, and neither has a real caller. Pick one name, delete the other directory, and update [features.md](../features.md) entries to point at the survivor. Recommendation: keep `attendants_selection` since it already has a richer scaffold (search + DiaryBloc reuse) and delete `select_attendants/` — but the team should confirm before action. **Blocks all other work in this feature.**

### Functional gaps (from features.md)

- [ ] **T-fix-2** *(from [features.md](../features.md#select_attendants--b))* Add "select all in class" shortcut for teachers (already restated in T021 above; tracked here for direct traceability to features.md).

### Implementation

- [ ] **T-impl-1** [US1] Wire the screen from the `add_form` engine's `AttendantsSelection` field type when the form schema includes it. Audit [lib/features/add_form/](../../lib/features/add_form/) to find the existing call site (or confirm it's a new field type to wire).

- [ ] **T-impl-2** [US1] If parents need to invite a *guardian* (not just a child) per [features.md attendants_selection](../features.md#attendants_selection--b) ("teachers/guardians"), expand the result to a tagged union of `child` / `guardian`. **NEEDS CLARIFICATION**: today the placeholder is silent on this — features.md says "Choose children attending" for `select_attendants` and "teachers/guardians" for `attendants_selection`. Likely the two features are deliberately distinct (children-only vs people-only), which reinforces that **T-fix-1 (naming collision)** is more nuanced than a simple delete.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test: list renders all children for a parent; toggling updates the selection set.
- [ ] **T-test-2** [P] [US1] Widget test: teacher sees "select all in class" CTA; tapping it selects all.
- [ ] **T-test-3** [P] [US1] Widget test: confirm round-trips the correct `List<int>` to the caller.

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| T-fix-1 | Two parallel features with overlapping names, both stubbed | Medium (P1) — blocks implementation |

## Gaps Found

- **Feature is a placeholder** — 10-line `Placeholder()` widget; nothing implemented.
- **Naming collision** with [attendants_selection](../attendants_selection/) is unresolved.
- **No caller wired** — grep returns no references to `SelectAttendantsScreen` outside its own file.
- **Unclear "children vs guardians" boundary** between this feature and `attendants_selection` (NEEDS CLARIFICATION in T-impl-2).

## Notes

- This is a **migration** of an existing (placeholder) feature. The `[x]` items are limited to directory existence and the reserved localization key.
- Until **T-fix-1** is resolved, do not invest in implementation here — work could be thrown away.
