---
status: migrated
feature: search_for_filter
migrated_from: lib/features/search_for_filter/
migrated_date: 2026-05-14
---

# Implementation Plan: Search-for-Filter

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/search_for_filter/spec.md](spec.md) and code in [lib/features/search_for_filter/](../../lib/features/search_for_filter/).

## Summary

`search_for_filter` is a **reusable picker** screen. It depends on the `search` feature's `SearchRepo` (no repo of its own), wraps the result in a typed `SearchForFilterModelType`, and pops the chosen `SchoolItem` back to the caller. Today it is used by exactly one consumer — [core/components/sheets/filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart) — for three picker variants (teacher / childOrParent / level).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `SearchForFilterBloc extends Bloc<SearchForFilterEvent, SearchForFilterState>` with catch-all `on<SearchForFilterEvent>`.
- `get_it` — registered directly in [init_dependencies.dart:86](../../lib/init_dependencies.dart#L86); no per-feature DI class.
- Reuses `search` feature's `SearchRepo` — no own data layer.

**Storage**: None at runtime. `LocalDatabaseRepo` is injected but unused.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Reusable UI feature consumed by other features.

**Performance Goals**: Submit-to-result under 800 ms (server-bound — same path as `search`).

**Constraints**:

- Must remain a self-contained `Navigator.push` target that returns a `SchoolItem?` — callers depend on this shape ([filter_sheet.dart:91-99, 129-138, 169-178](../../lib/core/components/sheets/filter_sheet.dart#L91-L99)).
- `classType` is currently a dead branch — see Complexity Tracking.

**Scale/Scope**: 7 .dart files, ~230 LOC.

## Project Structure

### Documentation (this feature)

```text
specs/search_for_filter/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/search_for_filter/
├── search_for_filter_screen.dart        # Entry — pushed as MaterialPageRoute by callers
├── bloc/
│   ├── search_for_filter_bloc.dart      # Uses SearchRepo.globalSearchForProfessor
│   ├── search_for_filter_event.dart     # GetSearchForFilterItems / SubmitSearchForFilter / ClearSearchForFilter
│   └── search_for_filter_state.dart     # Initial / Loading / Succeed / Error (+ unused ChangeValueLoading/Succeed/ActivitiesLoading)
├── model/
│   └── search_for_filter_model.dart     # SearchForFilterModel class (unused) + SearchForFilterModelType enum (used)
└── widgets/
    ├── search_for_filter_items_list.dart   # ListView wrapper
    └── search_for_filter_list_item.dart    # Single-row tile
```

### Cross-feature touch points

- [lib/features/search/data_sources/search_dc.dart](../../lib/features/search/data_sources/search_dc.dart) — `SearchRepo` and the `/teacher/timeline/` / `/parent/timeline` endpoints are reused as-is.
- [lib/features/search/models/global_search.dart](../../lib/features/search/models/global_search.dart) — `GlobalSearchResult` holds the bloc's last successful result.
- [lib/features/diary/models/school_item.dart](../../lib/features/diary/models/school_item.dart) — the actual row type returned via `Navigator.pop`.
- [lib/core/components/sheets/filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart) — the only known consumer (3 call sites at lines 92, 132, 172).
- [lib/core/local_db/local_db_repo.dart](../../lib/core/local_db/local_db_repo.dart) — injected dependency; not yet exercised (placeholder for FR-007).

## Implementation Phases

This feature was migrated; the phases reflect history.

- **Phase 1 — Setup**: feature folder + direct DI registration in `init_dependencies.dart`. ✓
- **Phase 2 — Foundational**: bloc + states + events; reuse of `search` repo. ✓
- **Phase 3 — Reusable surface**: screen + list widgets; `filter_sheet.dart` consumes the picker. ✓
- **Phase 4 — Gaps**: error UI, `classType` resolution, persistence (FR-006/7/8), DI class (constitution drift). Pending — see [tasks.md](tasks.md).

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| Reuse `SearchRepo` rather than own a `SearchForFilterRepo` | The data shape is identical; one less HTTP path. | Couples this feature to `search` lifetime; an upstream rename ripples here. |
| Pop a `SchoolItem` rather than the local `SearchForFilterModel` | Callers want the canonical domain type. | The local `SearchForFilterModel` is dead code; see tasks.md. |
| Bloc field `searchForFilterItems` outside state | Lets the screen read the last result without a `BlocBuilder` rebuild. | Same drift as `search`. |
| `LocalDatabaseRepo` injected up-front | Forward-compat for "persist last filters" feature work. | Currently unused; document. |

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — feature owns `bloc/`, `model/`, `widgets/`, and its screen at the root. ✓
- [ ] **II. Dependency Direction** — no `SearchForFilterInjection` class at feature root. Direct `di.registerFactory<SearchForFilterBloc>` in `init_dependencies.dart`. ⚠️ See tasks.md T-fix-DI.
- [x] **III. Networking Contract** — borrows `SearchRepo`, which routes through `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — N/A today (placeholder injection of `LocalDatabaseRepo`).
- [x] **V. Flavor Branching** — `context.isProfessors` fed into `isTeacher`. ✓
- [x] **VI. Localization** — `LocalizationKeys.search` used; no hardcoded strings. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reachable only via authenticated feature flows.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.w`/`.h`/`.sp` everywhere; `context.colors.*` tokens used.

## Dependencies

- `search` (for `SearchRepo` + `GlobalSearchResult`).
- `diary` (for `SchoolItem` row type).
- Consumed by `core/components/sheets/filter_sheet.dart`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Bloc constructed with unused `LocalDatabaseRepo` | Forward-compat for FR-007. | Inject it when we wire persistence; keeps the constructor honest. |
| `SearchForFilterModel` class with `fromJson` and `name`/`classRoom`/etc. — never instantiated | Originally planned to be the row type before `SchoolItem` was reused. | Delete the class; keep only the enum (or move the enum out and delete the file). |
| `classType` branch always returns `[]` | Reserved for a future class-picker variant. | Either implement or remove from the enum + callers. |
| `GetSearchForFilterItems` event with commented-out handler | Earlier draft of an initial-preload path. | Delete event + the `hasInitial` constructor arg. |
| Catch-all `on<SearchForFilterEvent>` | Predates the typed-handler convention. | Same fix as `search` and `chat`. |
| Empty placeholder states `SearchForFilterActivitiesLoading` / `ChangeValueLoading` / `ChangeValueSucceed` | Unused leftovers. | Delete. |
| Hardcoded `Colors.white` in [search_for_filter_items_list.dart:22](../../lib/features/search_for_filter/widgets/search_for_filter_items_list.dart#L22) | Light background. | Use `context.colors.background`. |
