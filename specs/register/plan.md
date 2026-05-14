---
status: migrated
feature: register
migrated_from: lib/features/register/
migrated_date: 2026-05-14
---

# Implementation Plan: Register

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Create-account screen reached from the login footer. Collects name / email / password / confirm-password and posts `auth/register`. **Shares [LoginRepository](../../lib/features/login/data_sources/login_repository.dart)** — register has no `_impl.dart` of its own; `RegisterBloc` is wired in [login_di.dart](../../lib/features/login/login_di.dart) alongside `LoginBloc`. 4 .dart files.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `RegisterBloc` is a `Cubit<RegisterStates>`
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart)
- `dartz` — `Either<Failure, UserModel>` from `LoginRepository.register`
- `flutter_screenutil` 5.9
- Reuses `CustomTextField`, `ButtonWithIcon`, `ErrorField`, `CommonImage`, `MyAppBar` from `lib/core/components/`

**Storage**: None directly. `UserBloc` (HydratedCubit) is updated on success.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **no `data_sources/`, no `models/` folder, no feature-root `_di.dart`** — atypically lean.

**Performance Goals**: Form interactive within 200 ms after navigation; submit round-trip dominated by backend.

**Constraints**:

- Shares `LoginRepository`. If registration grows beyond a single endpoint, split out `RegisterRepository`.
- No T&C consent surface today — legal risk worth flagging.

**Scale/Scope**: 4 .dart files, ~330 LOC (mostly screen).

## Constitution Check

- [ ] **I. Feature-First Layout** — ⚠️ Layout drift: register uses `bloc/` at the *feature root* (not under `presentation/bloc/`) — see [register/bloc/register_bloc.dart](../../lib/features/register/bloc/register_bloc.dart). This is one of the documented variations in [constitution principle I](../../.specify/memory/constitution.md). Acceptable.
- [x] **II. Dependency Direction** — ✓ Register uses the **sibling-co-located** pattern explicitly acknowledged by [constitution v1.2.0 principle II](../../.specify/memory/constitution.md). `RegisterBloc` is registered inside [login_di.dart:22-24](../../lib/features/login/login_di.dart#L22-L24) because register shares `LoginRepository`. If T-fix-1 (split out `RegisterRepository`) lands, promote register to its own `register_di.dart` per the constitution's "promote when a thin feature grows a domain" rule.
- [x] **III. Networking Contract** — `LoginImpl.register` uses `NetworkClient.handleRequest` returning `Either<Failure, UserModel>`. ✓
- [x] **IV. Persistence Discipline** — N/A directly (no Hive). ✓
- [x] **V. Flavor Branching** — `context.isProfessors` used for the badge; `isProfessorsFlavor` used in the request body (post T-fix-1). ✓
- [x] **VI. Localization** — all strings via `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — honored in `SuccessRegisterState` listener. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `flutter_screenutil` + `context.colors.*` throughout. ✓

## Project Structure

### Source Code (existing)

```text
lib/features/register/
├── bloc/                            # at feature root (variation, not under presentation/)
│   ├── register_bloc.dart           # Cubit<RegisterStates> — calls LoginRepository.register
│   ├── register_event.dart          # RegisterParamaters (typo'd class name)
│   └── register_state.dart          # RegisterStates (plural) — Initial / Loading / Success / Error
└── presentation/
    └── register_screen.dart         # form + validators + listener
```

### Cross-feature touch points

- **[lib/features/login/data_sources/login_repository.dart](../../lib/features/login/data_sources/login_repository.dart)** — `register({event})` lives here, **not** in this feature
- **[lib/features/login/login_di.dart](../../lib/features/login/login_di.dart)** — `RegisterBloc` is registered here
- **[lib/features/main/](../../lib/features/main/)** — destination on approved success
- **[lib/features/your_account_under_review/](../../lib/features/your_account_under_review/)** — destination on pending success
- **[lib/features/settings/edit_profile/widgets/edit_profile_field_tile.dart](../../lib/features/settings/edit_profile/widgets/edit_profile_field_tile.dart)** — imported for `FieldTitle`; this is **cross-feature** coupling that should live in `lib/core/components/`. See [tasks.md T-cleanup-2](tasks.md).
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — `UserBloc.get.loggedIn(user)` on success

**Structure Decision**: Shared-repo pattern is intentional. Document it; revisit when registration grows.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Register has no `data_sources/`; shares `LoginRepository` | Single endpoint, no domain of its own. | Splitting today would be premature abstraction. Revisit if register grows (CPF, school-code, child registration). See [features.md#register--b](../features.md#register--b) P1 task. |
| ~~`RegisterBloc` registered in `login_di.dart`~~ | ✅ **Resolved 2026-05-14** by [constitution v1.2.0](../../.specify/memory/constitution.md#amendment-log): the sibling-co-located DI pattern is now explicitly allowed for tightly-coupled siblings. Re-evaluate when T-fix-1 (split `RegisterRepository`) lands. | — |
| `bloc/` at feature root rather than under `presentation/` | Sibling features (e.g., chat) also vary; mirror-closest-sibling is the rule. | Standardizing to `presentation/bloc/` would just shuffle imports. Accepted variation. |
| Cross-feature import of `FieldTitle` from `settings/edit_profile/` | Convenience — the tile existed there first. | Move `FieldTitle` to `lib/core/components/` (or `lib/core/components/widgets/`) so register doesn't depend on settings. See [tasks.md T-cleanup-2](tasks.md). |
| `RegisterStates` (plural) vs `LoginState` (singular) | Two different authors wrote them. | Cosmetic; rename to `RegisterState` when convenient. |
