---
status: migrated
feature: add_medicine
migrated_from: specs/features.md#add_medicine--p
migrated_date: 2026-05-14
---

# Tasks: Add Medicine

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#add_medicine--p](../features.md#add_medicine--p).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

## Migration summary

- 2 .dart files in this feature (`add_medicine_screen.dart`, `repo/add_medicine_repo.dart`).
- Heavy reuse of the shared `add_form/` engine; alarm execution lives in `core/utils/alarm_manager/` + `core/custom_packages/native_alarm/`.
- DI registration in [core/dependency_injection/di.dart:80-82](../../lib/core/dependency_injection/di.dart#L80-L82).
- Mount sites: [medicine_screen.dart:121, 177](../../lib/features/settings/medicines/medicine_screen.dart#L121-L177) (edit + create).
- P0 hardening landed 2026-05-14: manifest foreground service + exact-alarm permission gating + Crashlytics redaction.

## Phase 1: Setup — ✅ Complete

- [x] **T-001**: Create `lib/features/add_medicine/` with `repo/`.
- [x] **T-002**: Register `AddMedicineRepo` as a `Singleton` in DI.
- [x] **T-003**: Register `AddFormBloc` factory keyed by `AddFormType.name` (for `medicine`).

## Phase 2: User Story 1 — Register child medication (P1) — ✅ Complete

- [x] **T-010**: Implement `AddMedicineRepo.fetchMedicineFields()` → `Either<Failure, List<Map>>` against `GET parent/medicines/items/types`.
- [x] **T-011**: Implement `AddMedicineRepo.saveMedicine(form, id?)` building a multipart `FormData` body: network URLs → JSON `{url, id?}`, local files → `MultipartFile.fromFile`.
- [x] **T-012**: Wire `AddMedicineScreen` → `AddFormBloc(instanceName: 'medicine')` → `AddFormBody`.
- [x] **T-013**: Schema-drive form sections: child, name, dose, dose-type, dose-count, time, instructions, period, starting date, period length, prescription image, notes.
- [x] **T-014**: Hydrate `initial:` values from `medicineModel` / `medicineBodyModel` on edit.
- [x] **T-015**: On save success: snack + `eventBus.fire(EventAdded())` + `Navigator.pop(true)`.

## Phase 3: User Story 2 — Native exact-alarm scheduling (P1) — ✅ Complete (P0 hardening)

- [x] **T-020** **(P0)** **(from [features.md `add_medicine` P0](../features.md#add_medicine--p))** Declare the alarm package's foreground service in `AndroidManifest.xml`. *Fixed 2026-05-14: added `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `USE_FULL_SCREEN_INTENT`, `USE_EXACT_ALARM`, `VIBRATE`.*
- [x] **T-021** **(P0)** **(from [features.md `add_medicine` P0](../features.md#add_medicine--p))** Gate `SCHEDULE_EXACT_ALARM` at runtime + `USE_EXACT_ALARM` fallback. *Fixed 2026-05-14: `AlarmManager._ensureExactAlarmPermission` requests via `permission_handler`, skips with a log if denied.*
- [x] **T-022** **(P0)** **(from [features.md `add_medicine` P0](../features.md#add_medicine--p))** Audit Crashlytics logging — medication / CPF / phone keys redacted. *Fixed 2026-05-14 in `network_client._redactBody`.*

## Phase 4: Gaps & cleanups

### Constitution drift fixes

- [ ] **T-fix-1** [P1] **Carry-over from [features.md `add_medicine` P1](../features.md#add_medicine--p)**: "Verify alarms survive app-kill on iOS 17+ and Android 14." Manual QA on the latest OS versions of each, including swipe-from-recents and battery-optimizer impact. If a regression surfaces on iOS, consider migrating to a `UNUserNotificationCenter` time-trigger which is more app-kill-resilient than the `alarm` package's iOS shim.

- [ ] **T-fix-2** [P2] **Carry-over from [features.md `add_medicine`](../features.md#add_medicine--p)**: "Encrypt prescription images at rest (or restrict to memory cache)." Prescription images today land in the temp dir via `image_picker` and stay until the OS clears the cache. Options:
  - Restrict to memory-only `Image.memory` for the preview surface.
  - Encrypt the temp file with `flutter_secure_storage`-derived key.
  - Don't keep a local copy at all — upload-then-discard.

- [ ] **T-fix-3** [P2] Surface a UI hint when `SCHEDULE_EXACT_ALARM` is denied — today the wrapper just logs ([alarm_manager.dart:78](../../lib/core/utils/alarm_manager/alarm_manager.dart#L78)). Teachers / parents have no way of knowing alarms won't fire. Either an in-app banner or a one-time dialog directing to system settings.

- [ ] **T-fix-4** [P2] Extract DI registration into `lib/features/add_medicine/add_medicine_di.dart` implementing `DependencyInjection`. Mechanical move from `core/dependency_injection/di.dart`.

- [ ] **T-fix-5** [P3] Allow same-day registration if the chosen dose time is in the future. Today `starting_date.min = DateTime.now() + 1 day` blocks the most common "I forgot to register this until lunch" case.

### Code hygiene

- [ ] **T-cleanup-1** Delete the two commented-out `saveMedicine` blocks in [add_medicine_repo.dart:32-87, 97-123](../../lib/features/add_medicine/repo/add_medicine_repo.dart#L32-L123). They are dead code.

- [ ] **T-cleanup-2** Remove `print('_AddFormBodyState.build 1 ...')` and `print(Map.fromEntries(...))` in [add_medicine_screen.dart:188-191](../../lib/features/add_medicine/add_medicine_screen.dart#L188-L191). Form contents leak to device logs. Part of the cross-feature [logger task](../features.md#cross-feature-tasks).

- [ ] **T-cleanup-3** Confirm whether the snake_case identifiers (`number_of_doses`, `period_of_time`, etc.) in [medicine_body_model.dart](../../lib/features/settings/medicines/models/medicine_body_model.dart) are required by the server contract. If not, rename to camelCase Dart-side.

### Tests (aspirational)

- [ ] **T-test-1** [P] Repo test for `saveMedicine`: mixed local + network images → correct multipart shape; only-network → no `MultipartFile` calls.
- [ ] **T-test-2** [P] Widget test for the form: required-field validators block submission.
- [ ] **T-test-3** Integration test for the alarm wrapper: schedule, advance system clock, verify fire (Android only; iOS infeasible in CI).
- [ ] **T-test-4** Crashlytics breadcrumb test: confirm `medication`, `cpf`, `phone` keys redacted in the `POST parent/medicines` body.

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-cleanup-* — no new warnings.
- [ ] **TX02** [X] On a real Android 14 device, validate that an alarm registered today fires at the chosen time tomorrow, with the app backgrounded.
- [ ] **TX03** [X] On a real iOS 17+ device, validate the same scenario, including after a force-quit. *This is the P1 task T-fix-1.*

## Dependencies & Execution Order

- **Phases 1–3 are complete (including P0 hardening).**
- **Phase 4** order:
  1. T-cleanup-1 / T-cleanup-2 (mechanical cleanups) — first.
  2. T-fix-1 (iOS 17+ / Android 14 survival) — manual QA + potential migration.
  3. T-fix-3 (denied-permission UI) — UX fix.
  4. T-fix-2 (prescription image encryption) — security follow-up.
  5. T-fix-4 / T-fix-5 — housekeeping.

## Constitution drift fixes (summary table)

| Drift | Source | Status |
|---|---|---|
| Manifest foreground service | features.md P0 | ✅ Fixed 2026-05-14 |
| `SCHEDULE_EXACT_ALARM` runtime gate | features.md P0 | ✅ Fixed 2026-05-14 |
| Crashlytics redaction of `medication` / `cpf` / `phone` | features.md P0 | ✅ Fixed 2026-05-14 |
| iOS 17+ / Android 14 survival not verified | features.md P1 | Open (T-fix-1) |
| Prescription image at rest unencrypted | features.md | Open (T-fix-2) |
| DI registration not in `add_medicine_di.dart` | this migration | Open (T-fix-4) |
| Two dead `saveMedicine` blocks | this migration | Open (T-cleanup-1) |

## Gaps found

- **iOS 17+ / Android 14 alarm survival is unverified** and is the most important open risk for this feature.
- **Denied `SCHEDULE_EXACT_ALARM` is silent to the user** — they lose a reminder without knowing.
- **Prescription images linger in the OS temp dir** — potential LGPD concern if the device is shared / backed up unencrypted.
- **No teacher-side push acknowledgement** — when an alarm fires, there is no confirmation flow ("administered: yes/no/skipped") routed back to the parent. Out of this feature's scope but worth flagging if Filhos plans an audit-trail feature.
- **`alarm_ids` is a flat list across users** — if the teacher device serves multiple classes / users, the same key could be overwritten. Verify if `LocalDatabaseRepo`'s scoping covers this.
