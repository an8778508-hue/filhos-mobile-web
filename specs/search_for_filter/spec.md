---
status: migrated
feature: search_for_filter
flavor_scope: both
migrated_from: specs/features.md#search_for_filter--b
migrated_date: 2026-05-14
---

# Feature Specification: Search-for-Filter

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/search_for_filter/](../../lib/features/search_for_filter/) and the existing [features.md `## search_for_filter · B`](../features.md#search_for_filter--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**:
  - The screen passes `isTeacher: context.isProfessors` to `SubmitSearchForFilter` ([search_for_filter_screen.dart:76](../../lib/features/search_for_filter/search_for_filter_screen.dart#L76)), and the bloc forwards it to `SearchRepo.globalSearchForProfessor(query, isTeacher)`. Same endpoint selection rules as the [search](../search/spec.md) feature.
  - Output filtering by `SearchForFilterModelType` is flavor-agnostic — it depends on which `searchModelType` the caller passes.
- **Server role implication**: None — auth token still defines role on the wire; `isTeacher` is a UX selector.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pick a teacher / child-or-parent / level from a filter sheet (Priority: P1) 🎯 MVP

A caller (today: `FilterSheet` in [filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart)) opens `SearchForFilterScreen(searchModelType: ...)`. The user types, picks one row, the screen pops back with the selected `SchoolItem`.

**Why this priority**: This is the only purpose of the feature — it is a reusable picker component used by other features' filter UIs.

**Independent Test**:
1. From any caller, push `SearchForFilterScreen(searchModelType: SearchForFilterModelType.teacher)` using `Navigator.push`.
2. Type a teacher's name and submit.
3. Tap a result.
4. Verify the awaited `Navigator.push` returns the tapped `SchoolItem` ([search_for_filter_screen.dart:97](../../lib/features/search_for_filter/search_for_filter_screen.dart#L97): `Navigator.of(context).pop(searchModel);`).

**Acceptance Scenarios**:

1. **Given** caller passes `SearchForFilterModelType.teacher`, **When** results return, **Then** only `result.teachers` rows are shown ([search_for_filter_screen.dart:126-127](../../lib/features/search_for_filter/search_for_filter_screen.dart#L126-L127)).
2. **Given** caller passes `SearchForFilterModelType.childOrParent`, **When** results return, **Then** rows are `[...parents, ...children]` merged ([search_for_filter_screen.dart:122-123](../../lib/features/search_for_filter/search_for_filter_screen.dart#L122-L123)).
3. **Given** caller passes `SearchForFilterModelType.level`, **When** results return, **Then** only `result.levels` rows are shown ([search_for_filter_screen.dart:128-129](../../lib/features/search_for_filter/search_for_filter_screen.dart#L128-L129)).
4. **Given** caller passes `SearchForFilterModelType.classType`, **When** results return, **Then** the filtered list is **always empty** ([search_for_filter_screen.dart:124-125](../../lib/features/search_for_filter/search_for_filter_screen.dart#L124-L125)) — `[NEEDS CLARIFICATION]` whether classType filtering was deferred or intentionally unused.
5. **Given** the request fails, **When** `SearchForFilterItemsError(failure)` is emitted, **Then** today the screen renders nothing meaningful — falls through to the `EmptySearchResult` branch. **Gap**: no `ErrorScreen` retry surface (unlike the sibling `SearchScreen`).
6. **Given** the user taps "clear", **When** `ClearSearchForFilter` is dispatched, **Then** the in-memory `searchForFilterItems` becomes null and the empty-state widget is shown again.

---

### User Story 2 - Reusable component API (Priority: P1)

Other features push `SearchForFilterScreen` as a `MaterialPageRoute` and `await` the result. The contract is the **inputs** and **the model returned via pop**.

**Why this priority**: This feature is shipped as a reusable picker. Stabilizing the API contract is the whole point of migrating it.

**Inputs** ([search_for_filter_screen.dart:21-24](../../lib/features/search_for_filter/search_for_filter_screen.dart#L21-L24)):

| Input | Type | Required | Use |
|---|---|---|---|
| `searchModelType` | `SearchForFilterModelType` (one of `childOrParent`, `classType`, `teacher`, `level`) | yes | Selects which sub-list of `GlobalSearchResult` to show. |
| `hasInitial` | `bool` (default `false`) | no | When `true`, dispatches `GetSearchForFilterItems(searchModelType)` on bloc creation. **Note**: the handler is fully commented out ([search_for_filter_bloc.dart:20-21](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart#L20-L21)) so `hasInitial: true` is a no-op today. |

**Output** (via `Navigator.pop`): the chosen `SchoolItem` (sourced from `lib/features/diary/models/school_item.dart`) — **not** the local `SearchForFilterModel` ([model file](../../lib/features/search_for_filter/model/search_for_filter_model.dart)), which is also defined in this feature but unused at runtime.

**Acceptance Scenarios**:

1. **Given** caller invokes `await Navigator.push(... => SearchForFilterScreen(searchModelType: SearchForFilterModelType.teacher))`, **When** user picks a row, **Then** the awaited future resolves to a `SchoolItem` whose `name` is shown in the caller's text field (see [filter_sheet.dart:91-99](../../lib/core/components/sheets/filter_sheet.dart#L91-L99)).
2. **Given** caller invokes the same with `hasInitial: true`, **When** the screen mounts, **Then** **no preload happens** because the handler is commented out — known no-op.

---

### User Story 3 - Empty / cleared state (Priority: P2)

When the user hasn't searched yet (or has just cleared), the screen renders `EmptySearchResult`.

**Acceptance Scenarios**:

1. **Given** the bloc state is `SearchForFilterInitial`, **When** the screen builds, **Then** `searchForFilterItems == null` → `searchItems` resolves to `[]` → `EmptySearchResult` is rendered.

---

### Edge Cases

- **`classType` is silently empty**: filtering always returns `[]` ([search_for_filter_screen.dart:124-125](../../lib/features/search_for_filter/search_for_filter_screen.dart#L124-L125)). Callers that pass `classType` get a screen that can never show results. None of the three known callers in [filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart) pass `classType` today.
- **`hasInitial: true` is a no-op**: the `GetSearchForFilterItems` handler in the bloc is commented out. Pushing the screen with `hasInitial: true` (no callers do this today) wastes a bloc creation and shows the empty state until the user types.
- **No error UI**: `SearchForFilterItemsError(failure)` falls through the `if (state is SearchForFilterItemsLoading) ... else ...` chain into the empty-state path ([search_for_filter_screen.dart:87-101](../../lib/features/search_for_filter/search_for_filter_screen.dart#L87-L101)) → user sees "no results" on a failed request.
- **Two `SearchForFilterModel` definitions**: the feature ships [model/search_for_filter_model.dart](../../lib/features/search_for_filter/model/search_for_filter_model.dart) with its own `SearchForFilterModel` + `SearchForFilterModelType`, but the runtime row type is the shared `SchoolItem`. The model file's `SearchForFilterModel` class is **unused at runtime** — only the enum `SearchForFilterModelType` is referenced.
- **No DI registration in `SearchForFilterInjection`**: the bloc is registered directly in [init_dependencies.dart:86](../../lib/init_dependencies.dart#L86) (`di.registerFactory<SearchForFilterBloc>(() => SearchForFilterBloc(di(), di()));`). No feature-root DI class. **Constitution drift** — every other feature owns its own `*Injection` class.
- **`localDatabaseRepo` injected but unused**: the bloc takes a `LocalDatabaseRepo` in its constructor ([search_for_filter_bloc.dart:18](../../lib/features/search_for_filter/bloc/search_for_filter_bloc.dart#L18)) and never reads from or writes to it.
- **No `tasks.md`-recommended "persist last-used filters"**: features.md asks for this; not implemented.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST accept `searchModelType` to select which segment of `GlobalSearchResult` is shown (`teacher`, `level`, `childOrParent`, `classType`).
- **FR-002**: System MUST return the chosen row via `Navigator.pop(schoolItem)` so callers can `await` the push.
- **FR-003**: System MUST gate query dispatch on a non-empty query via `stringNotNullOrEmpty`.
- **FR-004**: System MUST forward `isTeacher: context.isProfessors` to `SearchRepo.globalSearchForProfessor` so endpoint selection matches the current flavor.
- **FR-005**: System MUST support `ClearSearchForFilter` to reset the in-memory result and clear the input.
- **FR-006** (gap): System SHOULD surface `SearchForFilterItemsError` to the user with a retry, parity with `SearchScreen`'s `ErrorScreen`.
- **FR-007** (gap from features.md): System SHOULD persist last-used filters per `searchModelType` so reopening the picker pre-populates the last selection.
- **FR-008** (gap): System SHOULD either remove the `classType` branch or wire it to a server endpoint that returns class rows.

### Localization Requirements

| Key | Use site |
|---|---|
| `search` | App bar title + `SearchField` hint |

No new keys required.

### Backend Touchpoints

- Same endpoints as [search](../search/spec.md):
  - `GET teacher/timeline/?q=<query>` (when `isTeacher == true`).
  - `GET parent/timeline?q=<query>` (when `isTeacher == false`).
- No Firebase / Firestore.

### Permissions & Approval Gate

- Post-login screen reachable only through other authenticated features' filter sheets. Approval gate is enforced upstream.
- No device permissions.

### Key Entities

- **`SearchForFilterModelType`** ([search_for_filter_model.dart:30](../../lib/features/search_for_filter/model/search_for_filter_model.dart#L30)) — enum: `childOrParent | classType | teacher | level`. This is the only piece of the model file used at runtime.
- **`SchoolItem`** (shared) — the actual row type returned to callers.
- **`GlobalSearchResult`** (shared from [features/search/models/global_search.dart](../../lib/features/search/models/global_search.dart)) — bloc's in-memory result holder.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Any caller can `await` `SearchForFilterScreen` and receive a `SchoolItem?` back deterministically (null on back/cancel, the row on tap).
- **SC-002**: Switching `searchModelType` between calls yields the right segment of results without any extra plumbing on the caller side.
- **SC-003**: A failed search surfaces an error UI instead of "no results" (FR-006).

## Assumptions

- The three callers in [filter_sheet.dart](../../lib/core/components/sheets/filter_sheet.dart) (teacher / childOrParent / level pickers) cover the live usage. No grep finds any caller passing `classType`.
- Backend response shape matches what `SearchRepo.globalSearchForProfessor` already parses — this feature does no parsing of its own.
- The bloc's `LocalDatabaseRepo` dependency is forward-compat for FR-007 (persisted last-used filters) and not currently exercised.
