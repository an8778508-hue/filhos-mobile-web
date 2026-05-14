---
status: migrated
feature: settings/medicines
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: Medicines

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/medicines/](../../../lib/features/settings/medicines/) (parents side) + [lib/features/settings/medicines_professors/](../../../lib/features/settings/medicines_professors/) (teachers side) + [lib/features/add_medicine/](../../../lib/features/add_medicine/) (shared add-form) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both, with **different screens per flavor** dispatched from the Settings shell ([settings_screen.dart:158-178](../../../lib/features/settings/settings_screen.dart#L158-L178)):
  - **Parents** → `MedicinesScreen` (a flat list per child of registered medicines; can edit / delete / add).
  - **Teachers** → `MedicinesProfessorsScreen` (3-tab `TabBarView`: **Reminders** / **Requests** / **History**).
- **Flavor-conditional behavior**: structurally two independent feature modules sharing the same `MedicineModel` / `MedicineBodyModel` data classes plus the `AddMedicineScreen` form (built on `AddFormType.medicine`).
- **Server role implication**: endpoints diverge:
  - Parents → `/parent/medicines` (GET / DELETE).
  - Teachers → `teacher/medicines/requests`, `teacher/medicines/requests/{id}` (accept/reject), `teacher/medicines/reminders`, `teacher/medicines/reminders/{id}`, `/teacher/medicines/children/medicines-history`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Parent: register, view, edit and delete medicines (Priority: P1) 🎯 MVP

A parent opens "Medicines" from Settings, sees a list grouped by child, taps **Add medicine** to register a new one via `AddMedicineScreen`, edits or deletes existing entries inline.

**Why this priority**: Parents must be able to register medications so teachers can see what to administer.

**Independent Test**:
1. From parents Settings → `medicines`.
2. `FetchMedicines` fires → groups render per child with `MedicineHeaderWidget` + `MedicineBody`.
3. Tap **Add medicine** → `AddMedicineScreen(type: AddFormType.medicine)` opens; complete the form; pop with `true`.
4. Confirm `FetchMedicines` re-runs and the new entry appears.
5. Tap delete → confirm dialog → `DeleteMedicine(id)` fires; entry disappears.

**Acceptance Scenarios**:

1. **Given** a parent with no medicines, **When** the list returns empty, **Then** `EmptyMedicine` widget renders.
2. **Given** a parent has 2 children with medicines, **When** the list returns, **Then** each child's medicines are grouped under a `MedicineHeaderWidget`.
3. **Given** the user taps Edit on a medicine, **When** the editor pops with `true`, **Then** `FetchMedicines` reruns.
4. **Given** the user confirms a deletion, **When** `DeleteMedicine(id)` succeeds, **Then** a success `Snack.show` appears and the list is refetched ([medicines_bloc.dart:22-33](../../../lib/features/settings/medicines/bloc/medicines_bloc.dart#L22-L33)).
5. **Given** the delete fails with a message, **When** `state.deleteState.failure` populates, **Then** a failure `Snack.show` appears with the message.

### User Story 2 - Teacher: review medicine requests (Priority: P1)

A teacher opens "Medicines" from Settings, sees three tabs (Reminders / Requests / History). Under Requests they can approve or reject a medicine submitted by a parent.

**Why this priority**: Teachers gate-keep what's actually administered.

**Acceptance Scenarios**:

1. **Given** a teacher opens the screen, **When** the Reminders tab mounts, **Then** `loadReminders()` calls `GET /teacher/medicines/reminders` and renders `MedicinePrescriptionModel` items grouped by child.
2. **Given** a teacher taps an item in Reminders, **When** `MedPresBloc.check(item)` succeeds, **Then** Reminders + History reload (with a 1.5s delay on Reminders) and the local alarm for `item.id` is removed via `AlarmManager.removeAlarm`.
3. **Given** Requests tab is selected, **When** mount, **Then** `loadRequests()` calls `GET teacher/medicines/requests` after first fetching the medicine `AddFormFormModel` so payloads can be denormalized to human-readable strings ([medicine_professors_impl.dart:35-133](../../../lib/features/settings/medicines_professors/data_source/medicine_professors_impl.dart#L35-L133)).
4. **Given** a teacher taps Approve on a request, **When** `acceptRequest(id)` runs, **Then** `POST teacher/medicines/requests/{id}` with body `{medicine_id, status: 'approved'}` fires.
5. **Given** a teacher rejects with a reason, **When** `rejectRequest(id, reason, attachments)` runs, **Then** `POST teacher/medicines/requests/{id}` with `queryParameters` `{medicine_id, status: 'declined', reason}` fires. ⚠️ Attachments parameter is accepted but **not sent** — see [tasks.md T-fix-2](tasks.md).
6. **Given** History tab is selected, **When** mount, **Then** `loadHistory()` calls `GET /teacher/medicines/children/medicines-history` and renders prescription items.

### User Story 3 - Local medicine alarms (Priority: P1)

When a medicine is registered, the parent's device schedules a local alarm that fires at the dosage time.

**Why this priority**: Reminders are the parents-side trigger that lets them administer the medicine at home.

**Acceptance Scenarios**:

1. **Given** a parent saves a new medicine via `AddMedicineScreen`, **When** the save succeeds, **Then** the `AlarmManager` (native wrapper in [lib/core/custom_packages/](../../../lib/core/custom_packages/)) schedules a local alarm for each dosage time. *(Reminders implementation lives in `add_medicine` / `AlarmManager`; this feature only triggers a re-fetch on return.)*
2. **Given** the teacher tab marks a reminder as administered, **When** `MedPresBloc.check` succeeds, **Then** the parent-side alarm with that id is removed via `AlarmManager.removeAlarm(id: item.id)`.

### Edge Cases

- **Pagination off**: `MedicinesScreen` calls `Pagination` widget but the `onLoadMore` callback is a no-op ([medicine_screen.dart:80-83](../../../lib/features/settings/medicines/medicine_screen.dart#L80-L83)). The list is effectively single-page despite the wrapper. Bug-or-by-design.
- **Empty `medicines` array per child** is filtered with a `SizedBox()` short-circuit ([medicine_screen.dart:98-100](../../../lib/features/settings/medicines/medicine_screen.dart#L98-L100)) — children without active medicines render nothing (correct).
- **Empty-state CTA missing**: when the list is empty, `EmptyMedicine` renders but there is **no** "Add medicine" button — the Add button is inside the `if (medicines.isNotEmpty)` branch ([medicine_screen.dart:168-183](../../../lib/features/settings/medicines/medicine_screen.dart#L168-L183)). A first-time user has no way to add. Bug — see [tasks.md T-fix-3](tasks.md).
- **`medicines/repo/medicines_repo.dart`** contains 100+ lines of commented-out payload-denormalization code, now performed by the teachers-side repo only.
- **`MedicinesProfessorsImpl._basicErrorHandling`** is a dead extension at the bottom of the file — never called.
- **Reject-request `queryParameters` for `reason` + `attachments`** drops attachments and uses query parameters for what should be a multipart body. Bug — see [tasks.md T-fix-2](tasks.md).
- **`add_medicine` shared logic**: parents-side `AddMedicineScreen` is built on `AddFormType.medicine` and `AddMedicineRepo` (depends on `MyChildrenRepo`). Teachers do not use this — they read parent submissions via the request flow.
- **Approval gate**: implicit (downstream of Settings → MainScreen).
- **`medicines_professors` uses `Cubit`, not `Bloc`** — differs from parents-side and other settings sub-features. Acceptable.

## Requirements *(mandatory)*

### Functional Requirements

**Parents-side (`medicines/`):**

- **FR-P1**: System MUST list `MedicineModel` entries via `GET /parent/medicines` grouped per child.
- **FR-P2**: System MUST allow editing an entry by pushing `AddMedicineScreen` with the entry's `id`, `MedicineModel`, and `MedicineBodyModel`.
- **FR-P3**: System MUST allow deletion via `DELETE /parent/medicines/{id}` after a `confirmDialog`.
- **FR-P4**: System MUST surface success / failure via `Snack.show`.
- **FR-P5**: System MUST refetch the list after add / edit / delete.

**Teachers-side (`medicines_professors/`):**

- **FR-T1**: System MUST expose three tabs: Reminders, Requests, History.
- **FR-T2**: System MUST load each tab lazily on first display (`AutomaticKeepAliveClientMixin`).
- **FR-T3**: System MUST denormalize medicine `payload` entries by looking up `AddFormFormModel.values` to render human-readable strings (dropdown / multi-select / segmented / period-of-time fields).
- **FR-T4**: System MUST approve via `POST teacher/medicines/requests/{id}` body `{medicine_id, status: 'approved'}`.
- **FR-T5**: System MUST reject via `POST teacher/medicines/requests/{id}` with `{medicine_id, status: 'declined', reason}`. ⚠️ Attachments parameter accepted but not transmitted.
- **FR-T6**: System MUST mark a reminder read via `PUT /teacher/medicines/reminders/{id}` body `{read: 1, reminder_id: id}`.
- **FR-T7**: System MUST remove the local `AlarmManager` entry when the reminder is marked.

**Cross-cutting:**

- **FR-X1**: System MUST share `MedicineModel` / `MedicineBodyModel` between parents-side and teachers-side.
- **FR-X2**: System MUST trigger local alarms via `AlarmManager` for each registered medicine on the parent's device (handled in `add_medicine` + `AlarmManager`).

### Localization Requirements

| Key | Use site |
|---|---|
| `medicines` | screen title (both) |
| `reminders`, `requstes`, `history` | teacher tabs (⚠️ typo `requstes`) |
| `add_medicine` | parent CTA |
| `delete_medicine_title`, `delete_medicine_content` | parent delete confirm |
| `success_action` | success snack |
| `no_medicines` (via `EmptyMedicines`) | teacher empty state |

**[NEEDS CLARIFICATION]** confirm the `requstes` (sic) key is correct in `localization_keys.dart` or fix the typo.

### Backend Touchpoints

- **REST endpoints**:
  - Parents:
    - `GET /parent/medicines?page={n}` — list.
    - `DELETE /parent/medicines/{id}` — delete.
  - Teachers:
    - `GET teacher/medicines/requests?page={n}` — list pending requests.
    - `POST teacher/medicines/requests/{id}` `{medicine_id, status: 'approved'|'declined', reason?}` — accept/reject.
    - `GET teacher/medicines/reminders?page={n}` — list reminders.
    - `PUT /teacher/medicines/reminders/{id}` `{read: 1, reminder_id: id}` — mark read.
    - `GET /teacher/medicines/children/medicines-history?page={n}` — history.
- **Headers**: standard.
- **Firebase**: not used.
- **Firestore**: not used.
- **Local-only**: `AlarmManager` via `lib/core/custom_packages/` schedules / removes platform alarms.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit).
- Device permissions: notifications + alarm permissions (Android exact-alarm; iOS local notifications).

### Key Entities

- **`MedicineModel`** ([medicine_model.dart](../../../lib/features/settings/medicines/models/medicine_model.dart)) — `{child: UserModel?, medicines: List<MedicineBodyModel>, created_at}`.
- **`MedicineBodyModel`** ([medicine_body_model.dart](../../../lib/features/settings/medicines/models/medicine_body_model.dart)) — name, dose (`potion`), notes, image[], status.
- **`MedicinePrescriptionModel`** ([medicine_prescription_model.dart](../../../lib/features/settings/medicines_professors/models/medicine_prescription_model.dart)) — `{child: ChildModel, feed: List<PrescriptionModel>}` for teacher screens.
- **`AddFormFormModel`** (shared from `add_form/`) — the schema used to denormalize medicine payloads on the teacher side.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent can add → view → edit → delete a medicine in under 60 seconds without re-opening the screen.
- **SC-002**: A teacher's Approve / Reject on a request correctly updates the parent's list within one refresh cycle.
- **SC-003**: Marking a reminder removes the corresponding local alarm on the parent device.
- **SC-004**: Both flavors share the same `MedicineModel` so a single backend payload schema works for both.

## Assumptions

- The shared `add_medicine` flow is the only path to register a medicine; this feature merely lists and triggers refetch on return.
- `AlarmManager` is a no-op on web (per [init_dependencies.dart:62-65](../../../lib/init_dependencies.dart#L62-L65) — `kIsWeb` gate).
- Server returns parent's full medicine roster on page 1 (parents pagination is effectively off).
- `MedicinePrescriptionModel` payloads include a `feed: List<PrescriptionModel>` of scheduled doses.
- Teacher Requests denormalization (the 90-line payload walker) is performed client-side because the backend returns raw ids for dropdown values.
