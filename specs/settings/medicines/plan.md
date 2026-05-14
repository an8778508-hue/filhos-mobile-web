---
status: migrated
feature: settings/medicines
migrated_from: lib/features/settings/medicines/ + lib/features/settings/medicines_professors/
migrated_date: 2026-05-14
---

# Implementation Plan: Medicines

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/medicines/spec.md](spec.md) and code in [lib/features/settings/medicines/](../../../lib/features/settings/medicines/) + [lib/features/settings/medicines_professors/](../../../lib/features/settings/medicines_professors/) + [lib/features/add_medicine/](../../../lib/features/add_medicine/).

## Summary

Two co-located but structurally independent feature modules backed by **one** shared model layer. Parents register and manage medicines; teachers see incoming requests, scheduled reminders, and a history feed. Parents register entries through the **add_form** engine (`AddFormType.medicine`) reused as `AddMedicineScreen`. Reminders are local-alarm-driven on the parent device; teachers mark them read on the server.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0`.

**Primary Dependencies**:

- `flutter_bloc` — parents uses `Bloc<MedicinesEvents, MedicinesStates>`; teachers uses `Cubit<MedicinesProfessorsStates>`.
- `dartz` — `Either<Failure, T>`.
- `dio` — `FormData` for multipart payloads inside `add_medicine`.
- `separated_column` / `separated_row` — list spacing on teacher tabs.
- Shared `AddFormRepo` (medicine variant), `AddFormBloc` — schema-driven editor.
- `AlarmManager` (native wrapper in [lib/core/custom_packages/](../../../lib/core/custom_packages/)).

**Storage**: native device alarms (Android `AlarmManager` / iOS `LocalNotification`). No bloc persistence.

**Testing**: none.

**Target Platform**: iOS + Android, both flavors (different screens).

**Project Type**: Flutter mobile feature with two flavor-specific sub-modules.

**Performance Goals**: tab switch latency negligible — `AutomaticKeepAliveClientMixin` keeps each tab's state hot.

**Constraints**:

- Teachers-side `getMedicineRequests` first fetches `AddFormRepo.fetchFields()` to perform payload denormalization client-side. Two round-trips per Requests tab open.
- Local alarms can't be tested on web (`AlarmManager.init` skipped on `kIsWeb`).
- `MedicineModel.created_at` is a `String`, not a `DateTime`. Sorting on this is string-lexicographic — acceptable for ISO-8601 dates only.

**Scale/Scope**: ~30 .dart files combined across parents + teachers + shared models + `add_medicine`.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `medicines/{bloc,repo,models,widgets}` + `medicines_professors/{bloc,data_source,components,widgets,models}`. ⚠️ Teachers-side uses `data_source/` (singular) and `components/`; parents-side uses `repo/` and `widgets/`. Inconsistent but matches what was in the repo.
- [x] **II. Dependency Direction** — teachers-side `medicine_professors_impl.dart` imports from `add_form/` (the form repo). Acceptable (cross-feature shared schema infra).
- [x] **III. Networking Contract** — `NetworkClient.handleRequest` everywhere. ✓
- [x] **IV. Persistence Discipline** — alarms via `AlarmManager`; no direct Hive use here.
- [x] **V. Flavor Branching** — gated at Settings shell; no `mainKey.currentContext` references.
- [x] **VI. Localization** — surfaces use `LocalizationKeys`. ⚠️ `requstes` typo on the tab key.
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit (Settings).
- [x] **IX. Medicine Reminders** — `AlarmManager` is the single owner of platform alarms; no parallel `flutter_local_notifications` schedules for the same id. ✓
- [x] **X. Theming & Sizing** — `.h/.w/.csh/.csw/.r/.sp` + `context.colors.*` throughout.

## Project Structure

### Documentation (this feature)

```text
specs/settings/medicines/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/medicines/                    # parents flavor
├── medicine_screen.dart
├── bloc/
│   ├── medicines_bloc.dart
│   ├── medicines_events.dart
│   └── medicines_states.dart
├── repo/
│   └── medicines_repo.dart                         # /parent/medicines GET + DELETE
├── models/
│   ├── medicine_model.dart                         # shared with teachers
│   └── medicine_body_model.dart                    # shared
└── widgets/
    ├── medicine_body.dart
    ├── medicine_header_widget.dart
    ├── bottom_sheet_widget.dart
    ├── empty_medicine.dart
    ├── approval_medicine_button.dart
    └── icon_with_text_button.dart

lib/features/settings/medicines_professors/         # teachers flavor
├── medicine_professors_screen.dart                 # 3-tab TabController
├── bloc/
│   ├── medicines_professors_bloc.dart              # Cubit
│   ├── medicines_professors_events.dart            # empty (Cubit)
│   └── medicines_professors_states.dart
├── data_source/
│   ├── medicine_professors_di.dart
│   ├── medicine_professors_impl.dart               # denormalization + REST
│   └── medicine_professors_repo.dart               # export-only
├── components/
│   ├── medicine_reminders.dart                     # Reminders tab page
│   ├── medicine_requests.dart                      # Requests tab page
│   └── medicine_history.dart                       # History tab page
├── widgets/
│   ├── empty_medicines.dart
│   ├── medicine_request/bloc/bloc.dart             # per-row accept/reject Cubit
│   └── prescription/{bloc/bloc.dart, medicine_prescription_item.dart}
└── models/
    └── medicine_prescription_model.dart

lib/features/add_medicine/                          # shared form (parents-side)
├── add_medicine_screen.dart
└── repo/add_medicine_repo.dart
```

### Cross-feature touch points

- [lib/features/add_form/](../../../lib/features/add_form/) — schema engine and `AddFormType.medicine`.
- [lib/features/add_medicine/](../../../lib/features/add_medicine/) — parents-side editor wrapping `AddFormBloc`.
- [lib/features/settings/my_children/](../../../lib/features/settings/my_children/) — `MyChildrenRepo` injected into `AddMedicineRepo` so the form can show a child-picker.
- [lib/core/custom_packages/](../../../lib/core/custom_packages/) — `AlarmManager` native wrapper.
- [lib/core/utils/alarm_manager/alarm_manager.dart](../../../lib/core/utils/alarm_manager/alarm_manager.dart) — `removeAlarm`, called from `MedicinesRemindersPage` listener.

**Structure Decision**: two flavor modules side-by-side. Sharing only the model layer. Resists a "unified MedicinesBloc" — different states, different endpoints, different UIs.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Two separate feature modules (`medicines/` + `medicines_professors/`) | UIs and state machines diverge entirely. | A single bloc switching on `context.isProfessors` would mix two state schemas; rejected. |
| Client-side denormalization of medicine payloads ([medicine_professors_impl.dart:35-133](../../../lib/features/settings/medicines_professors/data_source/medicine_professors_impl.dart#L35-L133)) | Backend returns dropdown ids, not labels. | Backend should denormalize; tracked as a backend-side improvement. **See tasks.md T-fix-4.** |
| Reject-request body sent as `queryParameters` not body | Quick fix during integration. | Move to multipart body when wiring attachments. **See tasks.md T-fix-2.** |
| `_basicErrorHandling` extension declared but never used | Iteration scaffolding. | Delete. **See tasks.md T-cleanup-2.** |
| 100+ lines of commented denormalization in parents repo | Originally lived on parents side, moved to teachers. | Delete (git preserves). **See tasks.md T-cleanup-1.** |
| `Pagination` widget with no-op `onLoadMore` | Wraps the list for future paging. | Remove or wire — but page count is small in practice. **See tasks.md T-fix-5.** |
