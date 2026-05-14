---
status: migrated
feature: search
flavor_scope: both
migrated_from: specs/features.md#search--b
migrated_date: 2026-05-14
---

# Feature Specification: Search

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/search/](../../lib/features/search/) and the existing [features.md `## search · B`](../features.md#search--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**:
  - Endpoint selection is driven by an `isTeacher` flag passed in `GlobalSearch(query, isTeacher)` ([search_event.dart:20](../../lib/features/search/bloc/search_event.dart#L20)). The repo at [search_dc.dart:82](../../lib/features/search/data_sources/search_dc.dart#L82) routes `isTeacher == true` to `/teacher/timeline/` (returns children) and `isTeacher == false` to `/parent/timeline` (returns mixed parents / professors / levels).
  - The only on-screen call site that fires `GlobalSearch` is [all_children_screen.dart:84](../../lib/features/all_children/presentation/all_children_screen.dart#L84): `GlobalSearch(query: value, isTeacher: context.isProfessors)`.
  - The dedicated `SearchScreen` ([search_screen.dart:84](../../lib/features/search/presentation/search_screen.dart#L84)) only dispatches `ChildSearch` (calls `/teacher/timeline/`). It is reachable from `HomeScreen` via [home_screen.dart:113](../../lib/features/home/home_screen.dart#L113) on both flavors. **Gap**: this means a parent reaching `SearchScreen` from home still hits the teacher endpoint — see [Edge Cases](#edge-cases).
- **Server role implication**: The flag is the *intent* (teacher-vs-parent search semantics), not a Bearer-token role swap. The interceptor still attaches the user's real `Authorization` token. Backend trust boundary therefore relies on the token; the flag is a UX selector.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Teacher searches children (Priority: P1) 🎯 MVP

A teacher opens the search screen, types a child's name, and gets back a list of children matching that query.

**Why this priority**: Teachers need to find a specific child to open their diary/profile quickly. This is the primary search surface for the `professores` flavor.

**Independent Test**:
1. Launch the professores flavor.
2. From `HomeScreen`, tap the search icon → `SearchScreen` opens.
3. Type a name and submit.
4. Confirm a list of `SchoolItem` (childType) renders.
5. Tap a result → navigates to `ProfessorQuestions(item: item)` (the diary editor).

**Acceptance Scenarios**:

1. **Given** a teacher is on `SearchScreen`, **When** they type a non-empty query and submit, **Then** the bloc emits `SearchLoading` then `SearchSucceed` with `schoolItemsResult` populated from `GET /teacher/timeline/?q=<query>` ([search_dc.dart:28-42](../../lib/features/search/data_sources/search_dc.dart#L28-L42)).
2. **Given** results are showing, **When** the user taps clear, **Then** `ClearSearch` resets `schoolItemsResult` to null and the empty pre-search view is shown ([search_bloc.dart:25-30](../../lib/features/search/bloc/search_bloc.dart#L25-L30)).
3. **Given** a successful search returns zero rows, **When** the state transitions to `SearchSucceed` with `schoolItemsResult.isEmpty`, **Then** an `EmptySearchResult` widget is shown ([search_screen.dart:102-106](../../lib/features/search/presentation/search_screen.dart#L102-L106)).
4. **Given** the request fails, **When** `SearchFailed` is emitted, **Then** an `ErrorScreen` with `onRetry` is rendered that re-dispatches `ChildSearch` with the current controller text ([search_screen.dart:116-127](../../lib/features/search/presentation/search_screen.dart#L116-L127)).

---

### User Story 2 - Parent / teacher global search from "all children" (Priority: P2)

From `AllChildrenScreen` (settings → teachers see "all children"), a user types a query and the screen dispatches `GlobalSearch(query, isTeacher: context.isProfessors)`. Results are split into children + parents (teachers' view) or parents + professors + levels (parents' view — speculative; the parent path is not surfaced anywhere reachable today).

**Why this priority**: Lets a teacher search across the school for a child or parent without first navigating to a class roster.

**Independent Test**:
1. Launch professores flavor, open `AllChildrenScreen`.
2. Type a name in the search field.
3. Confirm the bloc fires `GlobalSearch(isTeacher: true)` and the response from `/teacher/timeline/?q=<query>` is parsed into `GlobalSearchResult.children` (because `isTeacher == false` branch is for the parent path).
4. Tapping a result opens `ChildDetailsSheet`.

**Acceptance Scenarios**:

1. **Given** `isTeacher == true`, **When** results return as a JSON list, **Then** every row is mapped to `SchoolItem` with `SchoolItemType.childType` ([search_dc.dart:104](../../lib/features/search/data_sources/search_dc.dart#L104)).
2. **Given** `isTeacher == false`, **When** results return as a JSON list, **Then** each row is dispatched by its `type` field — `'Parent'` → parents, `'professor'` → teachers, `'Level'` → levels ([search_dc.dart:94-102](../../lib/features/search/data_sources/search_dc.dart#L94-L102)).
3. **Given** the server returns a categorized object instead of a flat list, **When** parsed, **Then** the `data.{teachers,parents,children,levels}` arrays are merged into the `GlobalSearchResult` ([search_dc.dart:108-123](../../lib/features/search/data_sources/search_dc.dart#L108-L123)).

---

### User Story 3 - Professor (teacher) lookup (Priority: P3)

A user dispatches `ProfessorSearch(query)` and the repo calls `GET teacher/teacher-search?q=<query>` returning teachers only.

**Why this priority**: Endpoint exists in the repo ([search_dc.dart:135-149](../../lib/features/search/data_sources/search_dc.dart#L135-L149)) but **no UI surface in the codebase dispatches `ProfessorSearch`**. Carried for completeness; flagged as dead/unused below.

**Acceptance Scenarios**:

1. **Given** code that dispatches `ProfessorSearch(query)`, **When** the request succeeds, **Then** `globalSearchResult` is set to a `GlobalSearchResult` with only `teachers` populated and other lists empty ([search_bloc.dart:51-66](../../lib/features/search/bloc/search_bloc.dart#L51-L66)).

---

### Edge Cases

- **Empty query**: `stringNotNullOrEmpty(value)` gates dispatch in both [search_screen.dart:81-86](../../lib/features/search/presentation/search_screen.dart#L81-L86) and [all_children_screen.dart:83-86](../../lib/features/all_children/presentation/all_children_screen.dart#L83-L86). An empty submission is a no-op.
- **No debouncing**: The text field calls `onSearch` on submit/enter only (see `SearchField` behavior), so per-keystroke debouncing is not strictly required — but features.md asks for it. The repo already ships [lib/core/utils/debouncer.dart](../../lib/core/utils/debouncer.dart). **Not currently wired into `SearchScreen` or `AllChildrenScreen`** → [tasks.md T-fix-1](tasks.md#gap-debouncing).
- **Recent searches**: Not implemented; features.md asks for it.
- **`SearchScreen` from parents flavor still hits `/teacher/timeline/`**: `_childSearch` calls the teacher endpoint regardless of flavor. Whether a parent can open `SearchScreen` from home depends on the home shell; today the home-screen icon at [home_screen.dart:113](../../lib/features/home/home_screen.dart#L113) is unconditional. **Unconfirmed whether the backend accepts that endpoint with a parent token** → `[NEEDS CLARIFICATION]`.
- **Stray debug print** in [search_bloc.dart:43](../../lib/features/search/bloc/search_bloc.dart#L43): `debugPrint('sssssssssssssssssssssssssssss')` and another in [search_dc.dart:98](../../lib/features/search/data_sources/search_dc.dart#L98).
- **Catch-all `on<SearchEvent>`** in [search_bloc.dart:18](../../lib/features/search/bloc/search_bloc.dart#L18) — same constitution drift the chat feature has; should use typed handlers.
- **`ShowEmptySearch` event** ([search_event.dart:31](../../lib/features/search/bloc/search_event.dart#L31)) is defined and handled but nothing dispatches it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose three search modes via `SearchBloc`: `ChildSearch` (teacher endpoint), `GlobalSearch(isTeacher)` (teacher- vs parent-flavored global), and `ProfessorSearch` (teacher-search endpoint).
- **FR-002**: System MUST route `GlobalSearch` to `/teacher/timeline/` when `isTeacher == true` and to `/parent/timeline` when `isTeacher == false` ([search_dc.dart:82](../../lib/features/search/data_sources/search_dc.dart#L82)).
- **FR-003**: System MUST gate request dispatch on a non-empty query via `stringNotNullOrEmpty`.
- **FR-004**: System MUST surface server failures as `SearchFailed(failure)` and present a retry affordance.
- **FR-005**: System MUST clear bloc state (`schoolItemsResult` / `globalSearchResult`) on `ClearSearch`.
- **FR-006**: System MUST tolerate the two response shapes the backend currently emits — flat list with `type` discriminator and categorized object with `{teachers,parents,children,levels}` arrays ([search_dc.dart:90-123](../../lib/features/search/data_sources/search_dc.dart#L90-L123)).
- **FR-007**: `SearchScreen` MUST navigate to `ProfessorQuestions(item)` on result tap ([search_screen.dart:110-114](../../lib/features/search/presentation/search_screen.dart#L110-L114)).
- **FR-008** (gap from features.md): System SHOULD debounce keystrokes via [core/utils/debouncer.dart](../../lib/core/utils/debouncer.dart) to avoid hammering the search endpoint when used live (today: submit-only).
- **FR-009** (gap from features.md): System SHOULD persist recent searches (per-user) so the screen can offer suggestions before any keystroke.

### Localization Requirements

Keys actually used by this feature:

| Key | Use site |
|---|---|
| `search_by_child_name` | `SearchField` hint on `SearchScreen` |

Translations live in [assets/langs/pt.json](../../assets/langs/pt.json) / [en.json](../../assets/langs/en.json) / [ar.json](../../assets/langs/ar.json). No new keys required.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET teacher/timeline/?q=<query>` — used by both `ChildSearch` and `GlobalSearch(isTeacher: true)`. Note the two clients consume the same response in different shapes (child list vs typed sections).
  - `GET parent/timeline?q=<query>` — used by `GlobalSearch(isTeacher: false)`.
  - `GET teacher/teacher-search?q=<query>` — used by `ProfessorSearch`. **No dispatcher in the codebase** (dead UI surface).
- **Headers**: standard `Authorization` + `school_id` + `lang` from [NetworkInterceptor](../../lib/core/network/network_interceptor.dart). Nothing search-specific.
- **Firebase / Firestore**: not used by this feature.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **Yes (implicit)** — both surfaces (`SearchScreen` from home, `AllChildrenScreen` from settings) are post-login. A user with `isApproval == false` lands on `your_account_under_review` and cannot reach either screen.
- No device permissions required.

### Key Entities

- **`SchoolItem`** (shared from [lib/features/diary/models/school_item.dart](../../lib/features/diary/models/school_item.dart)) — discriminated by `SchoolItemType { classType, childType, allChildType, allTeachersType, all, level, parentType, teacherType }`. Search emits `childType`, `teacherType`, `parentType`, `level`.
- **`GlobalSearchResult`** ([global_search.dart](../../lib/features/search/models/global_search.dart)) — `{teachers, parents, children, levels}`; all `List<SchoolItem>`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A teacher can find a child by partial name from `SearchScreen` in under 2 seconds (server-bound).
- **SC-002**: An empty result set renders `EmptySearchResult` rather than a blank screen.
- **SC-003**: A failed request renders an `ErrorScreen` with a working retry that re-issues the last query.
- **SC-004**: Adding a Debouncer with a 300-400ms window (FR-008) reduces redundant `/teacher/timeline/` calls in live-typing scenarios by ≥80%.

## Assumptions

- Backend at `/teacher/timeline/` honors `q=<query>` as a fuzzy match against child names. The same path is reused for both a child-only list and a typed-section result depending on the call site; this is fragile (see features.md "search · B" P2 follow-ups).
- The parent-search surface (`isTeacher == false`) is reachable from somewhere — call-site grep finds only the teacher branch wired into `AllChildrenScreen`. If parents flavor never reaches a `GlobalSearch(isTeacher: false)` dispatch, the parent endpoint is currently dead.
- The Debouncer behavior would slot into `SearchField.onSearch`. If the design wants live results instead of submit-only, the screen also needs an `onChanged` hook.
