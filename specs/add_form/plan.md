---
status: migrated
feature: add_form
migrated_from: lib/features/add_form/
migrated_date: 2026-05-14
---

# Implementation Plan: Add Form

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/add_form/spec.md](spec.md) and code in [lib/features/add_form/](../../lib/features/add_form/) (47 .dart files).

## Summary

`add_form` is the schema-driven dynamic-form engine that powers three distinct entry points (medicines, events, announcements) from a single shared screen. Its core abstraction is the `FormModel` hierarchy: 18 typed subclasses, each with a `fromJson` parser and a render widget, plus a single-string-equality `FormDependencyModel` for conditional visibility. The engine is generic, but the medicine flow has leaked specifics into the bloc (`requiredTimeSelections`, `addMedicineChildrenState`, `addMedicineFieldsState`) — see Complexity. No tests today; the open work in [features.md](../features.md#add_form--b) is doc/UX-focused (field-type catalog, validation summary, autosave, dependency-semantics doc).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `AddFormBloc` is a `Cubit<AddFormState>`
- `provider` 6.1 — `Provider<AddFormType>` exposes the form-type to descendants without re-injecting into the bloc graph ([add_form_screen.dart:79-84](../../lib/features/add_form/add_form_screen.dart#L79-L84))
- `get_it` 8 — `AddFormRepo` + `AddFormBloc` registered as **named** singletons / factories keyed by `AddFormType.name` so each entry point gets its own configured instance ([di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91))
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart) — `dio.FormData` + `MultipartFile` for multipart submits
- `dartz` — `Either<Failure, T>`
- `equatable` 2.0
- `flutter_screenutil` 5.9
- `separated_column` (project pin) — used in `FormSection` + `CollectionWidget` + `GroupWidget` for consistent spacing

**Storage**:

- Bundled JSON schemas in `assets/{medicines,events,announcements}_fields.json` loaded via `rootBundle.loadString`.
- `state.formState.data` is in-memory only (no Hive, no HydratedBloc). Compose state is lost on cold start / back-press.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors. Web is out of scope (multipart upload behavior differs).

**Project Type**: Cross-feature shared engine — used by add_medicine, events, announcements.

**Performance Goals**:

- Form render ≤ 100 ms for a typical 12-field schema.
- Save round-trip ≤ 3 s for text-only; image-heavy gated by network.

**Constraints**:

- Schema files are bundled, not server-driven. Changing a field requires an app release (or hot-update via flutter dynamic loading, not used here).
- The bloc is **not** persisted; partial entries are lost on back-press or app suspension.
- Save is not idempotent and not droppable — double-tap can double-submit.

**Scale/Scope**: 47 .dart files (22 models, 20 widgets, 1 screen, 1 bloc, 1 state, 1 repo, 1 enum, 1 utils, 1 export). 4 backend endpoints. 18 `FormType` variants. 3 `AddFormType` variants.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/add_form/` with `bloc/`, `models/`, `widgets/`, `repo/`, `utils/`. ⚠️ Variant: `repo/` instead of the more common `data_sources/`. Acceptable per [constitution principle I](../../.specify/memory/constitution.md) — feature internals vary. Worth aligning eventually.
- [x] **II. Dependency Direction** — no feature-root `add_form_di.dart`; registration is in the central [di.dart](../../lib/core/dependency_injection/di.dart). ⚠️ This is a constitution drift — feature DI should be co-located with the feature. See [tasks.md T-cleanup-1](tasks.md). Cross-feature imports of `diary/models/child_model.dart`, `diary/models/school_item.dart`, `settings/my_children/repo/my_children_repo.dart`, `add_medicine/repo/add_medicine_repo.dart` — all justified usages but flagged.
- [x] **III. Networking Contract** — all REST calls go through `NetworkClient.handleRequest` returning `Either<Failure, T>`. ✓
- [x] **IV. Persistence Discipline** — no Hive, no HydratedBloc. State is in-memory by design. (Gap: no autosave.)
- [x] **V. Flavor Branching** — no `mainKey.currentContext` usage. Parent-vs-teacher branch is via `isCurrentUserParent` in [add_form_repo.dart:32](../../lib/features/add_form/repo/add_form_repo.dart#L32). ✓
- [x] **VI. Localization** — every form `title`/`hint` carried in the schema JSON is a `LocalizationKeys` key, `.tr(context)` applied at render. ⚠️ Stray `debugPrint` calls remain in bloc and repo — developer aid, not user-visible.
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — engine is reached only post-gate from the parent main shell.
- [x] **IX. Medicine Reminders** — N/A directly; medicine creation is a downstream consumer.
- [x] **X. Theming & Sizing** — sizes use `.h`/`.w`/`.sp`/`.csh`/`.csw`; colors via `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/add_form/
├── spec.md              # User scenarios, requirements, success criteria
├── plan.md              # This file
└── tasks.md             # Migration tasks + gaps from features.md
```

### Source Code (existing)

```text
lib/features/add_form/
├── add_form_screen.dart                            # entry point, dispatcher, SaveButton
├── add_form_type.dart                              # enum {medicine, event, announcement}
├── bloc/
│   ├── add_form_bloc.dart                          # Cubit<AddFormState>
│   └── add_form_state.dart                         # composite with 5 sub-states
├── repo/
│   └── add_form_repo.dart                          # NetworkClient + asset loading + multipart packing
├── models/
│   ├── add_form_model.dart                         # FormModel abstract base + FormType enum + FormDependencyModel + UnImplementedFormModel
│   ├── params.dart                                 # CreateFormParams + UploadFileParam
│   ├── text_model.dart                             # FormType.text
│   ├── text_area_model.dart                        # FormType.textArea
│   ├── rich_text_model.dart                        # FormType.richText
│   ├── number_model.dart                           # FormType.number
│   ├── counter_model.dart                          # FormType.counter
│   ├── date_picker_model.dart                      # FormType.datePicker
│   ├── time_picker_model.dart                      # FormType.timePicker
│   ├── dropdown_model.dart                         # FormType.dropdown
│   ├── multiselect_model.dart                      # FormType.multiselect
│   ├── segmented_control_model.dart                # FormType.segmented
│   ├── period_of_time_model.dart                   # FormType.periodOfTime
│   ├── create_meeting_button_model.dart            # FormType.createMeetingButton
│   ├── upload_image_model.dart                     # FormType.uploadImage
│   ├── attachments_model.dart                      # FormType.attachment
│   ├── comments_model.dart                         # FormType.comments
│   ├── attendants_selection_model.dart             # FormType.attendantsSelection (driven by side controller, not a render widget)
│   ├── collection_model.dart                       # FormType.collection — nested with List<FormModel>
│   └── group_model.dart                            # FormType.group — nested with List<FormModel>
├── widgets/
│   ├── forms.dart                                  # FormSection + FormCard primitives
│   ├── text.dart, text_area.dart, rich_text.dart, number.dart
│   ├── counter.dart, date_picker.dart, time_picker.dart
│   ├── dropdown.dart, multiselect.dart, segmented.dart
│   ├── period_of_time.dart, create_meeting_button.dart
│   ├── upload_image.dart, attachments.dart, comments.dart
│   ├── attendants_selection_button.dart            # consumes ValueNotifier<List<SchoolItem>> from the screen
│   ├── collection.dart                             # boxed nested rendering
│   ├── group.dart                                  # transparent nested rendering
│   ├── empty.dart                                  # empty-state widget
│   └── success.dart                                # post-save success widget
└── utils/
    └── utils.dart                                  # updateWhen(FormModel) + getData(state, FormModel)
```

### Cross-feature touch points

- [lib/core/dependency_injection/di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91) — registers one repo + one bloc per `AddFormType` value (named instances).
- [lib/core/user/current_role.dart](../../lib/core/user/current_role.dart) — `isCurrentUserParent` decides whether to inject the parent's children into the medicines schema.
- [lib/features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart) — `ChildModel` is the shape that flows into `addMedicineChildrenState.data` and the medicines `children` dropdown values. Shared across diary, chat, home, add_form.
- [lib/features/diary/models/school_item.dart](../../lib/features/diary/models/school_item.dart) — the attendants sheet emits a `List<SchoolItem>`; the screen translates these into the `receivers` form entry.
- [lib/features/settings/my_children/repo/my_children_repo.dart](../../lib/features/settings/my_children/repo/my_children_repo.dart) — `getChildren(1)` is called from `fetchFields()` (medicines) and `fetchAddMedicineData()`.
- [lib/features/add_medicine/repo/add_medicine_repo.dart](../../lib/features/add_medicine/repo/add_medicine_repo.dart) — `saveMedicine()` is delegated to this repo, not `AddFormRepo`. Medicine save path bypasses the generic `saveForm`.
- [lib/features/attendants_selection/](../../lib/features/attendants_selection/) — `AttendantsSelectionSheet.open()` is called from the screen's `initState`.
- [lib/core/event_bus.dart](../../lib/core/event_bus.dart) — `EventAdded` event is fired on save success to refresh the home + events screens.

**Structure Decision**: Standard layout with two minor deviations — `repo/` directory name (vs. `data_sources/`) and central DI registration (vs. feature-root `add_form_di.dart`). Both flagged in cleanup.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Medicine-specific state (`requiredTimeSelections`, `addMedicineChildrenState`, `addMedicineFieldsState`) lives inside generic `AddFormBloc` / `AddFormState` | Originally `AddFormBloc` was the only bloc; the medicine surface accreted onto it instead of getting its own. | A dedicated `AddMedicineBloc` extending or composing `AddFormBloc` would keep the engine generic. Cost: re-wiring DI + medicine screens. See [tasks.md T-arch-1](tasks.md). |
| `saveMedicine` exists alongside `saveForm` because `addMedicineRepo.saveMedicine` is its own multipart-packing path | Medicine prescriptions have a different multipart shape (prescription image, dose schedule list) — easier to special-case than fold into `saveForm`. | Generalize `saveForm` to read a per-`AddFormType` body-builder function. Deferred. See [tasks.md T-arch-1](tasks.md). |
| `fetchForm` endpoint is `''` for event / announcement | `fetchForm` is invoked only when `id != null`, which only happens for medicine edits today. Other types simply never hit this path... | ...but if a caller does pass an `id`, the empty-string URL fires a request anyway. Either gate the call by type or assert. See [tasks.md T-fix-3](tasks.md). |
| Hardcoded `/api/v1/teacher/announcements` (double prefix) | Likely a copy-paste from a curl example. | Either the server tolerates the double prefix (works today) or it's a bug. Either way: align with the other endpoints which use relative paths. See [tasks.md T-fix-1](tasks.md). |
| `saveForm` / `saveMedicine` are bare async methods on a Cubit (no `droppable`) | `Cubit` does not have event-handler semantics; debounce/dropping must be added manually. | Wrap with a `_saving` flag inside the cubit and short-circuit. Or migrate to `Bloc<AddFormEvent, AddFormState>` and use `EventTransformer`. See [tasks.md T-fix-2](tasks.md). |
| Central DI registration in `core/dependency_injection/di.dart` | Originated before feature-root DI became the convention. | Move to `lib/features/add_form/add_form_di.dart` implementing `DependencyInjection`, wired in `init_dependencies.dart`. See [tasks.md T-cleanup-1](tasks.md). |
| `Provider<AddFormType>` + `di<AddFormBloc>(instanceName: type.name)` double-injection | The form-type drives both DI keying AND in-tree config lookup; provider gives descendants cheap access without re-resolving from `di`. | Pass `AddFormType` down through constructors. Cost: ~20 widgets. Deferred. |
