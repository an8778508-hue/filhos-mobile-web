---
status: migrated
feature: search
migrated_from: lib/features/search/
migrated_date: 2026-05-14
---

# Implementation Plan: Search

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/search/spec.md](spec.md) and code in [lib/features/search/](../../lib/features/search/).

## Summary

`search` is a small feature (7 .dart files) that exposes three repo methods (`childSearch`, `globalSearchForProfessor`, `professorSearch`) and one `Bloc` driving two consumer surfaces: a dedicated `SearchScreen` reachable from home, and an embedded search bar in `AllChildrenScreen` (settings). The dedicated screen only fires `ChildSearch`; the embedded bar only fires `GlobalSearch`. `ProfessorSearch` has no dispatcher today.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `SearchBloc extends Bloc<SearchEvent, SearchState>` (uses catch-all `on<SearchEvent>` — same drift as chat).
- `get_it` — `SearchInjecion` (note typo in class name) at [search_di.dart](../../lib/features/search/search_di.dart). Registered via [init_dependencies.dart:118](../../lib/init_dependencies.dart#L118).
- `dio` via `NetworkClient.handleRequest` — `Either<Failure, T>` return.
- `equatable` for value semantics on events/states/models.

**Storage**: None. The bloc holds in-memory `schoolItemsResult` / `globalSearchResult`; state is rebuilt from the bloc on every screen mount.

**Testing**: None. The repo has no `test/` directory.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature, feature-first layout.

**Performance Goals**: Submit-to-render under 800 ms on a warm network. No debouncing today, so per-keystroke cost is N/A (submit-only).

**Constraints**:

- The dedicated `SearchScreen` hardcodes `ChildSearch` and therefore the teacher endpoint. A parent reaching it would still hit `/teacher/timeline/`.
- Catch-all `on<SearchEvent>` in [search_bloc.dart:18](../../lib/features/search/bloc/search_bloc.dart#L18) means typed handlers per event are missing; constitution drift relative to the "typed `on<Specific>` handlers" guidance set during the chat fix.

**Scale/Scope**: 7 .dart files, ~290 LOC. 3 endpoints, 1 bloc, 2 consumer screens.

## Project Structure

### Documentation (this feature)

```text
specs/search/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/search/
├── search_di.dart                       # SearchInjecion (typo) — DI at feature root
├── bloc/
│   ├── search_bloc.dart                 # Bloc<SearchEvent, SearchState> with catch-all on<SearchEvent>
│   ├── search_event.dart                # ChildSearch / GlobalSearch / ProfessorSearch / ClearSearch / ShowEmptySearch
│   └── search_state.dart                # SearchInitial / SearchLoading / SearchSucceed / SearchFailed / EmptySearchState
├── data_sources/
│   └── search_dc.dart                   # SearchRepo + SearchImpl (endpoints + parse)
├── models/
│   └── global_search.dart               # GlobalSearchResult { teachers, parents, children, levels }
└── presentation/
    └── search_screen.dart               # Dedicated full-screen search (fires ChildSearch only)
```

### Cross-feature touch points

- [lib/features/diary/models/school_item.dart](../../lib/features/diary/models/school_item.dart) — `SchoolItem` is the shared row type produced by the repo.
- [lib/features/diary/presentation/widgets/professor_questions/school_items_list.dart](../../lib/features/diary/presentation/widgets/professor_questions/school_items_list.dart) — list renderer; `EmptySearchResult` lives next to it.
- [lib/features/diary/presentation/widgets/professor_questions/professor_questions.dart](../../lib/features/diary/presentation/widgets/professor_questions/professor_questions.dart) — destination on tap from `SearchScreen`.
- [lib/features/all_children/presentation/all_children_screen.dart](../../lib/features/all_children/presentation/all_children_screen.dart) — embeds `SearchBloc` and fires `GlobalSearch(isTeacher: context.isProfessors)`.
- [lib/features/search_for_filter/bloc/search_for_filter_bloc.dart](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart) — reuses `SearchRepo.globalSearchForProfessor` directly.
- [lib/features/home/home_screen.dart:113](../../lib/features/home/home_screen.dart#L113) — entry point to `SearchScreen`.

## Implementation Phases

This feature is migrated from existing code; the phases below capture what shipped, not a forward plan.

- **Phase 1 — Setup**: feature folder + DI wired via `SearchInjecion`. ✓
- **Phase 2 — Foundational**: `SearchRepo` contract + `SearchImpl` with `NetworkClient.handleRequest`. ✓
- **Phase 3 — Surfaces**: `SearchScreen` (dedicated) + integration into `AllChildrenScreen` (embedded). ✓
- **Phase 4 — Gaps**: debouncer, recent searches, typed `on<Specific>` handlers, dead-code removal for `ProfessorSearch` (or wire a UI). Pending — see [tasks.md](tasks.md).

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| Bloc holds the last result as a field instead of in state | Lets the consumer `context.read<SearchBloc>().schoolItemsResult` outside the `BlocBuilder` closure for use in non-rebuild contexts. | Couples view code to bloc field semantics — a typed `success(items)` state would be cleaner. |
| Same endpoint path `/teacher/timeline/` reused for two parse shapes | Backend overloads response by request context. | Fragile — the parser at [search_dc.dart:90-123](../../lib/features/search/data_sources/search_dc.dart#L90-L123) has both branches with no version flag. |
| `isTeacher` flag is a UI selector, not a server role swap | Authorization token is still the user's real role; the flag picks the endpoint. | Means the flag does not pass any auth boundary on its own. |

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code is under `lib/features/search/` with `bloc/`, `data_sources/`, `models/`, `presentation/`. ✓
- [x] **II. Dependency Direction** — `SearchInjecion` (typo) lives at feature root, registered in `init_dependencies.dart`. ✓
- [x] **III. Networking Contract** — every REST call goes through `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — N/A (no persistence in this feature).
- [x] **V. Flavor Branching** — call site uses `context.isProfessors` to feed the `isTeacher` flag. ✓ (note the dedicated `SearchScreen` does not branch — see Complexity).
- [x] **VI. Localization** — `LocalizationKeys.search_by_child_name` used; no hardcoded strings. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — both consumer screens are post-login, after the approval-gate check.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.w`/`.h`/`.sp` everywhere; colors via `context.colors.*` except a single `const Color(0xffeceef1)` in [search_screen.dart:74](../../lib/features/search/presentation/search_screen.dart#L74). ⚠️ See tasks.md.

## Dependencies

- Depends on `diary` for `SchoolItem` and the result-list widgets.
- Depends on `all_children` as a consumer (via embedded `SearchBloc`).
- Depends on `search_for_filter` as a consumer of `SearchRepo.globalSearchForProfessor`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Catch-all `on<SearchEvent>` instead of typed `on<ChildSearch>` etc. | Predates the chat refactor; works. | Typed handlers were introduced repo-wide during the 2026-05-14 chat fixes — search should be brought in line; non-blocking. |
| `SearchScreen` always fires `ChildSearch` regardless of flavor | UX intent on `professores` is child search. | A parent reaching the screen still hits the teacher endpoint; either guard the icon by flavor at the home shell, or make the screen flavor-aware. |
| Hardcoded `Color(0xffeceef1)` in [search_screen.dart:74](../../lib/features/search/presentation/search_screen.dart#L74) | Light-grey search field bg. | Use `context.colors.secondaryScaffold` or similar token. |
| Stray `debugPrint` placeholders | Leftover debug. | Remove. |
| `ShowEmptySearch` event with no dispatcher | Dead. | Delete or wire it from somewhere meaningful. |
