---
status: migrated
feature: settings/edit_profile
migrated_from: lib/features/settings/edit_profile/
migrated_date: 2026-05-14
---

# Implementation Plan: Edit Profile

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/edit_profile/spec.md](spec.md) and code in [lib/features/settings/edit_profile/](../../../lib/features/settings/edit_profile/).

## Summary

Edit Profile is a form-based screen backed by `EditProfileBloc` (a `Bloc`, not a `Cubit`). It fetches teacher titles on mount, submits a multipart `FormData` to `/auth/profile`, and on success refreshes `UserBloc` so the rest of the app sees the new profile. Flavor differences: teachers see gender + title selectors and (commented today) external-contact + class multi-select fields.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `EditProfileBloc extends Bloc<EditProfileEvents, EditProfileStates>`.
- `dio` — `FormData` + `MultipartFile` for multipart submit.
- `dartz` — `Either<Failure, void>` / `Either<Failure, List<TitleModel>>`.
- `image_picker` — avatar pick.
- `crop_your_image` (via [choose_image.dart](../../../lib/features/settings/edit_profile/choose_image.dart)).
- `country_picker` — country dial code for the phone field.
- `brasil_fields` — CPF formatter (currently not invoked because the CPF section is commented).
- `flutter_screenutil` — sizing.
- `get_it` — `di<EditProfileBloc>` factory.

**Storage**: none directly. Reads/writes `UserBloc` (HydratedCubit).

**Testing**: none.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature with bloc/repo split.

**Performance Goals**: Form interactive within 200 ms; submit blocked under a `Loading()` overlay while `LoadingEditProfileState` is active.

**Constraints**:

- `EditProfileRepo` posts a `method: PUT` header to spoof a PUT through legacy proxy infra. Don't change without server coordination.
- Avatar submit re-reads the file from disk via `MultipartFile.fromFile`. Path must outlive the request.
- The phone field controller is initialised by stripping `+` + country code; assumes the user's `phone` and `countryCode` are consistent.

**Scale/Scope**: ~800 LOC across screen + bloc + repo + 5 models + helper `choose_image.dart`.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/`, `repo/`, `models/`, `widgets/`, screen at root, `choose_image.dart` at root. ✓
- [x] **II. Dependency Direction** — imports only `lib/core/*` + `add_address` models (for the city/area events on the bloc, currently unused). ⚠️ The `SelectCountry` / `SelectCity` / `SelectRegion` events in [edit_profile_events.dart](../../../lib/features/settings/edit_profile/bloc/edit_profile_events.dart) are declared but never used; cross-feature import is therefore unnecessary today.
- [x] **III. Networking Contract** — `NetworkClient.handleRequest` returning `Either<Failure, T>`. ✓
- [x] **IV. Persistence Discipline** — N/A directly; mutates `UserBloc` via `getUserData()`. ✓
- [x] **V. Flavor Branching** — `context.isProfessors` for teacher-only fields; `isCurrentUserProfessor` in the bloc. ⚠️ Fixed 2026-05-14 (no `mainKey.currentContext` branching in this feature anymore — repo confirmed clean).
- [x] **VI. Localization** — all visible strings are routed through `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit (downstream of Settings).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h/.w/.r/.sp/.csh/.csw` + `context.colors.*` throughout. ⚠️ `Colors.white` and `Colors.transparent` appear in 2 places ([edit_profile_screen.dart:267-268, 405, 417](../../../lib/features/settings/edit_profile/edit_profile_screen.dart#L267-L268)) — see tasks.md T-cleanup-1.

## Project Structure

### Documentation (this feature)

```text
specs/settings/edit_profile/
├── spec.md
├── plan.md   # this file
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/edit_profile/
├── edit_profile_screen.dart                # form + listeners
├── choose_image.dart                       # crop_your_image helper for avatar
├── bloc/
│   ├── edit_profile_bloc.dart              # Bloc<…> with FetchEditProfileEvent + SubmitEditProfileEvent
│   ├── edit_profile_events.dart            # event hierarchy
│   └── edit_profile_states.dart            # InitialEditProfileState/Loading/Fetched/Success/Error
├── repo/
│   └── edit_profile_repo.dart              # updateProfile + getClasses (unused) + getTitles
├── models/
│   ├── title_model.dart
│   ├── class_model.dart
│   ├── email_model.dart
│   ├── phone_model.dart
│   └── state_model.dart
└── widgets/
    └── edit_profile_field_tile.dart        # FieldTitle row with optional inline add-button
```

### Cross-feature touch points

- [lib/core/user/bloc/user_bloc.dart](../../../lib/core/user/bloc/user_bloc.dart) — `getUserData()` rehydrates after success.
- [lib/core/user/current_role.dart](../../../lib/core/user/current_role.dart) — `isCurrentUserProfessor` used by the bloc.
- [lib/core/attachment_selection/](../../../lib/core/attachment_selection/) — `showAttachmentSelectionBottomSheet` used to pick avatar source.
- [lib/features/add_address/models/](../../../lib/features/add_address/models/) — `CityModel` / `RegionModel` / `AreaModel` imported by `edit_profile_events.dart` for unused events.

**Structure Decision**: standard layout (`bloc/`, `repo/`, `models/`, `widgets/`, screen at root). Matches `my_children/` and `about/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `Bloc<EditProfileEvents, EditProfileStates>` with `SelectCountry`/`SelectCity`/`SelectRegion` events that are never dispatched | Likely vestigial from a shared form pattern with `add_address`. | Delete dead events; harmless but adds cognitive load. **See tasks.md T-cleanup-2.** |
| Commented-out CPF gate (Brazil-only) + commented-out external-contacts block | Iteration state; pending product decision. | Restore the `isBrazil` gate or remove entirely; **see tasks.md T-cleanup-3.** |
| `method: PUT` header spoof on a POST | Legacy proxy infra. | Use real PUT once backend is verified. **See tasks.md T-cleanup-4.** |
