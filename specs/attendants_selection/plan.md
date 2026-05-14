---
status: migrated
feature: attendants_selection
migrated_from: lib/features/attendants_selection/
migrated_date: 2026-05-14
---

# Implementation Plan: Attendants Selection

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Multi-select picker scaffold. 1 .dart file, ~155 LOC. Reuses `DiaryBloc.GetSchoolItems` + `SearchBloc.ChildSearch` to populate a `SchoolItemsList`. **The "multi-select" half of the feature is not implemented** — tap callbacks are no-ops, no `selectedItems` state, no confirm CTA. **No caller is wired** — grep finds no references to `AttendantsSelectionScreen` outside its own file.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `DiaryBloc` + `SearchBloc` provided via `MultiBlocProvider`
- `get_it` 8 — `di<DiaryBloc>()` + `di<SearchBloc>()`
- `flutter_screenutil` 5.9

**Storage**: none directly.

**Testing**: none today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **single file at feature root** (not under `presentation/`).

**Performance Goals**: List of ≤ ~200 entries renders + debounced search at 60 fps.

**Constraints**:

- Cross-feature import of `DiaryBloc` and `SchoolItemsList` from [diary/](../../lib/features/diary/) and of `SearchBloc` from [search/](../../lib/features/search/). The picker couples to internals of two other features; any change there reshapes this one.
- Localization keys (`select_attendants`, `search_by_child_name`) imply **children**, but the feature description in [features.md](../features.md#attendants_selection--b) says "teachers/guardians." Copy mismatch.
- Selection state and confirm flow are entirely missing — this is half a feature.

**Scale/Scope**: 1 .dart file, ~155 LOC.

## Constitution Check

- [x] **I. Feature-First Layout** — `lib/features/attendants_selection/attendants_selection_screen.dart` at feature root (not under `presentation/`). Acceptable for a single-file feature, but inconsistent with the dominant pattern.
- [x] **II. Dependency Direction** — no DI registration at the feature level; consumes `di<DiaryBloc>()` + `di<SearchBloc>()` from other features' DI.
- [x] **III. Networking Contract** — N/A directly. Inherits from `DiaryBloc` / `SearchBloc`.
- [x] **IV. Persistence Discipline** — N/A.
- [ ] **V. Flavor Branching** — no flavor branches today. **Should** branch on `isCurrentUserProfessor` to source the right people list once a dedicated repo is introduced (T-fix-2).
- [x] **VI. Localization** — both visible strings are `.tr(context)`-ed. ⚠️ The keys themselves are child-oriented; copy mismatch is documented.
- [x] **VII. Chat Source of Truth** — N/A.
- [ ] **VIII. Approval Gate** — would be enforced upstream by the caller. No caller wired yet.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — uses `context.colors.*` and `.h`/`.w` correctly. ✓

## Project Structure

### Documentation (this feature)

```text
specs/attendants_selection/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/attendants_selection/
└── attendants_selection_screen.dart   # ~155-LOC scaffold; no caller
```

### Source Code (planned)

```text
lib/features/attendants_selection/
├── attendants_selection_di.dart
├── data_sources/
│   ├── attendants_repository.dart
│   └── attendants_impl.dart
├── models/
│   └── attendant_model.dart      # or reuse a core entity if appropriate
└── presentation/
    ├── attendants_selection_screen.dart
    ├── bloc/
    │   ├── attendants_selection_bloc.dart
    │   ├── attendants_selection_event.dart
    │   └── attendants_selection_state.dart
    └── widgets/
        └── attendant_row.dart    # toggleable row with "invited" badge
```

### Cross-feature touch points

- **[lib/features/diary/](../../lib/features/diary/)** — `DiaryBloc.GetSchoolItems`, `SchoolItemsList` reused.
- **[lib/features/search/](../../lib/features/search/)** — `SearchBloc.ChildSearch`, `ClearSearch`.
- **[lib/features/select_attendants/](../../lib/features/select_attendants/)** — naming collision (see [select_attendants/spec.md](../select_attendants/spec.md)).
- **[lib/core/components/widgets/error_widget.dart](../../lib/core/components/widgets/error_widget.dart)** — `ErrorScreen` + `EmptySearchResult`.

**Structure Decision**: Today's single-file layout matches the scaffold size. When the missing multi-select state, confirm flow, and dedicated data source are added (T-fix-1, T-impl-1), promote to the standard layout above.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Cross-feature consumption of `DiaryBloc` + `SchoolItemsList` | Avoids duplicating list / row UI. | Introduce an `AttendantsRepository` + `AttendantsBloc` and a dedicated `AttendantRow` widget; treat the diary's `SchoolItemsList` as a sibling, not a parent. [tasks.md T-fix-2](tasks.md). |
| No selection state — taps are no-ops | Feature is mid-build. | Add `Set<int> _selectedIds` to the State + a confirm CTA + `Navigator.pop(context, selectedIds)`. [tasks.md T-impl-1](tasks.md). |
| `showAllChildren: false && !validList(searchItems)` ([line 103](../../lib/features/attendants_selection/attendants_selection_screen.dart#L103)) | Typo / dead branch. | Remove `false &&` or rewrite the boolean. [tasks.md T-cleanup-1](tasks.md). |
| `Builder` wrapping `MultiBlocProvider` ([line 56](../../lib/features/attendants_selection/attendants_selection_screen.dart#L56)) | Vestigial — providers' context is already available via the closure. | Remove. [tasks.md T-cleanup-2](tasks.md). |
| File at feature root rather than `presentation/` | Acceptable for a single file. | Move when other files are added (along with bloc + repo). [tasks.md T-cleanup-3](tasks.md). |
| Child-oriented localization keys (`search_by_child_name`) for a "teachers/guardians" picker | Reuse of existing translations. | Add `search_by_name` (generic) or dedicated keys when wiring a real caller. [tasks.md T-fix-3](tasks.md). |
