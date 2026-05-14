---
status: migrated
feature: add_form
migrated_from: specs/features.md#add_form--b
migrated_date: 2026-05-14
---

# Tasks: Add Form

**Input**: [spec.md](spec.md), [plan.md](plan.md), and [features.md#add_form--b](../features.md#add_form--b).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

**Organization**: This is a **migration** of an existing feature (47 .dart files). Story labels map to user stories in [spec.md](spec.md): US1 = render schema, US2 = save, US3 = re-edit. X = cross-cutting.

---

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/add_form/](../../lib/features/add_form/) with `bloc/`, `models/`, `widgets/`, `repo/`, `utils/`
- [x] T002 Bundle the three schema assets at [assets/medicines_fields.json](../../assets/medicines_fields.json), [assets/events_fields.json](../../assets/events_fields.json), [assets/announcements_fields.json](../../assets/announcements_fields.json)
- [x] T003 Localization keys for screen titles, snacks, and error copy in [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) (medicines, events, announcements variants)
- [x] T004 Register `AddFormRepo` per `AddFormType` (named singleton) and `AddFormBloc` per `AddFormType` (named factory) in [lib/core/dependency_injection/di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91) — ⚠️ central registration, not feature-root; see T-cleanup-1.

---

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define [AddFormType](../../lib/features/add_form/add_form_type.dart) enum `{medicine, event, announcement}`
- [x] T011 Define [FormType](../../lib/features/add_form/models/add_form_model.dart#L44-L64) enum with 18 variants + `unimplemented` fallback
- [x] T012 Define `FormModel` abstract base with tolerant `fromJson` dispatcher returning `UnImplementedFormModel` on unknown types
- [x] T013 Define `FormDependencyModel { id, value }` for single-string-equality dependency rules
- [x] T014 Define 18 concrete `FormModel` subclasses in `models/`, each with a `fromJson` + `toJson` + Equatable `props`
- [x] T015 Define `CreateFormParams { type, value }` and `UploadFileParam { id?, url }` in [models/params.dart](../../lib/features/add_form/models/params.dart)
- [x] T016 Define `AddFormState` composite with five sub-states (formState, fetchApiState, saveApiState, addMedicineChildrenState, addMedicineFieldsState) in [bloc/add_form_state.dart](../../lib/features/add_form/bloc/add_form_state.dart)
- [x] T017 Implement `AddFormBloc` as `Cubit<AddFormState>` with `fetchFields`, `fetchForm`, `saveForm`, `saveMedicine`, `updateForm`, `fetchAddMedicineData`

---

## Phase 3: User Story 1 — Render schema-driven form (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Asset-loading branch by `AddFormType` in `AddFormRepo.fetchFields` ([add_form_repo.dart:28-47](../../lib/features/add_form/repo/add_form_repo.dart#L28-L47))
- [x] T021 [US1] Inject parent's children list into medicines schema when `isCurrentUserParent` (T-cleanup-2: previously `mainKey.currentContext`-based; replaced)
- [x] T022 [US1] Top-level dispatcher `getField(FormModel)` ([add_form_screen.dart:317-359](../../lib/features/add_form/add_form_screen.dart#L317-L359)) maps each `FormType` to its widget; unknown → `SizedBox`
- [x] T023 [US1] `validateDependency(field, form)` ([add_form_screen.dart:300-315](../../lib/features/add_form/add_form_screen.dart#L300-L315)) filters hidden fields out of `getFields(...)` and out of the submit payload
- [x] T024 [US1] Single-level dependency cascade in `updateForm`: change to parent drops child's stored value ([add_form_bloc.dart:86-91](../../lib/features/add_form/bloc/add_form_bloc.dart#L86-L91))
- [x] T025 [US1] Nested rendering via `CollectionFormModel` (boxed `FormCard`) and `GroupFormModel` (transparent column), both recursing through `getFields(...)`
- [x] T026 [US1] `AttendantsSelectionSheet.open(...)` on first frame for event / announcement; pop the screen on dismiss

## Phase 4: User Story 2 — Save (P1) — ✅ Complete

- [x] T030 [US2] Endpoint switch by `AddFormType` in `AddFormRepo.saveForm`
- [x] T031 [US2] Multipart packing: `dio.FormData.fromMap(...)` with `MultipartFile.fromFile(...)` for non-http `UploadFileParam.url` values
- [x] T032 [US2] `_method: 'PUT'` added to body when `id != null` (Laravel update convention)
- [x] T033 [US2] Event-specific `audiences[child|class|level|teacher|parent][N]` flattening + `all_parents`/`all_teachers` sentinels
- [x] T034 [US2] `start_date` / `end_date` concatenation from `starting_date` + `starting_time` (and ending pair) for events
- [x] T035 [US2] Medicine save delegates to `AddMedicineRepo.saveMedicine` (own multipart shape)
- [x] T036 [US2] `eventBus.fire(EventAdded())` + localized success snack + `Navigator.pop(true)` on save success

## Phase 5: User Story 3 — Re-edit (P2) — ✅ Complete (medicine only)

- [x] T040 [US3] `fetchForm(id)` runs `fetchFields()` + `GET /parent/medicines/{id}` in parallel via `Future.wait`
- [x] T041 [US3] `payload` map matched against `FormModel.id` to produce `Map<FormModel, CreateFormParams>` ([add_form_repo.dart:88-103](../../lib/features/add_form/repo/add_form_repo.dart#L88-L103))
- [x] T042 [US3] `attachment` / `uploadImage` entries parsed via `UploadFileParam.fromJson` (no upload — they're already remote URLs)
- [x] T043 [US3] `counter` values normalized via `convertToDouble` (server may send as string)

---

## Phase 6: Gaps & cleanups (from features.md + this migration)

### Open from features.md

- [ ] **T-feat-1** **(P2)** *(from [features.md#add_form--b](../features.md#add_form--b))* Document every supported field type in this trio — **Done in [spec.md FR-003](spec.md#functional-requirements) (18 types tabulated).**
- [ ] **T-feat-2** **(P1)** *(from [features.md#add_form--b](../features.md#add_form--b))* Add a validation summary at the top of the form on submit failure. Today `Form.of(context).validate()` returns false silently; individual fields show their own errors but there's no aggregated summary.
- [ ] **T-feat-3** **(P1)** *(from [features.md#add_form--b](../features.md#add_form--b))* Snapshot autosave so back-press doesn't lose data. Options: (a) snapshot to Hive keyed by `AddFormType` on every `updateForm`; (b) prompt the user on `WillPopScope` if `state.formState.data` is non-empty. Snapshot serialization needs `CreateFormParams.toJson` to handle the `Object value` field for all 18 types — non-trivial for `MultipartFile` and `UploadFileParam`.
- [ ] **T-feat-4** **(P2)** *(from [features.md#add_form--b](../features.md#add_form--b))* Document `FormDependencyModel` semantics with examples — **Done in [spec.md FR-004 + FR-005 + Edge Cases](spec.md#functional-requirements). Example from `medicines_fields.json`: the dose-time sub-fields depend on `dose_number_id == '3'`. Multi-level chains (A→B→C) only cascade-drop one level deep in `updateForm`; the rest is filtered out at submit time by `validateDependency` (safe but counter-intuitive).**

### Bugs / drift

- [ ] **T-fix-1** **(P0)** [US2] Double `/api/v1/` prefix in the announcement endpoint at [add_form_repo.dart:119](../../lib/features/add_form/repo/add_form_repo.dart#L119): `'/api/v1/teacher/announcements'`. `NetworkClient` already prepends the base URL `https://criarte.filhos.app/api/v1/`. Either the server tolerates the double prefix (works today) or it's a latent bug. Align with the other endpoints — change to `teacher/announcements`.

- [ ] **T-fix-2** **(P0)** [US2] Save is **not** droppable. A double-tap on the Save CTA dispatches `saveForm` / `saveMedicine` twice. Add a guard inside the cubit:
  - Option A: a `_saving` boolean short-circuit at the top of `saveForm`.
  - Option B: migrate to `Bloc<AddFormEvent, AddFormState>` with `transformer: droppable()` on a `SaveFormEvent`.

- [ ] **T-fix-3** **(P1)** [US3] `fetchForm` is called for event / announcement with `endpoint = ''` ([add_form_repo.dart:55-58](../../lib/features/add_form/repo/add_form_repo.dart#L55-L58)). The network call fires against the base URL and predictably fails; the `Future.wait` `fold` returns an empty `Map` so the screen still renders, but it's a wasted round-trip. Gate the call: only invoke `networkClient.handleRequest` when `addFormType == AddFormType.medicine && id != null`, OR add `endpoint` cases for event/announcement edit when those flows ship.

- [ ] **T-fix-4** **(P2)** [US1] Medicine-specific magic constant `requiredTimeSelections` ([add_form_bloc.dart:92-95](../../lib/features/add_form/bloc/add_form_bloc.dart#L92-L95)) inside the generic bloc. Move into `AddMedicineBloc` (T-arch-1) or at minimum behind a `if (addFormType == AddFormType.medicine)` guard.

- [ ] **T-fix-5** **(P2)** [US2] `print('AddFormBloc.updateForm')` + `print(getPrettyJSONString(...))` ([add_form_bloc.dart:97-99](../../lib/features/add_form/bloc/add_form_bloc.dart#L97-L99)) — route through a structured logger that drops in release. Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) "Route 146 print/debugPrint calls through a single logger."

### Architecture

- [ ] **T-arch-1** **(P2)** [US2, US3] Promote medicine-specific concerns out of the generic `AddFormBloc` / `AddFormState`. Today the generic state carries `addMedicineChildrenState`, `addMedicineFieldsState`, and the generic bloc carries `requiredTimeSelections`, `fetchAddMedicineData`, `saveMedicine`. A dedicated `AddMedicineBloc` composing `AddFormBloc` (or extending it) would keep the engine clean. Coordinate with [add_medicine/](../../lib/features/add_medicine/) — the actual `AddMedicineScreen` uses `AddFormBloc` directly today.

- [ ] **T-arch-2** **(P2)** [US2] Generalize the multipart-packing path: `saveForm` has 60+ lines of inlined nested-conditional body-building. Extract to a per-`AddFormType` `FormEncoder` strategy.

### Code hygiene / Constitution drift fixes

- [ ] **T-cleanup-1** **(P1)** [X] Move DI registration from [core/dependency_injection/di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91) into a new feature-root `lib/features/add_form/add_form_di.dart` implementing `DependencyInjection`. Wire through [init_dependencies.dart](../../lib/init_dependencies.dart). Follows [constitution principle II](../../.specify/memory/constitution.md). Same pattern as other features (login, diary, chat).

- [x] **T-cleanup-2** **(P0)** [US1] Replaced `mainKey.currentContext`-based role check in `AddFormRepo.fetchFields` with `isCurrentUserParent` from [core/user/current_role.dart](../../lib/core/user/current_role.dart). *Fixed as part of the cross-feature `mainKey` sweep on 2026-05-14.*

- [ ] **T-cleanup-3** [X] Rename `lib/features/add_form/repo/` to `lib/features/add_form/data_sources/` to align with sibling features. Project-wide grep-and-replace; coordinate timing.

- [ ] **T-cleanup-4** [X] Remove the trailing `debugPrint('getField ${field.id}')` at [add_form_screen.dart:319](../../lib/features/add_form/add_form_screen.dart#L319) — fires on every field render, noisy.

- [ ] **T-cleanup-5** [X] Remove or guard the `for (final entry in form.entries) { debugPrint('${entry.key}: ...') }` in `saveForm` ([add_form_repo.dart:108-110](../../lib/features/add_form/repo/add_form_repo.dart#L108-L110)) — leaks form payload (potentially including medication / CPF / phone) to logs.

- [ ] **T-cleanup-6** [X] Snake-case field name `number_of_dosesModels` in `AddMedicineFieldsState` ([add_form_state.dart:166](../../lib/features/add_form/bloc/add_form_state.dart#L166)) — should be `numberOfDosesModels`.

- [ ] **T-cleanup-7** [X] Inconsistency: `FormType.unimplemented` `case` in `FormModel.fromJson` is `break` (falls through to `return UnImplementedFormModel()` at line 125), but a server-provided type that doesn't match any enum name also falls through to the same return. Functionally identical, just a code-style note.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Repo test: `AddFormRepo.fetchFields(medicine)` correctly decodes the bundled asset and injects parent children when `isCurrentUserParent`.
- [ ] **T-test-2** [P] [US1] Cubit test: `updateForm(parent, value)` correctly drops the dependent child's value from `state.formState.data`.
- [ ] **T-test-3** [P] [US1] Widget test: a field with `dependency: { id: X, value: Y }` is hidden when X's current value != Y, and shown when X's value becomes Y.
- [ ] **T-test-4** [P] [US2] Repo test: `saveForm(event)` builds the correct `audiences[child][N]` flattening for a mixed-target receivers map.
- [ ] **T-test-5** [P] [US2] Repo test: `saveForm(medicine, id: '42')` includes `_method: PUT` in the body.
- [ ] **T-test-6** [P] [US3] Repo test: `fetchForm(id)` correctly hydrates `UploadFileParam` for attachment / uploadImage payload entries.
- [ ] **T-test-7** [P] [US2] Double-tap test: dispatching `saveForm` twice in rapid succession must result in only one HTTP request (after T-fix-2).
- [ ] **T-test-8** [P] [US1] Tolerant parsing test: an unknown `FormType` string in the schema must produce an `UnImplementedFormModel` placeholder and not throw.

---

## Constitution Drift Summary

| Drift | Site | Status |
|---|---|---|
| Central DI registration instead of feature-root `add_form_di.dart` | [di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91) | Open — T-cleanup-1 |
| `repo/` directory instead of `data_sources/` | [repo/](../../lib/features/add_form/repo/) | Open — T-cleanup-3 |
| Medicine-specific state in generic bloc | [add_form_state.dart:139-245](../../lib/features/add_form/bloc/add_form_state.dart#L139-L245) | Open — T-arch-1 |
| `mainKey.currentContext` role check in repo | [add_form_repo.dart:32](../../lib/features/add_form/repo/add_form_repo.dart#L32) | ✅ Fixed (T-cleanup-2) — now `isCurrentUserParent` |
| `debugPrint`s on every render and per-field on save | screen + repo | Open — T-cleanup-4, T-cleanup-5 |

## Gaps Found

1. **Save is not idempotent and not droppable** (T-fix-2) — double-tap can double-submit.
2. **Wasted round-trip on event/announcement edit-mode** because `fetchForm` endpoint is `''` (T-fix-3).
3. **Double `/api/v1/` prefix** in announcement endpoint (T-fix-1) — works today, possibly a latent bug.
4. **No autosave / snapshot** — partial entries lost on back-press (T-feat-3).
5. **No validation summary** at the top of a failing form (T-feat-2).
6. **Medicine-specific concerns** leaked into the generic engine (T-arch-1).
7. **Form payload `debugPrint`** leaks potentially sensitive data (medication name, dose) to logs (T-cleanup-5).
8. **Central DI registration** violates feature-root convention (T-cleanup-1).
9. **`repo/` vs `data_sources/`** directory naming inconsistency (T-cleanup-3).
10. **Dependency cascade is single-level only** — chains (A→B→C) only drop one level deep at update time; multi-level dropping happens at submit-time via `validateDependency`. Counter-intuitive but safe today.

## Notes

- This migration covers the engine + the three known `AddFormType` flows. Widget-level details (per-widget hardcoded strings, theming drift across the 20 widget files) were not exhaustively audited — flagged for follow-up.
- The actual flow for "Add Medicine" routes through `AddFormScreen(type: AddFormType.medicine)` from [add_medicine_screen.dart](../../lib/features/add_medicine/add_medicine_screen.dart); the `add_medicine` feature is largely a thin wrapper plus its own repo.
