---
status: migrated
feature: register
migrated_from: specs/features.md#register--b
migrated_date: 2026-05-14
---

# Tasks: Register

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#register--b](../features.md#register--b).

**Tests**: No `test/` directory; test tasks are aspirational.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/register/](../../lib/features/register/) with `bloc/` (variation: at feature root, not under `presentation/`) + `presentation/`
- [x] T002 Use existing localization keys (`create_account`, `name`, `email`, `password`, `password_confirmation`, `confirm`, `password_doesnot_match`); no new keys required
- [x] T003 ✅ DI placement resolved by [constitution v1.2.0 principle II](../../.specify/memory/constitution.md). Register uses the sibling-co-located pattern (inside `login_di.dart`) because it shares `LoginRepository`. Promote to `register_di.dart` if T-fix-1 (split `RegisterRepository`) lands.

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `RegisterEvents` / `RegisterParamaters` in [bloc/register_event.dart](../../lib/features/register/bloc/register_event.dart) (⚠️ class-name typo: `Paramaters`)
- [x] T011 Define `RegisterStates` (plural) — `Initial / Loading / Success / Error(message)`
- [x] T012 Implement `RegisterBloc.submitRegister` → `LoginRepository.register` → `UserBloc.loggedIn` on success
- [x] T013 Add `register()` to [LoginRepository abstract](../../lib/features/login/data_sources/login_repository.dart) and [LoginImpl](../../lib/features/login/data_sources/login_impl.dart) using `NetworkClient.handleRequest`

## Phase 3: User Story 1 — Create account (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement [RegisterScreen](../../lib/features/register/presentation/register_screen.dart) with four `CustomTextField`s + `ButtonWithIcon` CTA
- [x] T021 [US1] All four client-side validators wired (empty / email-format / password length / confirm-match)
- [x] T022 [US1] `ProfessorsContainer` badge shown when `context.isProfessors`
- [x] T023 [US1] **(P0)** Replace `mainKey.currentContext` with `isProfessorsFlavor` in `LoginImpl.register`. *Fixed 2026-05-14 in the [login T-fix-1 sweep](../login/tasks.md#constitution-drift-fixes).*
- [x] T024 [US1] `SuccessRegisterState` listener routes through approval gate
- [x] T025 [US1] `ErrorRegisterState(message)` shown inline above the form

---

## Phase 6: Gaps & cleanups

### Bugs / drift

- [ ] **T-fix-1** **(P1)** [US1] *(from [features.md#register--b](../features.md#register--b))* Move `register()` out of `LoginRepository` into a dedicated `RegisterRepository`. Today the only difference at the data layer is the endpoint path. Splitting becomes meaningful once register collects more domain (CPF, school-code, child registration, T&C acceptance). Coordinate with [T-cross-1](#cross-feature) — both are about un-coupling register from login at the wiring layer.

- [ ] **T-fix-2** **(P1)** [US1] *(from [features.md#register--b](../features.md#register--b))* Surface server-side validation errors per field. Today [LoginImpl.register catch-all](../../lib/features/login/data_sources/login_impl.dart#L384-L387) collapses 4xx → `ServerFailure('Registration failed')`. Implement a structured-error path that maps the server's `{errors: {email: ['...']}}` payload to `RegisterStates` keyed by field.

- [x] **T-fix-3** **(P0, legal)** [US1] ✅ **Fixed 2026-05-14** in [register_screen.dart](../../lib/features/register/presentation/register_screen.dart): inline T&C / Privacy consent block added below the Confirm button, mirroring the [LoginScreen pattern](../../lib/features/login/presentation/login_screen.dart#L379-L441). Reuses existing localization keys `by_continuing_i_agree`, `terms_and_conditions`, `and`, `privacy_policy` (no new translations needed). Both links open the same `TermsAndConditions` / `PrivacyPolicy` screens as the login flow. Coordinate with legal/LGPD to confirm wording is acceptable for both registration and login surfaces.

- [ ] **T-fix-4** **(P2)** [US1] *(from [features.md#register--b](../features.md#register--b))* Confirm parity between client-side password validator and the server contract (length, character classes, common-password blocklist).

- [ ] **T-fix-5** **(P2)** [UX] *(from [features.md#register--b](../features.md#register--b))* Add a visible "back to login" CTA. The Row with that link is commented out at [register_screen.dart:264-291](../../lib/features/register/presentation/register_screen.dart#L264-L291). Either delete the commented block or re-enable it.

- [ ] **T-fix-6** **(P2)** [docs] *(from [features.md#register--b](../features.md#register--b))* Document whether teachers can self-register or only school admins. Today the screen is identical for both flavors; clarify product intent.

### Code hygiene

- [ ] **T-cleanup-1** Rename typo'd identifiers:
  - `RegisterParamaters` (class) → `RegisterParameters`
  - The class is referenced in `LoginRepository.register({event})` so the rename touches `LoginRepository` + `LoginImpl` + `RegisterBloc.submitRegister` + the call site in `register_screen.dart`.
  - For consistency, also rename `RegisterStates` (plural) → `RegisterState` (singular) to match `LoginState`.

- [ ] **T-cleanup-2** Move `FieldTitle` from [settings/edit_profile/widgets/edit_profile_field_tile.dart](../../lib/features/settings/edit_profile/widgets/edit_profile_field_tile.dart) to [lib/core/components/](../../lib/core/components/) (probably `widgets/field_title.dart`) so register doesn't import from settings. Cross-feature import currently violates the spirit of [constitution principle II](../../.specify/memory/constitution.md).

- [ ] **T-cleanup-3** Delete the commented "back to login" Row at [register_screen.dart:264-291](../../lib/features/register/presentation/register_screen.dart#L264-L291) (or re-enable it per T-fix-5).

- [ ] **T-cleanup-4** Remove stray top-of-file comment `// lib/features/auth/register/bloc/register_bloc.dart` ([register_bloc.dart:1](../../lib/features/register/bloc/register_bloc.dart#L1)) — the file is not under `auth/` and the path tag is misleading.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget tests for all four validators (empty / invalid email / short password / mismatch).
- [ ] **T-test-2** [P] [US1] Cubit test: `submitRegister` failure path → `ErrorRegisterState`; success path → `UserBloc.loggedIn` called → `SuccessRegisterState`.
- [ ] **T-test-3** [P] [US1] Widget test for the approval gate routing on `SuccessRegisterState`.

### Cross-feature

- [x] **T-cross-1** **(P1)** ✅ **Resolved 2026-05-14** by [constitution v1.2.0](../../.specify/memory/constitution.md#amendment-log): sibling-co-located DI is now explicitly allowed. Keep register in `login_di.dart` for now; promote to `register_di.dart` together with T-fix-1 (split `RegisterRepository`) when registration grows its own domain.

---

## Notes

- This is a **migration** — `[x]` items reflect existing code + history.
- The T-fix-1 (register's `mainKey` → `isProfessorsFlavor`) was already addressed in the login T-fix-1 sweep on 2026-05-14. The earlier features.md task about register is now also ticked.
- Three closely-related cleanups (T-fix-1 split repo, T-cross-1 DI placement, T-cleanup-1 rename) should be done together to avoid touching the same call sites twice.
