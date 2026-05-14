---
status: migrated
feature: register
flavor_scope: both
migrated_from: specs/features.md#register--b
migrated_date: 2026-05-14
---

# Feature Specification: Register (Create Account)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/register/](../../lib/features/register/) and the freshly-added [features.md#register--b](../features.md#register--b).

## Flavor Scope

- **Target flavor(s)**: both. The same screen renders for parents and teachers.
- **Flavor-conditional behavior**: a `ProfessorsContainer` badge appears above the form when `context.isProfessors == true` ([register_screen.dart:131-140](../../lib/features/register/presentation/register_screen.dart#L131-L140)).
- **Server role implication**: `role: 'teacher'` or `role: 'parent'` is included in the `POST auth/register` body, derived from `isProfessorsFlavor` (post T-fix-1 sweep).

## User Scenarios & Testing

### User Story 1 — Create a new account (Priority: P1) 🎯 MVP

A new user, reached from the login screen's "Create account" link, fills in name, email, password, and confirm-password. Tapping **Confirm** posts to `auth/register`; on success, `UserBloc.loggedIn(user)` fires and they land on `MainScreen` (if approved) or `YourAccountUnderReviewScreen` (if pending — typical for teachers awaiting school admin approval).

**Why this priority**: Without registration, schools can only onboard via backend-driven account creation.

**Independent Test**:
1. From the login footer, tap "Create account".
2. Fill all four fields; valid email, password ≥ 6, passwords matching.
3. Tap Confirm.
4. Verify `POST auth/register` is called with `{name, email, password, password_confirmation, role}`, `UserBloc.state.user` is populated, and routing follows the approval gate.

**Acceptance Scenarios**:

1. **Given** a valid form, **When** the user taps Confirm, **Then** `RegisterBloc.submitRegister` calls `LoginRepository.register` and emits `LoadingRegisterState → SuccessRegisterState` after `UserBloc.loggedIn(user)`.
2. **Given** an invalid email format, **When** the user taps Confirm, **Then** the form validator blocks with `this_is_not_a_valid_email`.
3. **Given** a password shorter than 6 characters, **When** the user taps Confirm, **Then** the validator blocks with `this_field_cant_be_empty_or_less_than 6 character`.
4. **Given** mismatched password and confirm-password, **When** the user taps Confirm, **Then** the validator blocks with `password_doesnot_match`.
5. **Given** the server returns a `Failure`, **When** the call fails, **Then** `ErrorRegisterState(message)` is emitted and shown inline above the form.
6. **Given** `SuccessRegisterState` and `isApproval == true`, **When** the listener fires, **Then** the user is pushed to `MainScreen`.
7. **Given** `SuccessRegisterState` and `isApproval == false`, **When** the listener fires, **Then** the user is pushed to `YourAccountUnderReviewScreen`.

---

### Edge Cases

- **Email already in use**: today returns a generic `ServerFailure('Registration failed')` from [LoginImpl.register catch-all](../../lib/features/login/data_sources/login_impl.dart#L384-L387). Server-side validation messages are not surfaced per field. See [tasks.md T-fix-2](tasks.md).
- **Server returns 4xx with structured errors**: same as above — collapsed into the generic message.
- **Network failure mid-submit**: standard `NetworkException` → `NetworkFailure` path via [NetworkClient.handleRequest](../../lib/core/network/network_client.dart); error message routes through `LocalizationKeys`.
- **Approval gate**: honored in the `SuccessRegisterState` listener (same pattern as login).
- ~~**No T&C consent on submit**~~ ✅ *Resolved 2026-05-14 — see [tasks.md T-fix-3](tasks.md).* Register screen now surfaces the same inline T&C / Privacy consent block as [LoginScreen](../../lib/features/login/presentation/login_screen.dart#L379-L441) beneath the Confirm button.
- **No "back to login" affordance** beyond the default app-bar back arrow. The Row with "Already have an account? Login" is **commented out** at [register_screen.dart:264-291](../../lib/features/register/presentation/register_screen.dart#L264-L291).
- **Cross-feature import**: `register_screen.dart` imports `settings/edit_profile/widgets/edit_profile_field_tile.dart` for the `FieldTitle` widget — minor cross-feature coupling that should move to `lib/core/components/`.

## Requirements

### Functional Requirements

- **FR-001**: System MUST collect `name`, `email`, `password`, `password_confirmation` via `CustomTextField`s with the project's standard styling.
- **FR-002**: System MUST validate client-side:
  - All four fields non-empty
  - Email matches `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
  - Password length ≥ 6
  - `password == password_confirmation`
- **FR-003**: System MUST call `POST auth/register` with `{name, email, password, password_confirmation, role}` via `NetworkClient.handleRequest` returning `Either<Failure, UserModel>`.
- **FR-004**: System MUST derive `role` from the flavor binary (`isProfessorsFlavor`), not from `UserBloc` or `mainKey.currentContext`.
- **FR-005**: On success, System MUST call `UserBloc.get.loggedIn(userModel)` so persisted state hydrates before navigation.
- **FR-006**: System MUST route to `MainScreen` or `YourAccountUnderReviewScreen` based on `isApproval`.
- **FR-007**: System MUST surface server errors as inline copy above the form via `ErrorRegisterState(message)`.
- **FR-008**: System MUST show a `ProfessorsContainer` badge above the form when on the `professores` flavor.

### Localization Requirements

Keys referenced (all present in pt/en/ar today):

| Key | Use site |
|---|---|
| `create_account` | app-bar title |
| `name`, `email`, `password`, `password_confirmation` | field hints + `FieldTitle` labels |
| `confirm` | CTA |
| `this_field_cant_be_empty` | empty-field validator |
| `this_is_not_a_valid_email` | email-format validator |
| `this_field_cant_be_empty_or_less_than`, `character` | short-password validator |
| `password_doesnot_match` | confirm-password mismatch |

✅ **T&C / privacy consent strings now used** (since T-fix-3): `by_continuing_i_agree`, `terms_and_conditions`, `and`, `privacy_policy` — all already present in pt/en/ar.

### Backend Touchpoints

- **REST**: `POST auth/register` (base `https://criarte.filhos.app/api/v1/`). Body: `{name, email, password, password_confirmation, role}`. Response: `{data: UserModel}`.
- **No Firebase Auth** for this path (email/password, not phone).
- **No FCM** in this feature directly — the FCM token is registered separately in [background_services/](../../lib/features/background_services/) after login.
- **No Firestore**.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **No** — registration is the path that *creates* the user; approval is a server-side decision returned with the first `UserModel`.
- The post-register listener honors the gate exactly as login does.
- No device permissions required.

### Key Entities

- **`RegisterParamaters`** ([register_event.dart:10-23](../../lib/features/register/bloc/register_event.dart#L10-L23)) — `{name, email, password, confirmPassword}`. ⚠️ filename / class-name typo: `Paramaters`.
- **`RegisterStates`** ([register_state.dart](../../lib/features/register/bloc/register_state.dart)) — abstract base + `InitialRegisterState`, `LoadingRegisterState`, `SuccessRegisterState`, `ErrorRegisterState(error: String)`. Note: state name is `RegisterStates` (plural) while sibling `LoginState` is singular — inconsistent.
- **`RegisterBloc`** — `Cubit<RegisterStates>` that delegates to `LoginRepository.register`. Owns no repo of its own.
- **`UserModel`** — emitted via `UserBloc.loggedIn(...)` on success.

## Success Criteria

- **SC-001**: A user can complete registration end-to-end in under 90 seconds on a typical 4G connection.
- **SC-002**: All four client-side validators block submission with localized error copy in pt/en/ar.
- **SC-003**: A successfully-registered user lands on the correct screen based on `isApproval`.
- **SC-004**: A user who tries to register with an existing email sees a *server-specific* error message — **not** the generic "Registration failed" copy. (Currently violated — T-fix-2.)

## Assumptions

- Backend supports `POST auth/register` for both `role: 'parent'` and `role: 'teacher'`. Teachers likely default to `isApproval == false`, requiring school-admin action.
- The same backend that issues a `UserModel` on register sets the appropriate `school_id`.
- `LoginRepository` is the right home for `register()` for now (small overhead, single repository). If/when registration grows (CPF capture, school-code entry, child registration during signup), a dedicated `RegisterRepository` becomes worthwhile. See [features.md#register--b](../features.md#register--b) P1 task.
- No T&C consent on register is currently *accepted by product*. If legal pushes back, add the inline consent block from `LoginScreen`.
