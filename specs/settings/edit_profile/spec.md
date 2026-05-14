---
status: migrated
feature: settings/edit_profile
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: Edit Profile

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/edit_profile/](../../../lib/features/settings/edit_profile/) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**:
  - **Teachers-only fields** (`isProfessors`): gender selector ([edit_profile_screen.dart:333-357](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L333-L357)), title selector ([edit_profile_screen.dart:379-424](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L379-L424)), and an extras block guarded by `if (isProfessors && false)` for external phone/email + class multi-select (currently dead code).
  - Teacher-only data prefetch in the bloc: `getTitles()` is only called when `isCurrentUserProfessor` ([edit_profile_bloc.dart:36-43](../../../lib/features/settings/edit_profile/bloc/edit_profile_bloc.dart#L36-L43)).
- **Server role implication**: identical endpoint for both roles — `POST /auth/profile` with `method: PUT` header override. Server routes by token / role ([edit_profile_repo.dart:14-15](../../../lib/features/settings/edit_profile/repo/edit_profile_repo.dart#L14-L15)). Fixed 2026-05-14 (no `mainKey.currentContext` role branch).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edit and save my profile (Priority: P1) 🎯 MVP

A signed-in user opens "My information", edits any of name / email / phone / avatar (plus gender + title for teachers), and taps Save.

**Why this priority**: Profile completeness drives the `CompleteProfileCard` on Settings and many downstream personalizations. Required for both flavors.

**Independent Test**:
1. From Settings, tap `my_information`.
2. Confirm fields prefill with `UserBloc.get.state.user`.
3. Change a field.
4. Tap Save.
5. Confirm a success `SnackBar` appears and the screen pops.
6. Re-open and confirm the change persisted.

**Acceptance Scenarios**:

1. **Given** an authenticated user, **When** the screen mounts, **Then** `FetchEditProfileEvent` fires and (for teachers) `getTitles()` is called to populate the title chooser ([edit_profile_bloc.dart:25-59](../../../lib/features/settings/edit_profile/bloc/edit_profile_bloc.dart#L25-L59)).
2. **Given** the user changes their name and taps Save, **When** the form validates, **Then** `SubmitEditProfileEvent` posts `FormData` to `/auth/profile` (with `method: PUT` header override).
3. **Given** the save succeeds, **When** `SuccessEditProfileState` emits, **Then** a success `SnackBar` shows `profile_updated_successfully` and the screen pops. Before popping, `UserBloc.getUserData()` re-fetches the user.
4. **Given** the user picks a new avatar via `showAttachmentSelectionBottomSheet`, **When** they choose camera/gallery, **Then** `chooseImage` (with `crop_your_image`) returns an `XFile` that's submitted as a `MultipartFile` under the `avatar` field.
5. **Given** the user is a teacher and selects a title, **When** they save, **Then** `title_id` is included in the form data. (Gender → `gender`.)
6. **Given** a server failure, **When** `ErrorEditProfileState(error)` emits, **Then** an `ErrorField` renders the message above the form.

### Edge Cases

- **Phone field stripping**: the controller is initialized by stripping `+` and the country dial code from `user.phone` ([edit_profile_screen.dart:660-661](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L660-L661)). If the user's stored phone has a different country code than `country.value.phoneCode`, the strip leaves the dial code visible.
- **CPF field is rendered but `isBrazil` gate is commented out** ([edit_profile_screen.dart:361-376](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L361-L376)) — CPF is always sent in the body (`'cpf'` and `'cpf_num'`) regardless of country.
- **Mobile validator is commented out** ([edit_profile_screen.dart:260-262](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L260-L262), 451-455) — only an empty check is enforced. Invalid phone formats can be submitted.
- **`if (isProfessors && false)`** block: external phones/emails + class multi-select are wired but disabled via the literal `false`. Dead UI but server submit fields still serialize empty arrays.
- **`completedProfile()` percentage check** comes from `UserModel.getPercentage()` — **[NEEDS CLARIFICATION]** confirm this matches actual fields the screen edits (flagged in [features.md#settings--b](../../features.md#settings--b)).
- **Hint text mismatch**: the email field's `hint` is `user_name` ([edit_profile_screen.dart:326](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L326)) — copy-paste bug.
- **Title list emptied at hot reload**: `titles` is a `ValueNotifier` on the bloc; navigating away and back re-fetches. Acceptable.
- **`debugPrint` and `print(...)` calls scattered**: see tasks.md T-cleanup.
- **Approval gate**: profile editing is reached only from Settings (already inside `MainScreen`); gate enforced upstream.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST prefill name, email, phone (with country code), CPF, gender (teacher), title (teacher), avatar from `UserBloc.get.state.user`.
- **FR-002**: System MUST validate `name`, `email`, `phone` as non-empty (text validators only — phone format check is disabled today).
- **FR-003**: System MUST submit changes via `POST /auth/profile` with the header `method: PUT` to spoof a PUT request through proxy infrastructure.
- **FR-004**: System MUST accept an avatar image (`XFile`) selected via the shared `showAttachmentSelectionBottomSheet` and submit it as a `MultipartFile`.
- **FR-005**: System MUST, for teachers, fetch the title list via `GET teacher/titles` on screen mount.
- **FR-006**: System MUST, on success, call `UserBloc.getUserData()` so other features see the fresh profile.
- **FR-007**: System MUST surface a success `SnackBar` with `profile_updated_successfully` and pop the screen.
- **FR-008**: System MUST surface an `ErrorField` above the form with the server message on `ErrorEditProfileState`.
- **FR-009**: System MUST use `FormData` (multipart) for all profile submits, even when no avatar is attached — extra fields (`phones`, `emails`, `cpf`, `gender`, `title_id`) are serialized as form fields.

### Localization Requirements

| Key | Use site |
|---|---|
| `my_information` | screen title |
| `name`, `user_name` | name field |
| `email` | email field title |
| `cpf` | CPF field title (commented out today) |
| `title` | teacher title selector |
| `male`, `female` | gender buttons |
| `external_phone`, `add_phone`, `external_email`, `add_email` | (dead) extras block |
| `professor_class` | (commented) class multi-select |
| `save` | submit button |
| `this_field_cant_be_empty` | required-field validator |
| `this_is_not_a_valid_mobile` | (commented) mobile validator |
| `profile_updated_successfully` | success SnackBar |

No new keys required.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `POST /auth/profile` (headers: `method: PUT`) — update profile. Body: multipart `FormData` with `name, email, phone, phones[], emails[], cpf, cpf_num, gender?, title_id?, avatar?`.
  - `GET teacher/titles` — list of `TitleModel` for the title dropdown.
  - `GET schools/{schoolId}/classes` — classes list (commented out / unused today).
- **Headers**: standard `Authorization` / `school_id` / `lang` added by [NetworkInterceptor](../../../lib/core/network/network_interceptor.dart).
- **Firebase**: not used.
- **Firestore**: not used.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit via Settings → MainScreen).
- Device permissions: **camera + photo library** to pick a new avatar via `showAttachmentSelectionBottomSheet`.

### Key Entities

- **`TitleModel`** ([title_model.dart](../../../lib/features/settings/edit_profile/models/title_model.dart)) — teacher job titles (id + name).
- **`ClassModel`** ([class_model.dart](../../../lib/features/settings/edit_profile/models/class_model.dart)) — class assignments. Currently fetched only via commented `getClasses()` path.
- **`EmailModel`** / **`PhoneModel`** / **`StateModel`** — auxiliary structures in `models/`. `EmailModel` / `PhoneModel` map external-contact items.
- **`UserModel`** (shared) — source-of-truth for prefill and re-hydrate via `UserBloc.getUserData()`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can edit name + email + avatar and see the changes persisted across cold start in under 60 seconds.
- **SC-002**: The `UserBloc` is rehydrated after every successful save (verified via `getUserData()` call in [edit_profile_bloc.dart:83](../../../lib/features/settings/edit_profile/bloc/edit_profile_bloc.dart#L83)).
- **SC-003**: Both flavors save successfully against the identical `/auth/profile` endpoint without a `role` body field (server routes by token).
- **SC-004**: Teacher's title selection round-trips through save → re-fetch → re-display.

## Assumptions

- Server accepts the `method: PUT` header override and treats the request as a PUT.
- `UserModel.getPercentage()` matches the fields edited on this screen (open per [features.md](../../features.md#settings--b)).
- `country.value.phoneCode` matches the user's stored country code at first render (or the strip leaves a corrupted prefix).
- The disabled `if (isProfessors && false)` extras block is intentional dead code pending a product decision on external contacts.
