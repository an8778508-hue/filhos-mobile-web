---
status: migrated
feature: add_medicine
migrated_from: lib/features/add_medicine/
migrated_date: 2026-05-14
---

# Implementation Plan: Add Medicine

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/add_medicine/spec.md](spec.md) and code in [lib/features/add_medicine/](../../lib/features/add_medicine/).

## Summary

`AddMedicineScreen` is a thin wrapper over the shared `AddFormBloc` engine instantiated with `AddFormType.medicine`. The data layer is a dedicated `AddMedicineRepo` that hits `parent/medicines/items/types` (GET) and `parent/medicines[/id]` (POST with multipart `FormData`). The downstream teacher-side `AlarmManager` then schedules native exact-time alarms via the `alarm` package, gated by `SCHEDULE_EXACT_ALARM` runtime permission and the manifest-declared foreground service.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `AddFormBloc` (instanced by form type) drives every field; `MedicinesBloc` listens for `EventAdded()` to refetch.
- `provider` 6 — `Provider<AddFormType>` exposes the form-type discriminant to inner widgets ([add_medicine_screen.dart:53-57](../../lib/features/add_medicine/add_medicine_screen.dart#L53-L57)).
- `get_it` — `AddMedicineRepo` registered as `Singleton` in [core/dependency_injection/di.dart:80-82](../../lib/core/dependency_injection/di.dart#L80-L82).
- `dio` 5 — `FormData.fromMap` + `MultipartFile.fromFile` for image upload.
- `dartz` — `Either<Failure, ...>` returns.
- `alarm` (downstream) — native exact-time alarm scheduling.
- `permission_handler` 11 — `Permission.scheduleExactAlarm` runtime check.
- `image_picker` — prescription image capture (via shared `UploadImage` field).
- `separated_column` — vertical spacing between form sections.

**Storage**:

- Hive (via `LocalDatabaseRepo`): `alarm_ids` → `List<int>` of scheduled alarm IDs.
- HydratedBloc: none directly here.

**Testing**: None today.

**Target Platform**: iOS + Android, parents flavor (registration); teacher-side alarm execution.

**Project Type**: Flutter mobile feature. Layout: `add_medicine_screen.dart` at the feature root + `repo/add_medicine_repo.dart`. No bloc folder — the screen relies on the shared `AddFormBloc`.

**Performance Goals**: Form renders < 1 s after schema fetch; save round-trip dominated by image upload (multipart, varies by device).

**Constraints**:

- Must redact `medication` / `cpf` / `phone` from Crashlytics breadcrumbs — done in `NetworkClient._redactBody`.
- Must gate exact-alarm permission on Android 12+ runtime.
- Must declare the alarm package's foreground service in `AndroidManifest.xml` — *Fixed 2026-05-14*.
- Cannot schedule alarms for today (date picker `min` is tomorrow).
- iOS 17+ / Android 14 survival is not yet validated — a P1 follow-up.

**Scale/Scope**: 2 .dart files in this feature (screen + repo) + heavy reuse of `add_form/`, `alarm_manager/`, `native_alarm/`.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [⚠] **I. Feature-First Layout** — files at the feature root: `add_medicine_screen.dart`, `repo/add_medicine_repo.dart`. **No** `lib/features/add_medicine/add_medicine_di.dart`; registration lives in `core/dependency_injection/di.dart`. Minor drift.
- [⚠] **II. Dependency Direction** — heavily imports `features/add_form/` (engine), `features/settings/medicines/models/`, `features/diary/models/school_item.dart`. Acceptable given the shared engine pattern, but tracked under [cross-feature absolute-imports lint task](../features.md#cross-feature-tasks).
- [x] **III. Networking Contract** — REST via `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — Hive access via `LocalDatabaseRepo`. ✓
- [x] **V. Flavor Branching** — alarm execution gated on `context.isProfessors` in [alarm_manager.dart:21](../../lib/core/utils/alarm_manager/alarm_manager.dart#L21). The add-medicine screen itself runs in the parents flavor only via upstream nav. ✓
- [x] **VI. Localization** — all field titles/hints use `LocalizationKeys.*`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — past the gate via parents settings.
- [x] **IX. Medicine Reminders** — **THE** medicine-reminders feature. Native alarm wrapper in `core/custom_packages/native_alarm/` is the constitution-mandated path. ✓
- [x] **X. Theming & Sizing** — sizes via `.h/.w/.sp/.csh`; colors via `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/add_medicine/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/add_medicine/
├── add_medicine_screen.dart                # Wraps AddFormBloc(instanceName: 'medicine')
└── repo/
    └── add_medicine_repo.dart              # fetchMedicineFields + saveMedicine (multipart)
```

### Cross-feature touch points

- [lib/features/add_form/](../../lib/features/add_form/) — the form engine: `AddFormBloc`, `AddFormState`, all field `FormModel` subclasses, `FormSection`, `SaveButton`, `ErrorFetchSection`, `ErrorSaveSection`.
- [lib/features/settings/medicines/medicine_screen.dart](../../lib/features/settings/medicines/medicine_screen.dart) — mount site for both create and edit flows.
- [lib/features/settings/medicines/models/medicine_model.dart](../../lib/features/settings/medicines/models/medicine_model.dart) + `medicine_body_model.dart` — preload models for edit.
- [lib/features/settings/my_children/repo/my_children_repo.dart](../../lib/features/settings/my_children/repo/my_children_repo.dart) — provides the child dropdown values via `AddFormBloc.addMedicineChildrenState`.
- [lib/core/utils/alarm_manager/alarm_manager.dart](../../lib/core/utils/alarm_manager/alarm_manager.dart) — teacher-side scheduler.
- [lib/core/custom_packages/native_alarm/](../../lib/core/custom_packages/native_alarm/) — native iOS / Android alarm wrapper.
- [lib/core/network/network_client.dart](../../lib/core/network/network_client.dart) — `_redactBody` knows about `medication` / `cpf` / `phone`.
- `android/app/src/main/AndroidManifest.xml` — declares the alarm foreground service + exact-alarm permissions (added 2026-05-14).

**Structure Decision**: Keep layout. Extract `add_medicine_di.dart` (cleanup). Address iOS 17+ / Android 14 survival as a separate verification task.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Two distinct alarm packages: `alarm` + a custom `native_alarm/` wrapper | The `alarm` package handles the cross-platform scheduling; the custom wrapper adds Brazil-specific UX (vibration patterns, foreground-service text) and a `MethodChannel` bridge. | Stick with `alarm` alone and add a lint to forbid mixing — but the custom wrapper exists; remove it later in a coordinated cleanup. Tracked under [features.md `add_medicine` `Encrypt prescription images at rest`](../features.md#add_medicine--p) sweep. |
| Two commented-out `saveMedicine` blocks ([add_medicine_repo.dart:32-87, 97-123](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L32-L123)) | Iterations of the multipart serialization that landed elsewhere. | Delete; mechanical. |
| `print` calls in `add_medicine_screen.dart` ([line 188, 191](../../lib/features/add_medicine/add_medicine_screen.dart#L188-L191)) | Debug leftovers. | Drop; part of the cross-feature [logger task](../features.md#cross-feature-tasks). |
| `starting_date.min = tomorrow` | School business rule: alarms cannot be scheduled for past times. | Allow same-day registration if dose time is later — would require date+time picker, not just date. Out of scope. |
| `parent/medicines/items/types` endpoint name uses `items/types` (singular/plural mix) | Backend choice. | Coordinate naming with backend team. Not blocking. |
| No `_method: PUT` override on edit | Backend tolerates POST for both. | If the backend ever requires PUT for idempotency, add the override field. Tracked. |
