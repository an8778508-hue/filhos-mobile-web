---
status: migrated
feature: settings/edit_profile
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: Edit Profile

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/edit_profile/](../../../lib/features/settings/edit_profile/) with `bloc/`, `repo/`, `models/`, `widgets/`.
- [x] T002 Add localization keys (`my_information`, `name`, `email`, `cpf`, `title`, `male`, `female`, `save`, `profile_updated_successfully`).
- [x] T003 Register `EditProfileBloc` factory + `EditProfileRepo` singleton in [lib/core/dependency_injection/di.dart](../../../lib/core/dependency_injection/di.dart) (lines 70, 106).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `EditProfileEvents` (`FetchEditProfileEvent`, `SubmitEditProfileEvent`) and `EditProfileStates` (`Initial/Loading/Fetched/Success/Error`).
- [x] T011 Define `TitleModel`, `ClassModel`, `EmailModel`, `PhoneModel`, `StateModel` in `models/`.
- [x] T012 Implement `EditProfileRepo.updateProfile` (multipart `POST /auth/profile` with `method: PUT` header override) and `getTitles` (`GET teacher/titles`).

## Phase 3: User Story 1 — Edit and save profile (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Build the form in [edit_profile_screen.dart](../../../lib/features/settings/edit_profile/edit_profile_screen.dart) with name / email / phone (+ country picker) / avatar.
- [x] T021 [US1] Prefill from `UserBloc.get.state.user` on `initState`.
- [x] T022 [US1] Wire `FetchEditProfileEvent` to call `getTitles()` only when `isCurrentUserProfessor`.
- [x] T023 [US1] Wire avatar picker via `showAttachmentSelectionBottomSheet` + `chooseImage` (crop).
- [x] T024 [US1] Wire `SubmitEditProfileEvent` → `EditProfileRepo.updateProfile` → success snackbar + `Navigator.pop`.
- [x] T025 [US1] On `SuccessEditProfileState`, call `di<UserBloc>().getUserData()` to refresh persisted user.
- [x] T026 [US1] **(P0)** Replace any role-branching via `mainKey.currentContext` with `isCurrentUserProfessor` / `context.isProfessors`. *Fixed 2026-05-14 per [features.md#settings--b](../../features.md#settings--b) — the endpoint is identical for both roles so the branch is gone.*

---

## Phase 4: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P2)** *(from [features.md#settings--b](../../features.md#settings--b))* Confirm `UserModel.getPercentage()` matches the fields actually edited on this screen. Today the helper enumerates a fixed field list; if those drift from the form, the `CompleteProfileCard` percentage is wrong.

- [ ] **T-fix-2** **(P2)** Re-enable phone-format validation. Both the primary `PhoneField` and the (currently disabled) secondary `PhoneField` have their `validateMobile` checks commented out ([edit_profile_screen.dart:260-262, 451-455](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L260-L262)). Either remove the comments or delete the validator slot entirely.

- [ ] **T-fix-3** **(P2)** Fix the email field's `hint` — it's `LocalizationKeys.user_name` but should be `LocalizationKeys.email_hint` (or similar) ([edit_profile_screen.dart:326](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L326)).

- [ ] **T-fix-4** **(P3)** Decide on the `if (isProfessors && false)` extras block (external phones + external emails + class multi-select). Either re-enable behind a real config flag or delete.

- [ ] **T-fix-5** **(P3)** Decide on the CPF block (commented out at [edit_profile_screen.dart:361-376](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L361-L376)). Even with the UI gone, the body still sends `cpf` + `cpf_num` — consistent but invisible.

### Constitution drift fixes

- [ ] **T-fix-6** **(P2)** Replace `Colors.transparent` / `Colors.white` literals on the `PhoneField`, `Avatar` border, and `SelectableField` background ([edit_profile_screen.dart:267-268, 405, 417](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L267-L268)) with `context.colors.*` equivalents.

### Code hygiene

- [ ] **T-cleanup-1** Replace hardcoded color literals (T-fix-6 covers this).
- [ ] **T-cleanup-2** Remove unused `SelectCountry` / `SelectCity` / `SelectRegion` events from [edit_profile_events.dart](../../../lib/features/settings/edit_profile/bloc/edit_profile_events.dart). They are never dispatched.
- [ ] **T-cleanup-3** Delete commented-out blocks in [edit_profile_screen.dart](../../../lib/features/settings/edit_profile/edit_profile_screen.dart):
  - lines 361-376 (CPF section)
  - lines 425-548 (external contacts + class multi-select)
  - lines 518-548 (commented MultiSelectWidget)
- [ ] **T-cleanup-4** Decide: real `HttpMethod.put` instead of `POST` + `method: PUT` header in [edit_profile_repo.dart:35-38](../../../lib/features/settings/edit_profile/repo/edit_profile_repo.dart#L35-L38). Coordinate with backend.
- [ ] **T-cleanup-5** Remove `print('_EditProfileScreenState.initControllers …')` ([edit_profile_screen.dart:655](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L655)), `print('_EditProfileScreenState.build $secondaryPhoneController.text')` ([line 433-436](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L433-L436)), and `print('EditProfileBloc.EditProfileBloc $l')` ([edit_profile_bloc.dart:79](../../../lib/features/settings/edit_profile/bloc/edit_profile_bloc.dart#L79)). Part of the repo-wide logger task.

### Tests (aspirational)

- [ ] **T-test-1** [P] Bloc test: `FetchEditProfileEvent` triggers `getTitles()` only for teachers.
- [ ] **T-test-2** [P] Bloc test: `SubmitEditProfileEvent` failure emits `ErrorEditProfileState` with the failure message.
- [ ] **T-test-3** [P] Widget test: success snackbar appears + screen pops after `SuccessEditProfileState`.

---

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze` after T-cleanup-* — no new warnings expected.
- [ ] **TX02** Verify on both flavors that the form fields render correctly (gender + title appear only for teachers).

---

## Gaps Found

- **`UserModel.getPercentage()` correctness** is unverified — known from features.md.
- **Phone validator disabled** — users can save garbage phone numbers.
- **Email hint copy-paste bug** (uses `user_name` key).
- **Dead UI**: external-contact + class blocks live under `&& false`.
- **`print` calls** in screen + bloc.

## Notes

- Repo's `getClasses()` method is implemented but no longer called (the multi-select UI is commented out).
- `EditProfileBloc` is a `Bloc`, not a `Cubit`, even though it has only two event types — consistent with sibling `MyChildrenBloc` and `MedicinesBloc`.
