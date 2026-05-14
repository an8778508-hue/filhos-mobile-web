---
status: migrated
feature: all_children
migrated_from: lib/features/all_children/
migrated_date: 2026-05-14
---

# Implementation Plan: All Children

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/all_children/spec.md](spec.md) and code in [lib/features/all_children/](../../lib/features/all_children/).

## Summary

`all_children` is a teacher-facing list screen (despite the features.md `· P` tag — discrepancy documented in [spec.md Flavor Scope](spec.md#flavor-scope-mandatory-for-criarte)). It fetches a child list via `GET teacher/questions/data`, embeds `SearchBloc` for in-page filtering, and routes taps into `ChildDetailsSheet`.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `AllChildrenBloc extends Bloc<AllChildrenEvent, AllChildrenState>` with catch-all `on<AllChildrenEvent>` (same drift as `search` / `chat`).
- `get_it` — `AllChildrenInjection` registered at [init_dependencies.dart:120](../../lib/init_dependencies.dart#L120). ✓ Feature owns its DI class.
- `dio` via `NetworkClient.handleRequest`.
- Reuses `SearchBloc` from the `search` feature.

**Storage**: None.

**Testing**: None.

**Target Platform**: iOS + Android, professores flavor (per the entry-point gate; see spec discrepancy).

**Project Type**: Read-side list with embedded search.

**Performance Goals**: List render under 1.5 s on a warm network.

**Constraints**:

- Bootstrap and search are two independent blocs both bound to `SchoolItem`; the screen merges their outputs.
- Synthetic `ChildDetailsModel` mapping in `getDetailsFromSchoolItem` loses several real fields.

**Scale/Scope**: 6 .dart files, ~270 LOC.

## Project Structure

### Documentation (this feature)

```text
specs/all_children/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/all_children/
├── all_children_di.dart                    # AllChildrenInjection — feature root ✓
├── data_source/
│   └── all_children_dc.dart                # AllChildrenRepo + AllChildrenImpl
└── presentation/
    ├── all_children_screen.dart            # MultiBlocProvider(AllChildrenBloc + SearchBloc)
    └── bloc/
        ├── all_children_bloc.dart          # Bloc<AllChildrenEvent, AllChildrenState>
        ├── all_children_event.dart         # GetAllChildren
        └── all_children_state.dart         # Initial / Loading / Succeed(items) / Failed(failure)
```

### Cross-feature touch points

- [lib/features/search/](../../lib/features/search/) — `SearchBloc` is embedded; `ClearSearch`, `GlobalSearch` events used here.
- [lib/features/diary/models/school_item.dart](../../lib/features/diary/models/school_item.dart) — row type.
- [lib/features/diary/presentation/widgets/professor_questions/school_items_list.dart](../../lib/features/diary/presentation/widgets/professor_questions/school_items_list.dart) — list widget.
- [lib/core/components/sheets/child_details_sheet.dart](../../lib/core/components/sheets/child_details_sheet.dart) — destination on tap.
- [lib/core/models/child_details_model.dart](../../lib/core/models/child_details_model.dart) — synthesized model.
- [lib/features/settings/settings_screen.dart:134-143](../../lib/features/settings/settings_screen.dart#L134-L143) — entry point (gated on `context.isProfessors`).

## Implementation Phases

- **Phase 1 — Setup**: feature folder + `AllChildrenInjection`. ✓
- **Phase 2 — Foundational**: `AllChildrenRepo` + sealed `AllChildrenState`. ✓
- **Phase 3 — User Story 1 (list)**: screen + bloc + `SchoolItemsList`. ✓
- **Phase 4 — User Story 2 (filter)**: embedded `SearchBloc` + result-merge. ✓
- **Phase 5 — User Story 3 (detail)**: `getDetailsFromSchoolItem` + `ChildDetailsSheet`. ✓ (lossy synthesis)
- **Phase 6 — Gaps**: error UI for `AllChildrenFailed`, debounce, enrollment badge, re-ordering, doc fix on flavor scope. Pending — see [tasks.md](tasks.md).

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| Bootstrap via `teacher/questions/data` (same endpoint diary uses) | Reuses an endpoint that already returns the right child set. | Couples this screen to the diary's data shape. |
| Embed `SearchBloc` instead of owning a search method | Reuses the existing `globalSearchForProfessor` path. | Two independent blocs in `MultiBlocProvider`; their states are merged at render time. |
| Sealed `AllChildrenState` | Modern Dart sealed-class pattern. | Good. |
| Catch-all `on<AllChildrenEvent>` | Predates typed-handler convention. | Same drift as `search`. |
| Synthetic `ChildDetailsModel` from `SchoolItem` | Avoids a separate detail-fetch on tap. | Loses real `age`/`gender`/`birthday`/`series`. |

## Constitution Check

- [x] **I. Feature-First Layout** — `data_source/`, `presentation/`, with `bloc/` under `presentation/`. ✓
- [x] **II. Dependency Direction** — `AllChildrenInjection` at feature root and registered. ✓
- [x] **III. Networking Contract** — `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — N/A.
- [ ] **V. Flavor Branching** — feature has no internal branch but features.md tags `· P` and the call site gates on `context.isProfessors`. **Doc-vs-code discrepancy.**
- [x] **VI. Localization** — all visible strings routed. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reached from settings, post-login.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.w`/`.h`/`.sp`; `Colors.white`/`Colors.black` used for the appbar/scaffold + result tile color ([all_children_screen.dart:41, 92, 107, 115](../../lib/features/all_children/presentation/all_children_screen.dart#L41)) — ⚠️ should use `context.colors.*`.

## Dependencies

- Depends on `search`, `diary` (for `SchoolItem` + list widget), and `core/components/sheets/child_details_sheet.dart`.
- Consumed by `settings`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Catch-all `on<AllChildrenEvent>` | Predates typed-handler convention. | Refactor to `on<GetAllChildren>`. |
| `showAllChildren: false && !validList(items)` always-false flag | Leftover from an in-progress experiment. | Delete the dead flag. |
| Doc-vs-code flavor mismatch | features.md says parents; code is teacher. | Trust the code; fix features.md. |
| `AllChildrenFailed` not rendered | Failure state ignored at the screen. | Add error UI parity with the embedded `SearchFailed` branch. |
| `Colors.white` / `Colors.black` literals | Quick defaults. | Move to `context.colors.*`. |
| Synthetic `ChildDetailsModel` mapping loses real data | Avoids a per-tap detail fetch. | Either backfill from a detail endpoint or extend `SchoolItem` to carry the missing fields. |
