---
status: migrated
feature: all_children
flavor_scope: professores
migrated_from: specs/features.md#all_children--p
migrated_date: 2026-05-14
---

# Feature Specification: All Children

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/all_children/](../../lib/features/all_children/) and the existing [features.md `## all_children · P`](../features.md#all_children--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: **professores** at the *entry point* — features.md tags this `· P` ("parents") but the only navigation site is gated `if (context.isProfessors)` ([settings_screen.dart:134-143](../../lib/features/settings/settings_screen.dart#L134-L143)). The data-source endpoint also confirms a teacher-side bias: `GET teacher/questions/data` ([all_children_dc.dart:8](../../lib/features/all_children/data_source/all_children_dc.dart#L8)).
- **Discrepancy with features.md**: features.md says "List of children linked to the parent account" but the implementation is **teacher-facing** — it lists all children the teacher has access to. **Decision**: trust the code; treat this as a teacher-flavor feature. Carry the discrepancy as a feature-doc fix.
- **Flavor-conditional behavior**: Search input dispatches `GlobalSearch(query, isTeacher: context.isProfessors)`. On the teachers flavor this fires the teacher branch of [search](../search/spec.md)'s endpoint selector. The screen will render even if reached from the parents flavor (no internal guard), but the search endpoint and the bootstrap endpoint are teacher-named.
- **Server role implication**: Auth token determines what `teacher/questions/data` returns.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Teacher views all children (Priority: P1) 🎯 MVP

A teacher taps "All children" in settings; the screen lists every child they have access to as a tappable row.

**Why this priority**: This is the primary value of the screen for the teachers flavor.

**Independent Test**:
1. Launch professores flavor, open settings, tap "All children".
2. Verify the `AllChildrenBloc` is created and `GetAllChildren` is dispatched on mount ([all_children_screen.dart:50](../../lib/features/all_children/presentation/all_children_screen.dart#L50)).
3. Verify `GET teacher/questions/data` is called.
4. Verify each row in `data.children` becomes a `SchoolItem(childType)` in `SchoolItemsList`.
5. Tap a row → `ChildDetailsSheet.openSheet(...)` opens with a `ChildDetailsModel` constructed from the `SchoolItem` ([all_children_screen.dart:116-117, 146-159](../../lib/features/all_children/presentation/all_children_screen.dart#L116-L117)).

**Acceptance Scenarios**:

1. **Given** the user opens the screen, **When** the bloc is created, **Then** `GetAllChildren()` is added and `AllChildrenLoading` is emitted while the request is in flight.
2. **Given** the response succeeds, **When** `AllChildrenSucceed(items)` is emitted, **Then** `SchoolItemsList` renders one tile per child.
3. **Given** the response fails, **When** `AllChildrenFailed(failure)` is emitted, **Then** the **bloc state itself is currently not surfaced** — the screen only renders an error if the *embedded* `SearchBloc` is in `SearchFailed`. `AllChildrenFailed` falls through to a blank-list view. **Gap.**

---

### User Story 2 - Filter via in-page search (Priority: P1)

The same screen embeds a `SearchBloc` (independent of the `AllChildrenBloc`). Typing in the search field dispatches `GlobalSearch(query, isTeacher: context.isProfessors)`. While search results are present, the screen prefers them over the bootstrapped list.

**Why this priority**: Lets a teacher narrow the on-screen list without leaving the screen.

**Acceptance Scenarios**:

1. **Given** results from `GetAllChildren` are showing, **When** the user types a non-empty query and submits, **Then** `SearchBloc` emits `SearchLoading` → `SearchSucceed` and the screen switches from `items` to `searchItems` (merged `children + parents`) ([all_children_screen.dart:63-69, 97-117](../../lib/features/all_children/presentation/all_children_screen.dart#L63-L69)).
2. **Given** search results are showing, **When** the user clears, **Then** `ClearSearch` resets the search bloc and the screen falls back to the bootstrapped `items` list.
3. **Given** the search request fails, **When** `SearchFailed` is emitted, **Then** an `ErrorScreen` with retry is rendered ([all_children_screen.dart:118-129](../../lib/features/all_children/presentation/all_children_screen.dart#L118-L129)).
4. **Given** the search returns zero rows, **When** `SearchSucceed` lands with empty merged result, **Then** `EmptySearchResult` is shown ([all_children_screen.dart:97-103](../../lib/features/all_children/presentation/all_children_screen.dart#L97-L103)).

---

### User Story 3 - Open a child's details (Priority: P2)

Tapping a row opens `ChildDetailsSheet` with a synthetic `ChildDetailsModel`.

**Acceptance Scenarios**:

1. **Given** a child row is tapped, **When** the screen calls `getDetailsFromSchoolItem(item)`, **Then** a `ChildDetailsModel` is constructed using `item.id`, `item.name`, `item.classRoom` (as `grade`), `item.avatar`, and `item.parent` (as both `responsible` and `enroll_parent`). Other fields (`age`, `gender`, `birthday`, `series`) are filled with stubs (`item.id.toString()` for `age` and `code`; `null` for `gender`, `birthday`, `series`) — see [all_children_screen.dart:146-159](../../lib/features/all_children/presentation/all_children_screen.dart#L146-L159). **The mapping loses real data**; the sheet displays placeholders.

---

### Edge Cases

- **`AllChildrenFailed` is invisible**: the screen only branches on `searchState`. A failed bootstrap fetch leaves the screen blank with no error UI.
- **No pull-to-refresh**: features tasks for parents-side flows usually include it; not present here.
- **Synthetic `ChildDetailsModel` mapping** loses real `age`/`gender`/`birthday`/`series`; the sheet relies on what the backend embeds in `SchoolItem`. **Gap.**
- **`showAllChildren: false && !validList(items)`** — the `false &&` short-circuits the entire expression to `false`. The flag exists but is permanently off ([all_children_screen.dart:106, 113](../../lib/features/all_children/presentation/all_children_screen.dart#L106)). Suggests an in-progress experiment.
- **`hasNotification: true, hasAvatar: false`** on the app bar — slightly unusual mix; check that the notification bell badge is genuinely needed on this surface ([all_children_screen.dart:43-46](../../lib/features/all_children/presentation/all_children_screen.dart#L43-L46)).
- **`SchoolItem.parent`** is used as both `responsible` and `enroll_parent` on the synthetic `ChildDetailsModel` — collapses two distinct parent relationships into one field.
- **Search input does not debounce** (same drift as the standalone `SearchScreen`).
- **Enrollment status badge** not surfaced — features.md asks for it. The model `SchoolItem` does not carry an enrollment field.
- **Re-ordering** not supported — features.md asks for it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the bootstrap list from `GET teacher/questions/data` and parse `data.children` into `List<SchoolItem>` (childType) ([all_children_dc.dart:18-32](../../lib/features/all_children/data_source/all_children_dc.dart#L18-L32)).
- **FR-002**: System MUST render each row via `SchoolItemsList` (shared with `diary`).
- **FR-003**: System MUST embed a `SearchBloc` and dispatch `GlobalSearch(query, isTeacher: context.isProfessors)` on non-empty submission.
- **FR-004**: System MUST prefer search results over the bootstrapped list whenever any of `children` / `parents` from `globalSearchResult` are non-null.
- **FR-005**: System MUST render `EmptySearchResult` on zero-row search, `ErrorScreen` on `SearchFailed` with working retry, and `Loading` while either bloc is loading.
- **FR-006**: System MUST construct a `ChildDetailsModel` from a tapped `SchoolItem` and open `ChildDetailsSheet`.
- **FR-007** (gap): System SHOULD surface `AllChildrenFailed` to the user (today it is silent).
- **FR-008** (gap from features.md): System SHOULD show an enrollment status badge per child (requires backend support — `SchoolItem` lacks the field).
- **FR-009** (gap from features.md): System SHOULD allow re-ordering for accounts with many children.
- **FR-010** (gap): Search SHOULD be debounced via [core/utils/debouncer.dart](../../lib/core/utils/debouncer.dart).

### Localization Requirements

| Key | Use site |
|---|---|
| `all_children` | App bar title |
| `search_by_child_name` | Search field hint |

No new keys required.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET teacher/questions/data` — bootstrap. Response shape: `{data: {children: [...], …}}`. The repo reads only `data.children`.
  - `GET teacher/timeline/?q=<query>` — search (via `SearchBloc` → `SearchRepo.globalSearchForProfessor(isTeacher: true)`).
- **Headers**: standard via `NetworkInterceptor`.
- **Firebase / Firestore**: not used.

### Permissions & Approval Gate

- Reachable from settings post-login; approval gate enforced upstream.
- No device permissions.

### Key Entities

- **`SchoolItem`** (shared) — the row type.
- **`AllChildrenState`** sealed union: `Initial`, `Loading`, `Succeed(items)`, `Failed(failure)`.
- **`ChildDetailsModel`** (shared from [core/models/child_details_model.dart](../../lib/core/models/child_details_model.dart)) — output of `getDetailsFromSchoolItem`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A teacher sees their full child list within 1.5 s of opening the screen on a warm network.
- **SC-002**: Tapping any row opens `ChildDetailsSheet` within 100 ms (no network).
- **SC-003**: An empty search submission renders the bootstrapped list; a non-empty submission renders the search result without removing it on error.
- **SC-004**: With FR-007 implemented, a `teacher/questions/data` failure surfaces an `ErrorScreen` with retry.

## Assumptions

- The `teacher/questions/data` endpoint returns the children the calling teacher has access to (server-side filter by token).
- `SchoolItem` from the bootstrap response carries enough fields for `SchoolItemsList` (avatar, name, classRoom) and for the `ChildDetailsSheet` synthesis (parent, classRoom). Anything else displayed on the sheet must be backfilled by the sheet via a separate call (out of scope here).
- Per features.md the feature was *intended* to be parents-side; the code shipped is teacher-side. Treat the discrepancy as a doc fix, not a feature rewrite — unless the product team confirms otherwise.
