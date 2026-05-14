---
status: migrated
feature: settings/medicines
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: Medicines

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

**Scope**: covers both `lib/features/settings/medicines/` (parents) and `lib/features/settings/medicines_professors/` (teachers) plus the shared `lib/features/add_medicine/`.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create parents-side [lib/features/settings/medicines/](../../../lib/features/settings/medicines/) with `bloc/`, `repo/`, `models/`, `widgets/`.
- [x] T002 Create teachers-side [lib/features/settings/medicines_professors/](../../../lib/features/settings/medicines_professors/) with `bloc/`, `data_source/`, `components/`, `widgets/`, `models/`.
- [x] T003 Add localization keys (`medicines`, `reminders`, `requstes` (sic), `history`, `add_medicine`, `delete_medicine_title`, `delete_medicine_content`, `success_action`).
- [x] T004 Register `MedicinesRepo` + `MedicinesBloc` in [di.dart:69, 102](../../../lib/core/dependency_injection/di.dart#L69); register `MedicinesProfessorsInjection().init()` at [di.dart:117](../../../lib/core/dependency_injection/di.dart#L117).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define shared `MedicineModel`, `MedicineBodyModel`.
- [x] T011 Define `MedicinePrescriptionModel` + `PrescriptionModel` for teachers tabs.
- [x] T012 Implement parents-side `MedicinesRepo.getMedicines` + `deleteMedicine`.
- [x] T013 Implement teachers-side `MedicinesProfessorsRepo` with denormalization, `acceptRequest`, `rejectRequest`, `markMedicineReminder`, `getMedicineHistory`, `getMedicineReminder`.

## Phase 3: User Story 1 — Parent CRUD (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement `MedicinesScreen` with grouped list per child.
- [x] T021 [US1] Wire `FetchMedicines` / `DeleteMedicine` events and snack feedback.
- [x] T022 [US1] Wire **Add medicine** CTA → `AddMedicineScreen(type: AddFormType.medicine)`; on pop `true`, refetch.
- [x] T023 [US1] Wire per-row **Edit** → `AddMedicineScreen` with `id`, `MedicineModel`, `MedicineBodyModel`; on pop `true`, refetch.
- [x] T024 [US1] Wire **Delete** → `confirmDialog(delete_medicine_title, delete_medicine_content)` → `DeleteMedicine(id)`.

## Phase 4: User Story 2 — Teacher review (P1) — ✅ Complete

- [x] T030 [US2] Implement `MedicinesProfessorsScreen` with 3-tab `TabController` (Reminders / Requests / History).
- [x] T031 [US2] Implement `MedicinesRemindersPage` with `AutomaticKeepAliveClientMixin`, per-row `MedPresBloc`, list, refresh, alarm removal.
- [x] T032 [US2] Implement `MedicinesRequestsPage` rendering denormalized payloads.
- [x] T033 [US2] Implement `MedicinesHistoryPage`.
- [x] T034 [US2] Wire Accept → `POST teacher/medicines/requests/{id}` `{status: approved}`.
- [x] T035 [US2] Wire Reject → `POST teacher/medicines/requests/{id}` `{status: declined, reason}` (attachments parameter is currently dropped).
- [x] T036 [US2] Wire Mark-reminder-read → `PUT /teacher/medicines/reminders/{id}` `{read: 1, reminder_id}`.

## Phase 5: User Story 3 — Local alarms (P1) — ✅ Complete (handled in `add_medicine` + `AlarmManager`)

- [x] T040 [US3] `AddMedicineScreen` schedules `AlarmManager` entries when saving a new medicine.
- [x] T041 [US3] `MedicinesRemindersPage` removes the alarm by id on success of `MedPresBloc.check`.

---

## Phase 6: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P2)** *(from [features.md#settings--b](../../features.md#settings--b))* Align with the `add_medicine` flow as a single source of truth for schedule data. Today the parent UI fetches the schedule from `MedicineBodyModel` but the teacher tabs read it from `MedicinePrescriptionModel.feed.PrescriptionModel`. Document the canonical schedule schema and unify.

- [ ] **T-fix-2** **(P1)** [US2] Reject-request attachments are accepted by `MedicinesProfessorsRepo.rejectRequest(id, reason, attachments)` but **not transmitted** — `attachments` is discarded; `reason` is in `queryParameters`. Move to a multipart body that actually uploads the files.

- [ ] **T-fix-3** **(P1)** [US1] Parents empty-state has no **Add medicine** CTA. Move the `CustomButton(add_medicine)` outside the `if (medicines.isNotEmpty)` guard ([medicine_screen.dart:168-183](../../../lib/features/settings/medicines/medicine_screen.dart#L168-L183)).

- [ ] **T-fix-4** **(P2)** [US2] Move medicine-payload denormalization to the backend; today the teachers-side does two round-trips (form schema + medicine list) just to render strings.

- [ ] **T-fix-5** **(P3)** [US1] Either wire pagination (`onLoadMore`) on `Pagination` in `medicine_screen.dart` or remove the wrapper.

- [ ] **T-fix-6** **(P3)** Fix the `requstes` localization key typo. Update key name in [localization_keys.dart](../../../lib/core/localization/localization_keys.dart) and all three locale JSONs.

### Code hygiene

- [ ] **T-cleanup-1** Delete the ~100 lines of commented-out denormalization in [medicines_repo.dart:22-106](../../../lib/features/settings/medicines/repo/medicines_repo.dart#L22-L106).
- [ ] **T-cleanup-2** Delete the unused `_basicErrorHandling` extension at the bottom of [medicine_professors_impl.dart](../../../lib/features/settings/medicines_professors/data_source/medicine_professors_impl.dart) (and in `announcements_impl.dart`, `events_impl.dart`, `single_event_impl.dart` — pattern is repeated).
- [ ] **T-cleanup-3** Delete the commented `MedicinesProfessorsRepo` abstract contract in [medicine_professors_repo.dart](../../../lib/features/settings/medicines_professors/data_source/medicine_professors_repo.dart) (the file is currently `export 'medicine_professors_impl.dart';` + ~14 lines of commented contract).
- [ ] **T-cleanup-4** Delete the `SubmitMedicinesEvent` dead event in [medicines_events.dart:21](../../../lib/features/settings/medicines/bloc/medicines_events.dart#L21).
- [ ] **T-cleanup-5** Delete the commented `TabBarWidget` block + `Container(...)` in [medicine_professors_screen.dart:98-119](../../../lib/features/settings/medicines_professors/medicine_professors_screen.dart#L98-L119).

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `FetchMedicines` → `DeleteMedicine` → `FetchMedicines` chain.
- [ ] **T-test-2** [P] [US2] Cubit test: `loadRequests` denormalizes a dropdown id to its `value.title`.
- [ ] **T-test-3** [P] [US3] Widget test: marking a reminder removes the alarm by `item.id`.

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze` after cleanups.
- [ ] **TX02** Verify both flavors end-to-end against a real Brazilian device with the platform alarms permission.

---

## Gaps Found

- **No empty-state Add CTA** — first-time parents can't add.
- **Attachments dropped on reject** — teachers can't share supporting docs.
- **`requstes` typo** in localization key.
- **Schedule data duplication** between parent-side `MedicineBodyModel` and teacher-side `MedicinePrescriptionModel.feed`.
- **Multiple dead extensions** (`_basicErrorHandling`) littered across settings sub-features.

## Notes

- `MedicinesBloc` is a `Bloc`; `MedicinesProfessorsBloc` is a `Cubit`. Different style choices — not consolidated.
- The teacher pages use `AutomaticKeepAliveClientMixin` so each tab fetches once per screen lifetime.
- `add_medicine/` lives outside this folder structure but is functionally part of this feature; consider co-locating in a future refactor.
