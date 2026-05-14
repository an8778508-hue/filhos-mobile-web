---
status: migrated
feature: attendants_selection
flavor_scope: both
migrated_from: specs/features.md#attendants_selection--b
migrated_date: 2026-05-14
---

# Feature Specification: Attendants Selection

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated (scaffolded — feature has UI but no real caller / wiring)

**Input**: Reverse-engineered from [lib/features/attendants_selection/](../../lib/features/attendants_selection/) and [features.md `## attendants_selection · B`](../features.md#attendants_selection--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both. Per features.md, the picker covers "teachers/guardians" — a multi-select used to invite people (not children) to something.
- **Flavor-conditional behavior**: not surfaced today. Teachers viewing the picker will get a class roster source; parents will get their authorized-guardians list. The current screen reuses `DiaryBloc.GetSchoolItems` regardless of role — *Gap-1: role-aware data source missing.*
- **Server role implication**: indirect — the loaded list (`DiaryBloc.diaryItems`) is whatever `GetSchoolItems` returns for the current authenticated user; the role header drives that endpoint's behavior server-side.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Multi-select teachers/guardians (Priority: P1) MVP

A user opens the attendants picker (intent: invite multiple people to an event / form / pickup authorization). They see a searchable list. They toggle multiple rows. They confirm; the selection rides back to the caller.

**Why this priority**: This is the explicit purpose per [features.md](../features.md#attendants_selection--b): "Multi-select picker for attendants (teachers/guardians)."

**Independent Test** (target behavior — partially implemented):
1. Open the screen (no caller wired today; instantiated only by test harness).
2. Verify the search field renders + `DiaryBloc.GetSchoolItems` dispatches on mount.
3. Type a query; `SearchBloc.ChildSearch(query)` fires with debounce.
4. Confirm `SchoolItemsList` renders the filtered or unfiltered items.
5. Toggle selection (**not implemented today** — `SchoolItemsList.onSchoolItemsPressed` is a no-op `(item) {}`).
6. Confirm; receive the selected IDs back at the caller (**not implemented today**).

**Acceptance Scenarios**:

1. **Given** the screen mounts, **When** `BlocProvider<DiaryBloc>` is created, **Then** `GetSchoolItems()` is dispatched immediately ([attendants_selection_screen.dart:53](../../lib/features/attendants_selection/attendants_selection_screen.dart#L53)).
2. **Given** `DiaryBloc` is loading or `SearchBloc` is loading or `DiaryBloc` is in `DiaryInitial`, **When** the body renders, **Then** a centered `Loading()` widget shows.
3. **Given** the user types into the search field with a non-empty string, **When** `onSearch` fires, **Then** `SearchBloc.add(ChildSearch(query: value))` runs.
4. **Given** `searchItems` is non-null but empty, **When** the body renders, **Then** `EmptySearchResult` widget shows.
5. **Given** `searchItems` is non-null and non-empty, **When** the body renders, **Then** `SchoolItemsList(items: searchItems, ...)` shows.
6. **Given** `diaryState is SchoolItemsError`, **When** the body renders, **Then** an `ErrorScreen` with `onRetry: () => DiaryBloc.add(GetSchoolItems())` is shown.
7. **Given** `searchState is SearchFailed`, **When** the body renders, **Then** an `ErrorScreen` with `onRetry: () => SearchBloc.add(ChildSearch(query: _searchController.text))` is shown.

---

### Edge Cases

- **No caller**: grep returns zero references to `AttendantsSelectionScreen` outside its own file. The feature is scaffolded but not invoked by any flow. *Gap-2.*
- **Selection callbacks are no-ops**: `onSchoolItemsPressed: (item) {}` at lines [104](../../lib/features/attendants_selection/attendants_selection_screen.dart#L104) and [111](../../lib/features/attendants_selection/attendants_selection_screen.dart#L111) — tapping a row does nothing. There is no `selectedItems` state, no "confirm" CTA, no `Navigator.pop(selection)`. *Gap-3 — the "multi-select" behavior promised by the feature name is not implemented.*
- **`DiaryBloc` reuse**: the picker is built on top of [diary/](../../lib/features/diary/)'s `DiaryBloc.GetSchoolItems` + `SchoolItemsList`. This is a **cross-feature import** — `DiaryBloc` is owned by the diary feature. Reuse is pragmatic but creates a coupling: any change to the diary's school-items contract reshapes this picker.
- **No "already invited" vs "available" distinction**: features.md task — "Distinguish 'already invited' vs. 'available' states." Today the rows all render identically. *Gap-4.*
- **`showAllChildren: false && !validList(searchItems)`** at [line 103](../../lib/features/attendants_selection/attendants_selection_screen.dart#L103) — the `false &&` makes the entire expression always `false`. Dead branch / typo. *Cleanup item.*
- **`Builder` wrapping the `MultiBlocProvider`** at [line 56](../../lib/features/attendants_selection/attendants_selection_screen.dart#L56) — unnecessary in this position (the providers' `context` is already available); leftover scaffolding.
- **`SchoolItemsList.showAllChildren: false`** is hardcoded in both branches — unclear why a multi-select picker would need that flag at all.
- **Naming collision with [select_attendants](../select_attendants/)** — see that feature's spec for the cross-cutting discussion. The two features overlap in name and intent.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a search field at the top with the localized hint `search_by_child_name`. Tapping the clear button MUST dispatch `SearchBloc.ClearSearch`.
- **FR-002**: System MUST dispatch `DiaryBloc.GetSchoolItems()` on mount.
- **FR-003**: System MUST show a loading state while either bloc is loading or `DiaryBloc` is in `DiaryInitial`.
- **FR-004**: System MUST show search results when `SearchBloc.schoolItemsResult` is non-null. An empty result shows `EmptySearchResult`; a non-empty result shows `SchoolItemsList`.
- **FR-005**: System MUST show the full `DiaryBloc.diaryItems` list when no search is active.
- **FR-006**: System MUST show an `ErrorScreen` with retry on either bloc's failure state.
- **FR-007**: System MUST allow multi-selection of rows (toggle on tap). *Not implemented today.*
- **FR-008**: System MUST distinguish "already invited" vs "available" rows visually (e.g. checkmark + disabled state). *Not implemented — [features.md task](../features.md#attendants_selection--b).*
- **FR-009**: System MUST surface a "Confirm" CTA that pops with the selected IDs back to the caller. *Not implemented today.*
- **FR-010**: System MUST source the people list from a role-aware endpoint. *Today reuses `DiaryBloc.GetSchoolItems`; verify this is the right contract or replace with a dedicated `AttendantsRepository`.*

### Localization Requirements

| Key | Use site |
|---|---|
| `select_attendants` | screen title ([attendants_selection_screen.dart:46](../../lib/features/attendants_selection/attendants_selection_screen.dart#L46)) |
| `search_by_child_name` | search field hint ([line 73](../../lib/features/attendants_selection/attendants_selection_screen.dart#L73)) |

⚠️ Both keys are oriented around **children** (`select_attendants` is reused here, `search_by_child_name` is explicitly child-named) — but features.md describes this picker as covering "teachers/guardians." Localization keys imply children. *Gap-5: copy mismatch between feature description and reused keys.*

### Backend Touchpoints

- **REST**: indirect — `DiaryBloc.GetSchoolItems` and `SearchBloc.ChildSearch` reach `diary/` and `search/` repos via `NetworkClient.handleRequest`. No dedicated endpoint for this feature today.
- **Firestore**: none.
- **FCM**: none.

### Permissions & Approval Gate

- Requires `isApproval == true`. Reachable only from inside authenticated event/form flows when wired.
- Device permissions: none required.

### Key Entities

- **`DiaryBloc`** (cross-feature, [diary/](../../lib/features/diary/)) — loads `diaryItems` via `GetSchoolItems`.
- **`SearchBloc`** (cross-feature, [search/](../../lib/features/search/)) — runs `ChildSearch(query)`, stores `schoolItemsResult`.
- **`SchoolItemsList`** ([diary/.../professor_questions/school_items_list.dart](../../lib/features/diary/presentation/widgets/professor_questions/school_items_list.dart)) — the rendered list widget.
- **`EmptySearchResult`** / **`ErrorScreen`** / **`Loading`** / **`MyAppBar`** / **`SearchField`** — core components.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: User can search, toggle multiple rows, confirm, and the selection round-trips to the caller. *Not achievable today — selection is a no-op.*
- **SC-002**: "Already invited" rows are visually distinct from "available" rows.
- **SC-003**: Network failure surfaces an `ErrorScreen` with a working retry — **achievable today.**
- **SC-004**: Empty search returns a clear empty-state UI — **achievable today.**

## Assumptions

- The intended caller is the events / forms flow (e.g. an `attendants` field in `add_form` or an "invite" CTA on an event). **Not wired in code today.**
- `DiaryBloc.GetSchoolItems` returns the right list for this picker's purpose. **NEEDS CLARIFICATION** — the bloc is owned by diary and its name suggests children/school-roster, not "teachers/guardians." Confirm with the team whether to reuse or to create an `AttendantsRepository`.
- The naming collision with [select_attendants](../select_attendants/) will be resolved (see that feature's spec). Until then, treat this feature as the **more-developed scaffold** of the two but **not yet usable as a multi-select picker**.
- The "Distinguish 'already invited' vs. 'available'" task in features.md will be honored when wiring a caller, since callers will supply the pre-invited set.
