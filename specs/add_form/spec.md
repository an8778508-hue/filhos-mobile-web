---
status: migrated
feature: add_form
flavor_scope: both
migrated_from: specs/features.md#add_form--b
migrated_date: 2026-05-14
---

# Feature Specification: Add Form (Dynamic Form Engine)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/add_form/](../../lib/features/add_form/) (47 .dart files) and the existing [features.md `## add_form · B`](../features.md#add_form--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores) — flavor branching happens by `AddFormType`, not by flavor flag.
- **Flavor-conditional behavior**:
  - `AddFormType.medicine` is parents-only in practice (the parent app reaches it from the medicines surface; the teacher app does not surface a "register medication" CTA), but the same screen renders in both flavors. The medicine field schema in [assets/medicines_fields.json](../../assets/medicines_fields.json) injects the parent's own children into the `children` multiselect when `isCurrentUserParent` is true ([add_form_repo.dart:32-38](../../lib/features/add_form/repo/add_form_repo.dart#L32-L38)).
  - `AddFormType.event` and `AddFormType.announcement` are teacher-side composition flows; the screen auto-opens [AttendantsSelectionSheet](../../lib/features/attendants_selection/) on first build ([add_form_screen.dart:182-197](../../lib/features/add_form/add_form_screen.dart#L182-L197)).
  - The `receivers` field shape is **different** for events vs. announcements at the network layer — events use `audiences[child][N]` flat keys, announcements use `receivers[children][]` nesting ([add_form_repo.dart:124-225](../../lib/features/add_form/repo/add_form_repo.dart#L124-L225)).
- **Server role implication**: endpoint paths differ per form type, not per flavor:
  - Medicines (parent) → `/parent/medicines` (POST) / `/parent/medicines/{id}` (PUT via `_method`)
  - Events (teacher) → `events/create` (POST)
  - Announcements (teacher) → `/api/v1/teacher/announcements` (POST) ⚠️ note the stray `/api/v1/` prefix — see Gaps.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Render a schema-driven form (Priority: P1) 🎯 MVP

A user opens an entry point (Add Medicine / Add Event / Add Announcement). The screen loads the right JSON schema, renders one widget per typed field, evaluates field-level `dependency` rules to hide/show children, and surfaces a Save button.

**Why this priority**: This is the single shared engine behind every "add medication / create event / publish announcement" surface. If it doesn't render, none of those work.

**Independent Test**:
1. From the parents flavor, navigate to "Add Medicine" → `AddFormScreen(type: AddFormType.medicine)`.
2. The bundled asset `assets/medicines_fields.json` decodes; `AddFormFormModel.fromJson` produces a `List<FormModel>`.
3. Each `FormModel` subclass dispatches in [getField()](../../lib/features/add_form/add_form_screen.dart#L317-L359) to a typed widget.
4. Filling a `dose_number_id` dropdown updates `requiredTimeSelections` ([add_form_bloc.dart:92-95](../../lib/features/add_form/bloc/add_form_bloc.dart#L92-L95)) and the dependent collection re-renders.

**Acceptance Scenarios**:

1. **Given** an `AddFormType`, **When** `_AddFormBodyState.initState` runs, **Then** `fetchFields()` decodes the matching bundled JSON in [add_form_repo.dart:28-47](../../lib/features/add_form/repo/add_form_repo.dart#L28-L47).
2. **Given** a `FormModel` with `dependency: { id: X, value: Y }`, **When** the user-typed value of field `X` is not equal to `Y`, **Then** the dependent field is hidden in `getFields()` via `validateDependency()` ([add_form_screen.dart:300-315](../../lib/features/add_form/add_form_screen.dart#L300-L315)) **and** its entry is removed from `state.formState.data` so it doesn't get submitted ([add_form_bloc.dart:96](../../lib/features/add_form/bloc/add_form_bloc.dart#L96)).
3. **Given** a `FormType` value not yet implemented client-side, **When** `FormModel.fromJson` parses, **Then** an `UnImplementedFormModel` placeholder is returned and `getField()` renders `SizedBox.shrink()` instead of throwing.
4. **Given** the user pulls to refresh, **When** the gesture completes, **Then** `fetchFields(id, refresh: true)` runs and the form re-renders from the latest schema asset.
5. **Given** the user updates a field whose value chains to another field, **When** `updateForm(key, value)` runs, **Then** the **dependent field's value is dropped** if its dependency precondition no longer holds (see the [add_form_bloc.dart:86-91](../../lib/features/add_form/bloc/add_form_bloc.dart#L86-L91) `safeFirstWhere → removeWhere` block).

---

### User Story 2 - Save a completed form (Priority: P1)

A user fills out the form and taps Save. The form is validated by `Form.of(context).validate()`; on success the bloc routes to `saveForm` (default) or `saveMedicine` (medicine type) and constructs a multipart `FormData` body.

**Why this priority**: Save is the terminal action; without it the engine is read-only.

**Independent Test**:
1. Fill a medicine form end-to-end, tap Save.
2. `saveMedicine(id)` posts to `/parent/medicines` (POST) or `/parent/medicines/{id}` (PUT via `_method` body field).
3. On `Right(_)`, `AddFormSaveApiState.success = true` and the listener at [add_form_screen.dart:206-213](../../lib/features/add_form/add_form_screen.dart#L206-L213) fires `Snack`, `eventBus.fire(EventAdded())`, and `Navigator.pop(true)`.

**Acceptance Scenarios**:

1. **Given** all required fields have valid values, **When** the user taps Save, **Then** the Form validator passes and `saveForm` / `saveMedicine` is dispatched (medicine routes to `addMedicineRepo.saveMedicine`).
2. **Given** the form contains a `UploadFileParam` whose `url` does **not** start with `http`, **When** the request is built, **Then** the URL is wrapped in `MultipartFile.fromFile(url)` and uploaded ([add_form_repo.dart:198-200](../../lib/features/add_form/repo/add_form_repo.dart#L198-L200)).
3. **Given** an `AddFormType.event` submit, **When** the request is built, **Then** `receivers` is exploded into `audiences[child][i]`, `audiences[class][i]`, `audiences[level][i]`, `audiences[teacher][i]`, `audiences[parent][i]` keys, plus `all_parents=1` / `all_teachers=1` flags when the receiver list contains the sentinel `'all'` ([add_form_repo.dart:128-153](../../lib/features/add_form/repo/add_form_repo.dart#L128-L153)).
4. **Given** an `AddFormType.event` submit with a `starting_date` and `starting_time` pair, **When** the body is built, **Then** the two fields are concatenated to a single `start_date` (and likewise `end_date`) — [add_form_repo.dart:155-157](../../lib/features/add_form/repo/add_form_repo.dart#L155-L157).
5. **Given** a save failure, **When** the API returns `Left(Failure)`, **Then** `AddFormSaveApiState.failure` is populated and `ErrorSaveSection` renders the type-specific localized error key ([add_form_screen.dart:445-454](../../lib/features/add_form/add_form_screen.dart#L445-L454)).

---

### User Story 3 - Re-edit an existing entity (Priority: P2)

A user opens an entity by id (e.g., medicine id `42`) and the form pre-fills from the server payload.

**Why this priority**: Edit-existing is supported only for medicines today (`endpoint` for event/announcement is `''` in `fetchForm` — see [add_form_repo.dart:55-58](../../lib/features/add_form/repo/add_form_repo.dart#L55-L58)). Useful but not P1.

**Acceptance Scenarios**:

1. **Given** `AddFormType.medicine` and `id = '42'`, **When** the screen mounts, **Then** `fetchForm('42')` runs in parallel with `fetchFields()` via `Future.wait`, and the server's `payload` map is matched against `FormModel.id` to produce a `Map<FormModel, CreateFormParams>` ([add_form_repo.dart:60-103](../../lib/features/add_form/repo/add_form_repo.dart#L60-L103)).
2. **Given** the payload includes `attachment` / `uploadImage` entries, **When** they are parsed, **Then** each is wrapped in `UploadFileParam.fromJson` so the widget treats them as remote URLs (no upload).
3. **Given** the payload includes a `counter` value coming from JSON as a string, **When** parsed, **Then** `convertToDouble` normalizes it.
4. **Given** save is invoked with an `id`, **When** the FormData body is built, **Then** `_method: 'PUT'` is added so Laravel routes to update instead of create ([add_form_repo.dart:180](../../lib/features/add_form/repo/add_form_repo.dart#L180)).

---

### Edge Cases

- **Unimplemented `FormType` from server**: tolerated via `FormType.unimplemented` + `UnImplementedFormModel` placeholder; render is `SizedBox()`.
- **`fetchForm` for event / announcement**: endpoint is `''` — the network call goes to base URL, predictably fails, but the catch-all `fold` returns an empty `Map` so the screen still renders ([add_form_repo.dart:54-58](../../lib/features/add_form/repo/add_form_repo.dart#L54-L58), [add_form_repo.dart:84-86](../../lib/features/add_form/repo/add_form_repo.dart#L84-L86)). Wasted round-trip on every edit-mode open for non-medicine. See [tasks.md T-fix-3](tasks.md).
- **Hardcoded `/api/v1/` prefix in announcement endpoint** ([add_form_repo.dart:119](../../lib/features/add_form/repo/add_form_repo.dart#L119)) — `NetworkClient` already prepends the base URL, so the resolved URL becomes `https://criarte.filhos.app/api/v1/api/v1/teacher/announcements`. Either it's a bug or the server tolerates the double-prefix. See [tasks.md T-fix-1](tasks.md).
- **Dependency cascade is single-level**: `updateForm` only drops the field whose `dependency.id == key.id` once. A chain of dependencies (A → B → C) where A changes does **not** automatically drop C; `validateDependency` filters C out at render-time but the value lingers in `state.formState.data` until C's parent (B) also changes. Low-risk because hidden fields are filtered before submit ([add_form_bloc.dart:56](../../lib/features/add_form/bloc/add_form_bloc.dart#L56)).
- **`requiredTimeSelections` magic constant**: when `key.id == 'dose_number_id'` and value `'3'`, the bloc sets `requiredTimeSelections = 2`; otherwise `1`. This is medicine-form-specific business logic leaking into the generic engine ([add_form_bloc.dart:92-95](../../lib/features/add_form/bloc/add_form_bloc.dart#L92-L95)). Acceptable today; flagged.
- **`AttendantsSelectionSheet.open` on first frame**: if the user dismisses the sheet without selecting, the screen pops itself ([add_form_screen.dart:191](../../lib/features/add_form/add_form_screen.dart#L191)) — entering then immediately exiting is the canonical "back out" path.
- **No client-side validation summary**: `Form.of(context).validate()` returns false silently; individual fields show their own errors but there's no top-of-form summary. [features.md task](../features.md#add_form--b).
- **No autosave on back-press**: `state.formState.data` is in-memory only; navigating away loses everything. [features.md task](../features.md#add_form--b).
- **Approval gate**: reached only post-gate from settings / events tab / medicines tab.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support three `AddFormType` variants: `medicine`, `event`, `announcement` ([add_form_type.dart:1](../../lib/features/add_form/add_form_type.dart#L1)).
- **FR-002**: System MUST load the type-specific JSON schema from `assets/{medicines,events,announcements}_fields.json` at fetch time.
- **FR-003**: System MUST support the 18-variant `FormType` enum, mapping each to a concrete `FormModel` subclass and a render widget:

  | `FormType` | Model | Widget |
  |---|---|---|
  | `text` | [TextModel](../../lib/features/add_form/models/text_model.dart) | [TextFieldWidget](../../lib/features/add_form/widgets/text.dart) |
  | `textArea` | [TextAreaModel](../../lib/features/add_form/models/text_area_model.dart) | [TextAreaFieldWidget](../../lib/features/add_form/widgets/text_area.dart) |
  | `richText` | [RichTextModel](../../lib/features/add_form/models/rich_text_model.dart) | [RichTextFieldWidget](../../lib/features/add_form/widgets/rich_text.dart) |
  | `number` | [NumberModel](../../lib/features/add_form/models/number_model.dart) | [NumberFormFieldWidget](../../lib/features/add_form/widgets/number.dart) |
  | `counter` | [CounterModel](../../lib/features/add_form/models/counter_model.dart) | [CounterWidget](../../lib/features/add_form/widgets/counter.dart) |
  | `datePicker` | [DatePickerModel](../../lib/features/add_form/models/date_picker_model.dart) | [DatePickerWidget](../../lib/features/add_form/widgets/date_picker.dart) |
  | `timePicker` | [TimePickerModel](../../lib/features/add_form/models/time_picker_model.dart) | [TimePickerWidget](../../lib/features/add_form/widgets/time_picker.dart) |
  | `dropdown` | [DropDownModel](../../lib/features/add_form/models/dropdown_model.dart) | [DropDownWidget](../../lib/features/add_form/widgets/dropdown.dart) |
  | `multiselect` | [MultiSelectModel](../../lib/features/add_form/models/multiselect_model.dart) | [MultiSelect](../../lib/features/add_form/widgets/multiselect.dart) |
  | `segmented` | [SegmentedControlModel](../../lib/features/add_form/models/segmented_control_model.dart) | [SegmentedControlWidget](../../lib/features/add_form/widgets/segmented.dart) |
  | `periodOfTime` | [PeriodOfTimeModel](../../lib/features/add_form/models/period_of_time_model.dart) | [PeriodOfTimeWidget](../../lib/features/add_form/widgets/period_of_time.dart) |
  | `createMeetingButton` | [CreateMeetingButtonModel](../../lib/features/add_form/models/create_meeting_button_model.dart) | [CreateMeetingButton](../../lib/features/add_form/widgets/create_meeting_button.dart) |
  | `uploadImage` | [UploadImageModel](../../lib/features/add_form/models/upload_image_model.dart) | [UploadImageWidget](../../lib/features/add_form/widgets/upload_image.dart) |
  | `attachment` | [AttachmentsModel](../../lib/features/add_form/models/attachments_model.dart) | [AttachmentsWidget](../../lib/features/add_form/widgets/attachments.dart) |
  | `comments` | [CommentsModel](../../lib/features/add_form/models/comments_model.dart) | [CommentsWidget](../../lib/features/add_form/widgets/comments.dart) |
  | `attendantsSelection` | [AttendantsSelectionModel](../../lib/features/add_form/models/attendants_selection_model.dart) | (none — rendered via `AttendantsSelectionButton` driven by `attendantsController` in the screen) |
  | `collection` | [CollectionFormModel](../../lib/features/add_form/models/collection_model.dart) | [CollectionWidget](../../lib/features/add_form/widgets/collection.dart) (boxed group) |
  | `group` | [GroupFormModel](../../lib/features/add_form/models/group_model.dart) | [GroupWidget](../../lib/features/add_form/widgets/group.dart) (transparent group) |
  | `unimplemented` | `UnImplementedFormModel` | `SizedBox()` |

- **FR-004**: System MUST evaluate `FormDependencyModel { id, value }` against the live form state to gate the visibility and submission of dependent fields. The dependency relationship is a single string-equality predicate against the parent field's serialized value ([add_form_screen.dart:300-315](../../lib/features/add_form/add_form_screen.dart#L300-L315)).
- **FR-005**: System MUST drop a dependent field's value from form state when its parent's value changes such that the predicate would now fail (single-level cascade — [add_form_bloc.dart:86-91](../../lib/features/add_form/bloc/add_form_bloc.dart#L86-L91)).
- **FR-006**: System MUST support nesting via `CollectionFormModel` (rendered inside a `FormCard`) and `GroupFormModel` (rendered transparently). Both hold a `List<FormModel> items` that itself flows through `getFields()` recursively.
- **FR-007**: System MUST exclude hidden (dependency-failing) fields from the submit payload by filtering `form.entries.where((e) => validateDependency(e.key, form))` in `saveForm` / `saveMedicine` ([add_form_bloc.dart:56](../../lib/features/add_form/bloc/add_form_bloc.dart#L56)).
- **FR-008**: System MUST submit form bodies as `dio.FormData` (multipart). Files uploaded inline as `MultipartFile.fromFile(...)`; existing remote URLs (those starting with `http`) are preserved as strings.
- **FR-009**: System MUST switch between create and update by checking `id == null` and routing to POST or to POST + `_method: 'PUT'` ([add_form_repo.dart:180](../../lib/features/add_form/repo/add_form_repo.dart#L180)). (No PATCH; the server is a Laravel-style API.)
- **FR-010**: System MUST, for `AddFormType.event`, present an `AttendantsSelectionSheet` on first frame and pop the screen if the user dismisses without selecting attendants ([add_form_screen.dart:185-193](../../lib/features/add_form/add_form_screen.dart#L185-L193)).
- **FR-011**: System MUST, for `AddFormType.medicine` in the parents flavor, hydrate the children multiselect from `MyChildrenRepo.getChildren(1)` ([add_form_repo.dart:32-38](../../lib/features/add_form/repo/add_form_repo.dart#L32-L38)).
- **FR-012**: System MUST fire `eventBus.fire(EventAdded())` after a successful save so the home / events screens refresh.
- **FR-013**: System MUST hide all errors and validation messages behind `LocalizationKeys` — every visible string in the engine goes through `key.tr(context)`.
- **FR-014**: System MUST register `AddFormRepo` and `AddFormBloc` as named singletons / factories keyed by `AddFormType.name` ([di.dart:76-91](../../lib/core/dependency_injection/di.dart#L76-L91)) so each form-type entry point gets its own bloc instance with the right config.

### Localization Requirements

Localization keys referenced by the engine (non-exhaustive — widget-internal strings not audited):

| Key | Use site |
|---|---|
| `add_now`, `add_event`, `add_announcement` | screen titles per `AddFormType` |
| `error_fetch_prescriptions`, `error_fetch_events`, `error_fetch_announcements` | fetch-failure copy |
| `success_save_prescription`, `success_save_event`, `success_save_announcement` | save-success snack |
| `error_save_prescription`, `error_save_event`, `error_save_announcement` | save-failure copy |
| `select_attendants` | section header in event/announcement mode |
| `save` | CTA |

All bundled schema files store **localization keys** (not display strings) as their `title` / `hint` values — the widgets call `.tr(context)` on the title at render time ([forms.dart:34](../../lib/features/add_form/widgets/forms.dart#L34)). New form fields require adding the key to the JSON schema AND a translation in `assets/langs/{pt,en,ar}.json`.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `POST /parent/medicines` — create medicine. Body: multipart, fields per medicines schema (`children[]`, `name`, `dose`, …).
  - `POST /parent/medicines/{id}` + `_method=PUT` — update medicine.
  - `GET /parent/medicines/{id}` — read medicine for edit-mode pre-fill (parsed from `data.payload`).
  - `POST events/create` — create event. Body: multipart with `audiences[child|class|level|teacher|parent][N]`, `all_parents`, `all_teachers`, `title`, `description`, `start_date`, `end_date`, `has_approval`, `has_payment`, `is_feature`, `price`, `price_for_all_children`, `payment_info`, `image`, `images[N][url]`.
  - `POST /api/v1/teacher/announcements` — create announcement. Body: multipart. ⚠️ The `/api/v1/` prefix is hardcoded in addition to the `NetworkClient` base URL — see [tasks.md T-fix-1](tasks.md).
- **Bundled assets** (`rootBundle`):
  - [assets/medicines_fields.json](../../assets/medicines_fields.json)
  - [assets/events_fields.json](../../assets/events_fields.json)
  - [assets/announcements_fields.json](../../assets/announcements_fields.json)
- **No Firestore** use.
- **No FCM** use directly (downstream consumers like `events` may push).

### Permissions & Approval Gate

- Reached only post-approval (entry points are inside `MainScreen`).
- Device permissions:
  - **Camera / Photos / Storage** — when a `uploadImage` or `attachment` field is filled; permission requested by `lib/core/attachment_selection/`.

### Key Entities

- **`AddFormType`** ([add_form_type.dart](../../lib/features/add_form/add_form_type.dart)) — enum `{medicine, event, announcement}`. Drives endpoint selection, asset selection, child-list injection, and the auto-open attendants sheet.
- **`AddFormFormModel`** ([add_form_model.dart:23](../../lib/features/add_form/models/add_form_model.dart#L23)) — top-level wrapper of `List<FormModel> fields`.
- **`FormModel`** (abstract, [add_form_model.dart:66](../../lib/features/add_form/models/add_form_model.dart#L66)) — base class for all 18 typed fields. Carries `id`, `type`, `title`, `required`, `dependency`. `FormModel.fromJson` dispatches on `type` name to the concrete subclass; unknown types return `UnImplementedFormModel`.
- **`FormDependencyModel`** ([add_form_model.dart:144](../../lib/features/add_form/models/add_form_model.dart#L144)) — `{id, value}` pair. A field with `dependency: {id: "dose_number_id", value: "3"}` is visible iff the field with id `dose_number_id` currently has the value `"3"`.
- **`CreateFormParams`** ([params.dart:6](../../lib/features/add_form/models/params.dart#L6)) — `{type, value}` — what the bloc stores in `state.formState.data: Map<FormModel, CreateFormParams>`.
- **`UploadFileParam`** ([params.dart:32](../../lib/features/add_form/models/params.dart#L32)) — `{id?, url}` — represents either a remote attachment (URL starts with `http`) or a local file path (uploaded via `MultipartFile.fromFile` at submit).
- **`AddFormState`** ([add_form_state.dart:12](../../lib/features/add_form/bloc/add_form_state.dart#L12)) — composite of five sub-states: `formState`, `fetchApiState`, `saveApiState`, `addMedicineChildrenState`, `addMedicineFieldsState`. The two `addMedicine*` slices are medicine-specific concerns leaking into the generic state — see Gaps.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A teacher can compose a 12-field event (mixed types: text, datePicker, timePicker, dropdown, multiselect, uploadImage, attendantsSelection, comments) and submit in under 90 seconds.
- **SC-002**: A backend that adds a new `FormType` not yet known to the client renders the surrounding form correctly; the unknown field is skipped (`UnImplementedFormModel` → `SizedBox`).
- **SC-003**: With a 3-field dependency chain (A→B→C), changing A correctly hides B and C in the rendered tree, and excludes B and C from the submitted payload (verified by `validateDependency` filter on submit).
- **SC-004**: Save round-trip ≤ 3 s for text-only forms; image-heavy forms gated by network throughput.
- **SC-005**: An accidental double-tap of Save does not double-submit. **Currently violated** — `saveForm`/`saveMedicine` are bare async methods on a `Cubit`; no `droppable()` guard. See [tasks.md T-fix-2](tasks.md).

## Assumptions

- The bundled JSON schemas (`medicines_fields.json`, `events_fields.json`, `announcements_fields.json`) are kept in sync with backend expectations manually. There is no schema sync endpoint today.
- The backend accepts `_method: PUT` inside a POST FormData body as the Laravel update convention.
- Hidden (dependency-failing) fields are safe to exclude from the submit payload — the server does not require them to be sent explicitly as null.
- `AttendantsSelectionSheet` returns a `List<SchoolItem>` that includes sentinel types (`SchoolItemType.all`, `allChildType`, `allTeachersType`) which translate to `audiences[*]` flat keys / `all_*=1` flags on the server side.
- The hardcoded `/api/v1/` prefix in the announcement endpoint either works (server tolerates double prefix) or is a known bug — confirmation pending. See [tasks.md T-fix-1](tasks.md).
