---
status: migrated
feature: settings/my_children
flavor_scope: parents
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: My Children

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/my_children/](../../../lib/features/settings/my_children/) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: **parents only**. The row that pushes `MyChildrenScreen` is gated by `if (context.isParents)` in [settings_screen.dart:108-120](../../../lib/features/settings/settings_screen.dart#L108-L120).
- **Flavor-conditional behavior**: N/A — no teacher rendering.
- **Server role implication**: hits `GET /parent/children` ([my_children_repo.dart:8](../../../lib/features/settings/my_children/repo/my_children_repo.dart#L8)). Teacher equivalent is `lib/features/all_children/`, not this feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse my enrolled children (Priority: P1) 🎯 MVP

A parent opens "My children" from Settings, sees a paginated list of children attached to their account, and can tap any child to open the diary view for that child.

**Why this priority**: This is the parents' canonical roster screen. Acts as an entry point into the per-child diary.

**Independent Test**:
1. From Settings (parents flavor), tap `my_children`.
2. `FetchMyChildren(1)` fires → list of `ChildModel` renders.
3. Tap any child → `DiaryScreen(child: child)` pushes.

**Acceptance Scenarios**:

1. **Given** a parent with N enrolled children, **When** the screen mounts, **Then** `FetchMyChildren(1)` fires and the `PaginationController` adds the returned page.
2. **Given** zero children, **When** the response is empty, **Then** an `EmptyWidget` with `no_children` localization key + the child icon renders.
3. **Given** a parent taps a child row, **When** `ChildItem.onTap` fires, **Then** the app pushes `DiaryScreen(child: child)`.
4. **Given** the repo returns a `Failure`, **When** `childrenState.error` is non-null, **Then** the `PaginationWidget` renders an error message from `state.childrenState.error.message`.
5. **Given** an avatar URL is present, **When** the `ChildItem` renders, **Then** it shows `child.avatar` + `child.name` + `child.classRoom` (subtitle).

### Edge Cases

- **Pagination boundary**: `MyChildrenRepo.getChildren(page)` ignores `page` server-side today (no `?page=` query param in [my_children_repo.dart:15-18](../../../lib/features/settings/my_children/repo/my_children_repo.dart#L15-L18) — the local `page` argument is silently dropped). The `PaginationController` thinks it's adding pages but the server returns the same payload. Bug — see [tasks.md T-fix-2](tasks.md).
- **No "remove child from account"** path — flagged P2 in [features.md#settings--b](../../features.md#settings--b) as a feature gap (with a confirmation modal).
- **`SubmitMyChildrenEvent`** is declared but never dispatched — dead event.
- **`ChildrenState.select(AreaModel)`** returns a clone with the same `data` (no mutation) — vestigial; never called.
- **Approval gate**: reached only via Settings → MainScreen, so implicit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display the parent's enrolled children list via `GET /parent/children`.
- **FR-002**: System MUST render each child row using `ChildItem` showing the avatar, name, and class.
- **FR-003**: System MUST navigate to `DiaryScreen(child: child)` when a child row is tapped.
- **FR-004**: System MUST show an `EmptyWidget` with `no_children` localization when the list is empty.
- **FR-005**: System MUST be gated behind `context.isParents` at the Settings shell row level.

### Localization Requirements

| Key | Use site |
|---|---|
| `my_children` | screen title + Settings row title |
| `no_children` | empty-state widget |

No new keys required.

### Backend Touchpoints

- **REST endpoints**:
  - `GET /parent/children` — returns `{data: {childs: [ChildModel]}}` (`childs` typo preserved by backend).
- **Headers**: standard via [NetworkInterceptor](../../../lib/core/network/network_interceptor.dart).
- **Firebase**: not used.
- **Firestore**: not used.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit).
- No device permissions.

### Key Entities

- **`ChildModel`** ([lib/features/diary/models/child_model.dart](../../../lib/features/diary/models/child_model.dart)) — shared cross-feature child entity (id, name, avatar, classRoom).
- **`MyChildrenStates`** / **`ChildrenState`** — bloc state container with `data`, `loading`, `error`.
- **`MyChildrenModel`** ([my_children_model.dart](../../../lib/features/settings/my_children/models/my_children_model.dart)) — declared in `models/`. **[NEEDS CLARIFICATION]** the screen actually uses `ChildModel`; `MyChildrenModel` may be vestigial.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent sees their children list within 1 round-trip after opening the screen (≤ 2s on a typical mobile network).
- **SC-002**: Empty state renders without crash when the parent has no enrolled children.
- **SC-003**: Tapping a child consistently lands on the right `DiaryScreen` (per `ChildModel.id`).

## Assumptions

- The same `MyChildrenRepo` is used by the **AddForm engine** (`add_form_repo.dart` constructor receives a `MyChildrenRepo`) to populate the children dropdown — keep the public contract stable.
- `ChildModel` is the right shared type; `MyChildrenModel` is **[NEEDS CLARIFICATION]**.
- Server returns the full roster on page 1 (no pagination today).
