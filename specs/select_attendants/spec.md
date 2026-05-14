---
status: migrated
feature: select_attendants
flavor_scope: both
migrated_from: specs/features.md#select_attendants--b
migrated_date: 2026-05-14
---

# Feature Specification: Select Attendants

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated (placeholder — feature is stubbed in code)

**Input**: Reverse-engineered from [lib/features/select_attendants/](../../lib/features/select_attendants/) and [features.md `## select_attendants · B`](../features.md#select_attendants--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores). Parents picking which of their own children will attend an event; teachers picking children from their class roster (typically with a "select all in class" shortcut — *not yet implemented*).
- **Flavor-conditional behavior**: planned — teachers should see "select all in class" and a class-roster source; parents see only their enrolled children. *Not implemented today.*
- **Server role implication**: none yet — the screen is a placeholder. When implemented, the children list will come from the appropriate role-aware endpoint (parents: `/children`, teachers: class roster), already centralized in [home_repo.dart](../../lib/features/home/data_sources/home_repo.dart).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Choose attending children for an event (Priority: P1) MVP

A user on the events / RSVP flow needs to mark which children are attending a school event or filling out a consent form.

**Why this priority**: The feature is referenced by name in the events / forms flows ([features.md attendants_selection · B](../features.md#attendants_selection--b) — the related "attendants" picker) and is part of the `add_form` engine's `AttendantsSelection` field type ([features.md add_form](../features.md#add_form--b)). Without it, parents cannot complete RSVP / consent flows that involve multiple children.

**Independent Test** (target behavior — *not yet implemented*):

1. Open an event detail or a consent form that includes an "attendants" field.
2. Tap the field; this screen presents a list of the user's children (parent) or class roster (teacher).
3. Toggle selection per child.
4. Confirm; the selection rides back to the caller via `Navigator.pop(context, selectedIds)`.

**Acceptance Scenarios** (target — pending implementation):

1. **Given** a parent with three children, **When** they open the screen from an RSVP form, **Then** all three children render as toggleable rows.
2. **Given** the parent toggles two children and taps confirm, **When** the screen pops, **Then** the caller receives `[childId1, childId2]`.
3. **Given** a teacher on a class roster, **When** they tap "select all in class", **Then** every child in the class is selected. *Not yet implemented — [features.md task](../features.md#select_attendants--b).*

---

### Edge Cases

- **The screen is currently a `Placeholder` widget** ([select_attendants_screen.dart](../../lib/features/select_attendants/select_attendants_screen.dart)). The feature exists in name only. The real picker today lives in [attendants_selection/](../../lib/features/attendants_selection/) (which is also stubbed in a different shape) — naming overlap between the two is a known confusion. See the **Naming overlap with `attendants_selection`** note below.
- **No data source, no bloc, no models** in this feature. Whatever fills the placeholder in the future will need to use the standard `Either<Failure, List<ChildDetailsModel>>` shape via `NetworkClient.handleRequest`.
- **Caller contract is unspecified**: it's unclear which event/form path is supposed to push this screen vs. push `AttendantsSelectionScreen`. *Gap-1.*

### Naming overlap with `attendants_selection`

The repo has **two** features whose names imply the same intent:

- [`lib/features/select_attendants/`](../../lib/features/select_attendants/) — this feature; `Placeholder()`.
- [`lib/features/attendants_selection/`](../../lib/features/attendants_selection/) — see [attendants_selection/spec.md](../attendants_selection/spec.md); a working `AttendantsSelectionScreen` that reuses `DiaryBloc` + `SearchBloc` to render the class/child list.

Neither is currently referenced from a real call site in the codebase (grep `SelectAttendantsScreen` / `AttendantsSelectionScreen` returns only the class definitions themselves). The naming overlap should be resolved before either is fleshed out further — see [tasks.md T-fix-1](tasks.md).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow a user to select one or more children for an event / form / RSVP context. *Not yet implemented.*
- **FR-002**: System MUST return the selection to the caller via `Navigator.pop(context, List<int> childIds)` (or equivalent). *Not yet implemented.*
- **FR-003**: For teachers, System MUST surface a "select all in class" shortcut. *Per [features.md task](../features.md#select_attendants--b) — not yet implemented.*
- **FR-004**: System MUST source the children list from the role-appropriate endpoint (parents → own children; teachers → class roster). Use the existing helpers in [home_repo.dart](../../lib/features/home/data_sources/home_repo.dart) / [core/user/current_role.dart](../../lib/core/user/current_role.dart) to switch roles without `mainKey.currentContext`.
- **FR-005**: System MUST localize every label through `LocalizationKeys`. The key `select_attendants` already exists at [localization_keys.dart:199](../../lib/core/localization/localization_keys.dart#L199).
- **FR-006**: System MUST distinguish "already invited" vs "available" (this requirement lives in [attendants_selection spec FR](../attendants_selection/spec.md#functional-requirements); a single picker should cover both screens after the naming consolidation).

### Localization Requirements

| Key | Use site |
|---|---|
| `select_attendants` | screen title (planned) |

No new keys required by this migration. Additional keys will be needed when the feature is implemented (e.g., `select_all_in_class`, `no_children_available`).

### Backend Touchpoints

- **REST**: planned — `GET /children` (parents) or `GET /teacher/class/{id}/children` (teachers). Specific endpoints to be confirmed when the feature is wired.
- **Firestore**: none.
- **FCM**: none.

### Permissions & Approval Gate

- Requires `isApproval == true`. The screen would only be reachable from inside authenticated flows (events / forms).
- No device permissions required.

### Key Entities

- **`ChildDetailsModel`** ([lib/core/models/](../../lib/core/models/)) — the entity rendered in each row.
- **Selection result** — `List<int>` of child IDs returned to the caller. Shape to be confirmed when implemented.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent can complete an RSVP for two children in one pass (no per-child re-entry into the form).
- **SC-002**: A teacher can bulk-select an entire class with one tap.
- **SC-003**: The selection round-trips back to the caller without data loss on Android back-press.

## Assumptions

- The feature is **paused / pending design**. Today's `Placeholder()` is intentional scaffolding waiting for a clear caller contract.
- The intended caller is the events/forms flow (`add_form` engine's `AttendantsSelection` field type) — not yet confirmed by reading the form-renderer code.
- The naming collision with `attendants_selection` will be resolved in favor of **one** picker covering both use cases (event attendants and form-field attendants). The redundant feature directory should be deleted once decided.
