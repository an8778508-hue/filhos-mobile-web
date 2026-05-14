---
status: migrated
feature: add_medicine
flavor_scope: parents
migrated_from: specs/features.md#add_medicine--p
migrated_date: 2026-05-14
---

# Feature Specification: Add Medicine

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/add_medicine/](../../lib/features/add_medicine/), the shared `add_form` engine, the alarm wrappers in `core/utils/alarm_manager/` + `core/custom_packages/native_alarm/`, and the [features.md `## add_medicine · P`](../features.md#add_medicine--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: parents (per features.md tag `· P`). Reached from the parent settings → medicines list ([medicine_screen.dart:121, 177](../../lib/features/settings/medicines/medicine_screen.dart#L121-L177)).
- **Flavor-conditional behavior**: alarm scheduling itself is **professor-side** (parents *register* medications; teachers receive the alarm via `AlarmManager.getAlarms(context)` which is gated by `context.isProfessors` in [alarm_manager.dart:21-26](../../lib/core/utils/alarm_manager/alarm_manager.dart#L21-L26)). The add/edit screen is parents-only; the resulting medication record drives alarms on the teacher-side device.
- **Server role implication**: `parent/medicines` REST endpoints — explicitly parent-namespaced ([add_medicine_repo.dart:18, 89](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L18-L89)).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Register a child medication (Priority: P1) 🎯 MVP

A parent opens settings → medicines → "+". The dynamic form engine (`AddFormBloc`, schema-driven) renders fields for: child, medicine name, dose, dose type, number of doses, time(s), instructions, period (AM/PM), starting date, period length, prescription image, comments. On save, `saveMedicine` POSTs to `parent/medicines` and the parent is returned to the medicines list.

**Why this priority**: This is the foundational write path for the medicines surface. Without it, schools have no formal record of what to administer.

**Independent Test**:
1. From the parents' medicines screen, tap "+" → `AddMedicineScreen(type: AddFormType.medicine)`.
2. Fill all required fields; attach a prescription image.
3. Tap Save → confirm `POST parent/medicines` fires with `FormData` body, success snack appears, navigator pops `true`, the medicines list refreshes.

**Acceptance Scenarios**:

1. **Given** a fresh form, **When** the screen mounts, **Then** a post-frame callback calls `AddFormBloc.fetchAddMedicineData(widget.id)` to load dropdown values (dose types, periods, instructions, time slots) ([add_medicine_screen.dart:147](../../lib/features/add_medicine/add_medicine_screen.dart#L147)).
2. **Given** the user submits with all required fields, **When** `SaveButton` triggers `AddFormBloc` save, **Then** `AddMedicineRepo.saveMedicine(form, id)` is called and `NetworkClient.handleRequest` POSTs `FormData` to `parent/medicines` (or `parent/medicines/{id}` on edit).
3. **Given** `saveApiState.success == true`, **When** the `BlocListener` fires, **Then** a success `Snack` shows, `eventBus.fire(EventAdded())` runs, and `Navigator.pop(true)` returns to the medicines list ([add_medicine_screen.dart:159-164](../../lib/features/add_medicine/add_medicine_screen.dart#L159-L164)).
4. **Given** the user picked a prescription image from device storage, **When** the form serializes, **Then** each non-`http` URL is wrapped in `MultipartFile.fromFile` under `images[i]` ([add_medicine_repo.dart:124-140](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L124-L140)).
5. **Given** the user is editing an existing record, **When** they reopen the screen with `medicineModel` / `medicineBodyModel` populated, **Then** every field's `initial:` is hydrated from those models ([add_medicine_screen.dart:220-353](../../lib/features/add_medicine/add_medicine_screen.dart#L220-L353)).

---

### User Story 2 - Schedule a native exact-time alarm (Priority: P1, teacher-side)

After the parent registers a medication, the teacher's device polls `getAlarms` and schedules a native exact-time alarm via the `alarm` package wrapped by [AlarmManager](../../lib/core/utils/alarm_manager/alarm_manager.dart). On Android 12+ the wrapper gates on `SCHEDULE_EXACT_ALARM` runtime permission, falling back to `USE_EXACT_ALARM` (auto-granted on API 33+ for medication-reminder use cases).

**Why this priority**: Without an exact alarm, the medication window can be missed by minutes-to-hours.

**Independent Test**:
1. As a teacher, ensure the `alarm` foreground service permissions are granted.
2. Trigger a refresh of `getAlarms(context)` (e.g., from `home_screen.dart:45`).
3. Confirm: a native alarm is set for the dose time; if `SCHEDULE_EXACT_ALARM` is denied, the wrapper logs and skips rather than silently demoting to inexact.

**Acceptance Scenarios**:

1. **Given** `Platform.isAndroid`, **When** `AlarmManager._ensureExactAlarmPermission` runs, **Then** it requests `Permission.scheduleExactAlarm` and returns the granted bool; if denied, logs `[AlarmManager] SCHEDULE_EXACT_ALARM not granted — skipping alarm` ([alarm_manager.dart:72-80](../../lib/core/utils/alarm_manager/alarm_manager.dart#L72-L80)).
2. **Given** `AndroidManifest.xml` declares the alarm foreground service + `USE_FULL_SCREEN_INTENT` + `USE_EXACT_ALARM` + `VIBRATE`, **When** an alarm fires while the app is in background, **Then** the native foreground service surfaces the notification.
3. **Given** the parent registers a medication for a future date, **When** the teacher's device polls `getAlarms`, **Then** the alarm is scheduled via `setAlarm(id, title, description, alarmDate)` using the localized title/description from `LocalizationKeys.medicine_notification_title` / `..._desc`.

---

### Edge Cases

- **iOS 17+ / Android 14 app-kill survival**: alarms may not fire if the OS aggressively terminates the app. Per [features.md `add_medicine` P1](../features.md#add_medicine--p), this is **not yet verified**. The native foreground service helps on Android; iOS relies on `flutter_local_notifications` scheduled triggers and is more fragile.
- **`SCHEDULE_EXACT_ALARM` denied + `USE_EXACT_ALARM` not granted**: the wrapper logs and skips ([alarm_manager.dart:78](../../lib/core/utils/alarm_manager/alarm_manager.dart#L78)). The user has no UI feedback that their reminder won't fire — gap.
- **Image is already a `http(s)` URL (re-edit case)**: the repo sends it as `{url, id}` JSON object rather than re-uploading ([add_medicine_repo.dart:130-136](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L130-L136)).
- **Multipart for native files**: each local file becomes its own `MultipartFile.fromFile` under `images[i]`.
- **PII / CPF redaction in Crashlytics**: medication name + dose + child name are sensitive. The [NetworkClient._redactBody](../../lib/core/network/network_client.dart) sweep added `medication`, `cpf`, `phone` keys to redaction (per features.md (P0) "Audit Crashlytics logging — medication / CPF / phone keys redacted").
- **Prescription image at rest**: stored in the app's image cache (via `image_picker` → temp). features.md flags "Encrypt prescription images at rest" as a follow-up.
- **Stray debug `print`** in [add_medicine_screen.dart:188, 191](../../lib/features/add_medicine/add_medicine_screen.dart#L188-L191) — leaks form contents to device logs. Cleanup.
- **Two commented-out save implementations** in [add_medicine_repo.dart:32-87, 97-123](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L32-L123) — dead code from earlier iterations. Remove.
- **Starting date defaults to "tomorrow"**: `min: DateTime.now().add(const Duration(days: 1))` and initial value matches ([add_medicine_screen.dart:317-319](../../lib/features/add_medicine/add_medicine_screen.dart#L317-L319)). Today's medication cannot be registered.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render the add/edit medicine form via the shared `AddFormBloc` engine using `AddFormType.medicine`.
- **FR-002**: System MUST hydrate dropdown values (dose types, dose counts, instructions, periods, time slots) by calling `AddFormBloc.fetchAddMedicineData(id)` on first frame.
- **FR-003**: System MUST require these fields: `child_id`, `name`, `dose`, `dose_type_id`, `dose_number_id`, `tempo`, `instruction_id`, `period_id`, `starting_date`, `period_time`, `images`. `notes` is optional.
- **FR-004**: System MUST `POST parent/medicines` for new records and `POST parent/medicines/{id}` for edits, with a `FormData` body.
- **FR-005**: System MUST serialize prescription images such that:
  - Network URLs (`http*://...`) → `images[i] = {url, id?}` JSON object.
  - Local file URLs → `images[i] = MultipartFile.fromFile(url)`.
- **FR-006**: System MUST fire `eventBus.fire(EventAdded())` on save success so listening features (medicines list) can refetch.
- **FR-007**: System MUST localize and surface a success Snack on save.
- **FR-008**: System MUST gate native exact-alarm scheduling on Android via `Permission.scheduleExactAlarm` runtime check, skipping (not demoting) when denied.
- **FR-009**: System MUST declare the alarm foreground service in `AndroidManifest.xml` per [features.md (P0)](../features.md#add_medicine--p) — `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `USE_FULL_SCREEN_INTENT`, `USE_EXACT_ALARM`, `VIBRATE`. *Fixed 2026-05-14.*
- **FR-010**: System MUST redact `medication` / `cpf` / `phone` keys in Crashlytics breadcrumbs via [NetworkClient._redactBody](../../lib/core/network/network_client.dart). *Fixed 2026-05-14.*
- **FR-011**: System MUST persist the alarm IDs locally via `LocalDatabaseRepo` key `alarm_ids` so they can be removed/replaced cleanly ([alarm_manager.dart:43, 49](../../lib/core/utils/alarm_manager/alarm_manager.dart#L43-L49)).

### Localization Requirements

| Key | Use site |
|---|---|
| `determine_child` | Child dropdown title + hint |
| `medicine_name` | Medicine-name field |
| `determine_dose` | Dose counter |
| `choose_dose`, `please_choose_dose` | Dose-type dropdown |
| `number_of_doses`, `select_number` | Dose-count dropdown |
| `time`, `select_time` | Time picker |
| `instructions` | Instructions segmented control |
| `hour` | Period (AM/PM) segmented control |
| `starting_date`, `select_date` | Date picker |
| `period_time` | Period-length counter |
| `attach_copy_of_recipe`, `attach_copy_of_recipe_desc` | Prescription image upload |
| `comments` | Free-text notes |
| `medicine_notification_title`, `medicine_notification_desc` | Native alarm title / description |

Translations live in `assets/langs/{en,pt,ar}.json` with the cross-feature i18n caveat for `ar.json`.

### Backend Touchpoints

- **REST** (via `NetworkClient.handleRequest`):
  - `GET parent/medicines/items/types` → dropdown values (dose types, number-of-doses, time slots, instructions, periods).
  - `POST parent/medicines` (new) / `POST parent/medicines/{id}` (edit) with `FormData` body. **No `_method: PUT` override is used** — the server appears to accept POST for edits.
- **Native alarm**: the `alarm` package + a custom wrapper at [core/custom_packages/native_alarm/](../../lib/core/custom_packages/native_alarm/). `AlarmManager` reads alarms via [AlarmRepo](../../lib/core/utils/alarm_manager/alarm_repo.dart), persists IDs to Hive, and calls `setAlarm` for each.
- **No Firestore** in this feature.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **Yes** — only reachable from the parents' settings/medicines screen which is past the gate.
- Device permissions:
  - **Image picker**: photos / camera (handled by `image_picker` via the shared `UploadImage` field).
  - **Schedule exact alarm** (Android 12+): runtime, requested by `AlarmManager._ensureExactAlarmPermission`.
  - **Foreground service** (Android): declared in manifest, not runtime-prompted.
  - **Full-screen intent** (Android 14+): declared in manifest.
  - iOS: relies on `flutter_local_notifications` scheduling + the alarm package's iOS shim; **survival under app-kill not yet validated** — see Gaps.

### Key Entities

- **`AddMedicineRepo`** ([repo](../../lib/features/add_medicine/repo/add_medicine_repo.dart)) — `fetchMedicineFields()`, `saveMedicine(form, id?)`. Returns `Either<Failure, ...>` via `NetworkClient.handleRequest`.
- **`AddMedicineScreen`** ([screen](../../lib/features/add_medicine/add_medicine_screen.dart)) — thin wrapper that provides `AddFormBloc` (instanced by `AddFormType.name`) and routes to `AddFormBody` which builds the form.
- **`MedicineModel`** / **`MedicineBodyModel`** (shared with `settings/medicines/`) — populate `initial:` values on edit.
- **`AddFormBloc`** (shared engine) — fields per `FormModel` type (DropDown, Counter, PeriodOfTime, SegmentedControl, DatePicker, UploadImage, Comments).
- **`AlarmManager`** ([core](../../lib/core/utils/alarm_manager/alarm_manager.dart)) — schedules native alarms (teacher-side execution).
- **`UploadFileParam`** — `{id?, url}` for images; URL may be local or http.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent can register a new medication in under 60 seconds (with a pre-cropped prescription image) on a 4G connection.
- **SC-002**: On a stock Android 14 device with `SCHEDULE_EXACT_ALARM` granted, the registered alarm fires within ±60s of the dose time, even with the app backgrounded.
- **SC-003**: On Android 12+ with permission denied, the wrapper does not silently schedule an inexact alarm — it logs and skips (verified by absence of system-alarm row).
- **SC-004**: Crashlytics breadcrumbs of `POST parent/medicines` contain redacted values for the `medication`, `cpf`, and `phone` keys.
- **SC-005**: Editing an existing record correctly re-uploads only the locally-changed images; previously-uploaded images travel as `{url, id}` JSON.

## Assumptions

- The server accepts plain `POST parent/medicines/{id}` for edits (no `_method: PUT` envelope).
- The `alarm` package's iOS shim survives `applicationWillTerminate`. *Per [features.md `add_medicine` P1](../features.md#add_medicine--p), this is **not yet verified** on iOS 17+ / Android 14.*
- The teacher-side device polls `getAlarms` frequently enough to pick up newly-registered medications (today only from `home_screen.dart:45`). If the teacher never opens home, the parent-side registration won't surface as an alarm.
- The `parent/medicines/items/types` endpoint returns enough data to construct every dropdown / picker — if a new dose-type is added server-side, no app update is required.
- The `image_picker` returns paths that `MultipartFile.fromFile` can read directly (true on Android + iOS today).
- Tomorrow's-or-later constraint on `starting_date` matches the school's business rule (alarms cannot be scheduled in the past).
