---
status: migrated
feature: settings/my_children
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: My Children

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/my_children/](../../../lib/features/settings/my_children/) with `bloc/`, `repo/`, `models/`, `widget/`.
- [x] T002 Add localization keys `my_children`, `no_children`.
- [x] T003 Register `MyChildrenRepo` singleton + `MyChildrenBloc` factory in [lib/core/dependency_injection/di.dart](../../../lib/core/dependency_injection/di.dart) (lines 71, 99).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `MyChildrenStates` / `ChildrenState` (data / loading / error).
- [x] T011 Implement `MyChildrenRepo.getChildren(page)` calling `GET /parent/children`.
- [x] T012 Wire `MyChildrenBloc` `FetchMyChildren(page)` → repo.

## Phase 3: User Story 1 — Browse children (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Build [my_children_screen.dart](../../../lib/features/settings/my_children/my_children_screen.dart) with `PaginationController<ChildModel>` + `PaginationWidget`.
- [x] T021 [US1] Render each child as `ChildItem` with avatar + name + classRoom.
- [x] T022 [US1] Push `DiaryScreen(child: child)` on tap.
- [x] T023 [US1] Show `EmptyWidget` with `no_children` when list is empty.

---

## Phase 4: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P2)** *(from [features.md#settings--b](../../features.md#settings--b))* Add a "remove child from account" path with a confirmation modal. Today there is no UX to unlink a child.

- [ ] **T-fix-2** **(P2)** [US1] `MyChildrenRepo.getChildren(page)` ignores the `page` argument — no `?page=` query param at [my_children_repo.dart:15-18](../../../lib/features/settings/my_children/repo/my_children_repo.dart#L15-L18). Either:
  - Plumb `page` into `queryParameters` if the backend supports pagination.
  - Strip `page` from `FetchMyChildren` and document that this list is always a single page (most parents have ≤ 5 kids — likely fine).

### Code hygiene

- [ ] **T-cleanup-1** Remove the dead `SubmitMyChildrenEvent` and its empty handler.
- [ ] **T-cleanup-2** Remove `ChildrenState.select(AreaModel)` (no-op).
- [ ] **T-cleanup-3** Rename folder `lib/features/settings/my_children/widget/` → `widgets/` to match sibling features. Touches one import in `my_children_screen.dart`.
- [ ] **T-cleanup-4** Decide on [models/my_children_model.dart](../../../lib/features/settings/my_children/models/my_children_model.dart) — the screen uses `ChildModel` everywhere. Delete or wire it.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: success / failure paths for `FetchMyChildren`.
- [ ] **T-test-2** [P] [US1] Widget test: tapping a child pushes `DiaryScreen` with the right `ChildModel`.

---

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze` after T-cleanup-*.
- [ ] **TX02** Manual test: parent with 0 / 1 / 5 children.

---

## Gaps Found

- **No "remove from account" / unlink flow** (features.md P2).
- **Page argument silently dropped** — pagination is theatrical today.
- **Vestigial `MyChildrenModel`** unused by the screen.
- **Dead `SubmitMyChildrenEvent`** event.

## Notes

- `MyChildrenRepo` is also depended on by `AddFormRepo` and `AddMedicineRepo`; any contract change ripples there.
