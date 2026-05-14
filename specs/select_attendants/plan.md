---
status: migrated
feature: select_attendants
migrated_from: lib/features/select_attendants/
migrated_date: 2026-05-14
---

# Implementation Plan: Select Attendants

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

**The feature is a `Placeholder()` widget today.** A single file containing 10 lines. This plan documents the *intended* shape (per [features.md](../features.md#select_attendants--b) and the surrounding form / event flows) so that whoever picks this up next has a clear starting point, and tracks the **naming collision** with [attendants_selection](../attendants_selection/) that should be resolved before any meaningful work is done.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies** (today): only `flutter/material.dart`.

**Primary Dependencies** (planned):

- `flutter_bloc` 9.1 — likely a `Cubit<SelectAttendantsState>` for the loaded children + selection set.
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart) — fetch children via the existing role-aware endpoint helper.
- `flutter_screenutil` 5.9.

**Storage**: none expected. Selection is per-form-instance.

**Testing**: none today, none planned until the feature is wired.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **single-file placeholder** today.

**Performance Goals**: list of ≤ ~50 children renders within one frame; selection toggle never blocks the UI.

**Constraints**:

- Must coexist with — or be merged into — [attendants_selection](../attendants_selection/). One picker per concern.
- Must respect [constitution principle V](../../.specify/memory/constitution.md): role selection via `isCurrentUserProfessor`, not `mainKey.currentContext`.

**Scale/Scope**: 1 .dart file, 10 LOC today. ~150-200 LOC expected after implementation.

## Constitution Check

- [x] **I. Feature-First Layout** — `lib/features/select_attendants/` exists at feature root with the single screen file. ✓ (will need `presentation/` + `data_sources/` + `models/` when fleshed out — see [tasks.md](tasks.md)).
- [x] **II. Dependency Direction** — no DI to register today.
- [x] **III. Networking Contract** — N/A today; planned per `NetworkClient.handleRequest` contract.
- [x] **IV. Persistence Discipline** — N/A.
- [x] **V. Flavor Branching** — N/A today; planned via `isCurrentUserProfessor`.
- [x] **VI. Localization** — N/A today (no strings); key reserved at [localization_keys.dart:199](../../lib/core/localization/localization_keys.dart#L199).
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — would inherit gate enforcement via the upstream caller (events/forms screens).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — N/A today; `Placeholder` is a Flutter-provided dev widget.

## Project Structure

### Documentation (this feature)

```text
specs/select_attendants/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/select_attendants/
└── select_attendants_screen.dart   # 10-line Placeholder
```

### Source Code (planned)

```text
lib/features/select_attendants/
├── select_attendants_di.dart
├── data_sources/
│   ├── select_attendants_repository.dart
│   └── select_attendants_impl.dart
├── models/
│   └── attendant_model.dart           # or reuse core ChildDetailsModel
└── presentation/
    ├── select_attendants_screen.dart
    └── bloc/
        ├── select_attendants_bloc.dart
        ├── select_attendants_event.dart
        └── select_attendants_state.dart
```

### Cross-feature touch points

- **[lib/features/add_form/](../../lib/features/add_form/)** — `AttendantsSelection` field type is the most likely caller.
- **[lib/features/attendants_selection/](../../lib/features/attendants_selection/)** — naming overlap (see [spec.md naming overlap](spec.md#naming-overlap-with-attendants_selection)).
- **[lib/core/models/child_details_model.dart](../../lib/core/models/)** — entity per row.

**Structure Decision**: Placeholder today. Standard layout when implemented; no deviations expected.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Two parallel features `select_attendants` and `attendants_selection` both stubbed | Historical — unclear which is "the" picker. | Merge into one feature, delete the other. See [tasks.md T-fix-1](tasks.md). |
| Feature exists with no real caller | Reserved-for-future-use scaffolding. | Either implement and wire to the caller (forms / events), or delete the directory. Tracked. |
