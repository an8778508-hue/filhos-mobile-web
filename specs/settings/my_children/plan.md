---
status: migrated
feature: settings/my_children
migrated_from: lib/features/settings/my_children/
migrated_date: 2026-05-14
---

# Implementation Plan: My Children

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/my_children/spec.md](spec.md) and code in [lib/features/settings/my_children/](../../../lib/features/settings/my_children/).

## Summary

Parents-only screen listing the parent's enrolled children. Uses the shared `PaginationController<ChildModel>` + `PaginationWidget`; backend currently returns the full roster regardless of `page`. Tapping a child pushes the diary view for that child.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0`.

**Primary Dependencies**:

- `flutter_bloc` — `MyChildrenBloc extends Bloc<MyChildrenEvents, MyChildrenStates>`.
- `dartz` — `Either<Failure, List<ChildModel>>`.
- `get_it` — `di<MyChildrenBloc>` factory.
- `flutter_screenutil` — sizing.
- Shared `PaginationController` / `PaginationWidget` from `lib/core/components/widgets/pagination_widget.dart`.

**Storage**: none.

**Testing**: none.

**Target Platform**: iOS + Android, **parents flavor only**.

**Project Type**: Flutter mobile feature with bloc/repo split.

**Performance Goals**: List interactive after 1 REST round-trip (~1-2s).

**Constraints**: `MyChildrenRepo` is also injected into `AddFormRepo` and `AddMedicineRepo` ([di.dart:77, 81](../../../lib/core/dependency_injection/di.dart#L77)) — changing its public contract affects those features.

**Scale/Scope**: ~150 LOC across 5 files.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/`, `repo/`, `models/`, `widget/`, screen at root. ✓ (Note: `widget/` is singular here vs sibling `widgets/`. Cosmetic.)
- [x] **II. Dependency Direction** — imports `lib/core/*` and `lib/features/diary/models/child_model.dart` (shared model — acceptable).
- [x] **III. Networking Contract** — `NetworkClient.handleRequest` → `Either`. ✓
- [x] **IV. Persistence Discipline** — N/A; no Hive / hydrated state.
- [x] **V. Flavor Branching** — feature is parents-only; gated at Settings shell row.
- [x] **VI. Localization** — `my_children` + `no_children` only. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit downstream of Settings.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h/.w` + `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/settings/my_children/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/my_children/
├── my_children_screen.dart                # screen + pagination wiring
├── bloc/
│   ├── my_children_bloc.dart              # Bloc<MyChildrenEvents, MyChildrenStates>
│   ├── my_children_events.dart            # FetchMyChildren(page), SubmitMyChildrenEvent (unused)
│   └── my_children_states.dart            # ChildrenState (data/loading/error)
├── repo/
│   └── my_children_repo.dart              # getChildren(page) → /parent/children
├── models/
│   └── my_children_model.dart             # ⚠️ likely vestigial; screen uses ChildModel
└── widget/                                 # ⚠️ singular vs sibling 'widgets/'
    └── child_item.dart                    # row widget
```

### Cross-feature touch points

- [lib/features/diary/](../../../lib/features/diary/) — `ChildModel` and `DiaryScreen` (navigation target).
- [lib/features/add_form/repo/add_form_repo.dart](../../../lib/features/add_form/repo/add_form_repo.dart) — depends on `MyChildrenRepo`.
- [lib/features/add_medicine/repo/add_medicine_repo.dart](../../../lib/features/add_medicine/repo/add_medicine_repo.dart) — depends on `MyChildrenRepo`.
- [lib/core/components/widgets/pagination_widget.dart](../../../lib/core/components/widgets/pagination_widget.dart) — shared paginator.

**Structure Decision**: standard layout. Folder name `widget/` (singular) is a minor inconsistency.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `Bloc` with `SubmitMyChildrenEvent` (declared but never dispatched) | Vestigial scaffolding from a shared template. | Delete the dead event. **See tasks.md T-cleanup-1.** |
| `ChildrenState.select(AreaModel)` returning a no-op | Copy-paste from `AreaState`. | Delete. **See tasks.md T-cleanup-2.** |
| Folder name `widget/` (singular) | Inconsistent with sibling features. | Rename — touches 1 import. **See tasks.md T-cleanup-3.** |
