---
status: migrated
feature: otp
flavor_scope: both
migrated_from: specs/features.md#otp--b
migrated_date: 2026-05-14
---

# Feature Specification: OTP (SMS Verification)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/otp/](../../lib/features/otp/) and the existing [features.md `## otp · B`](../features.md#otp--b) entry.

## Flavor Scope

- **Target flavor(s)**: both. The OTP screen is identical for parents and teachers.
- **Flavor-conditional behavior**: none. The flavor information already rides in the `role` field set during the prior `auth/login` call (see [login spec](../login/spec.md)); OTP just verifies the SMS code and re-calls `auth/login` to materialize the `UserModel`.
- **Server role implication**: derived upstream during the phone-OTP login step. OTP itself sends no role.

## User Scenarios & Testing

### User Story 1 — Enter and verify 6-digit SMS code (Priority: P1) 🎯 MVP

A user has just submitted the phone form on [LoginScreen](../../lib/features/login/presentation/login_screen.dart). They land on [OTPScreen](../../lib/features/otp/presentation/otp_screen.dart) showing their phone number, a 6-cell pin code field, a resend link, and a circular arrow CTA. As soon as they type the 6th digit (or tap the arrow), the code is verified and they continue.

**Why this priority**: Without OTP success there is no authenticated session; phone-OTP is the primary login path.

**Independent Test**: Trigger `LoginReady` from a phone submission, then enter the SMS code on the OTP screen. Approved user lands on main; pending user lands on `your_account_under_review`.

**Acceptance Scenarios**:

1. **Given** a user with an active `verificationId` from Firebase, **When** they type the 6-digit code, **Then** `OTPBloc.confirmSMSCode` calls `LoginRepository.confirmOTP` → `LoginRepository.login` (second time, to materialize `UserModel`) → emits `OTPSuccess`.
2. **Given** the user is debug-mode bypassing, **When** they type `123456`, **Then** the Firebase round-trip is skipped and `OTPSuccess` fires (debug branch lives in `LoginImpl`, not here).
3. **Given** the SMS code is wrong, **When** the user types 6 digits, **Then** `OTPFailure(NetworkFailure(message: 'invalid-verification-code'))` is emitted and the `ErrorField` surfaces above the pin field.
4. **Given** `OTPSuccess` and `UserBloc.user.isApproval == true`, **When** the listener fires, **Then** the user is pushed to `MainScreen` with the stack cleared.
5. **Given** `OTPSuccess` and `UserBloc.user.isApproval == false`, **When** the listener fires, **Then** the user is pushed to `YourAccountUnderReviewScreen`.

---

### User Story 2 — Resend OTP (Priority: P2)

The user didn't receive the SMS and taps "Resend again."

**Why this priority**: SMS delivery is unreliable on Brazilian carriers; a second-chance path is essential.

**Independent Test**: Tap resend after a few seconds; verify Firebase re-sends and the cooldown applies.

**Acceptance Scenarios**:

1. **Given** the user is on the OTP screen, **When** they tap "Resend again", **Then** `OTPBloc.resendOTP` calls `requestOTP` with the same phone and remembered `rememberMe` flag.
2. **Given** a fresh-enough `last_otp_request` for the same phone (≤ 60s ago), **When** the user taps resend, **Then** the app surfaces `OTPFailure(NetworkFailure(message: 'already_sent'))` and sets `ready.value = true` without firing Firebase again. *(see Gap-3: cooldown timer is commented out)*

---

### User Story 3 — Persist "Remember me" preference on success (Priority: P3)

If the user checked **Remember me** on the login screen, persist that preference so future cold starts can keep the session.

**Why this priority**: Quality-of-life; not blocking auth.

**Acceptance Scenarios**:

1. **Given** `rememberMe == true` was passed in from `LoginScreen`, **When** OTP succeeds, **Then** `LocalDatabaseRepo.write(LocalKeys.rememberMe, true)` fires before `OTPSuccess`.

---

### Edge Cases

- **`already_sent` error path**: the `OTPBloc.requestOTP` flow swallows this into an `OTPFailure` *and* sets `ready.value = true`. Mixed signal — UI may show an error while also enabling the "submit" affordance. Worth a UX review.
- **Code auto-fill on Android**: not implemented today. `pin_code_fields` does not subscribe to `SmsRetriever`. ([features.md task](../features.md#otp--b))
- **Verification timeout** (`OTPErrorModel.timeout()`): emitted by `LoginImpl.requestOTP` after Firebase's `codeAutoRetrievalTimeout`. UI just shows the code value; no explicit timeout copy.
- **Code expired** (`invalid-verification-code` after `verificationId` expires): handled as a generic failure today; no special copy. ([features.md task "Handle the 'code expired' path explicitly"](../features.md#otp--b))
- **Bloc receives `LoginFailure` for the upstream login error**: the OTP screen reads BOTH `OTPBloc` state AND `LoginBloc` state via two stacked `BlocSelector`s ([otp_screen.dart:171-182](../../lib/features/otp/presentation/otp_screen.dart#L171-L182)). Couples OTP to the prior screen's bloc lifetime.
- **Approval gate**: handled in the OTP screen's `OTPSuccess` listener.
- **Cold start during OTP entry**: `verificationId` is held only in `LoginImpl` instance state. A cold start mid-flow loses it; the user has to go back to the login screen.

## Requirements

### Functional Requirements

- **FR-001**: System MUST present a 6-cell pin code field that accepts digits only, auto-focused on screen entry.
- **FR-002**: System MUST auto-submit when the user types the 6th digit (no Loading state).
- **FR-003**: System MUST verify the code by calling `LoginRepository.confirmOTP(smsCode, phone)`.
- **FR-004**: After a successful Firebase credential exchange, System MUST re-call `LoginRepository.login(LoginRequest{phone, country_code})` to materialize a `UserModel` from the Criarte backend.
- **FR-005**: System MUST emit `OTPSuccess` only after `UserBloc.loggedIn(userModel)` completes.
- **FR-006**: System MUST honor the approval gate after `OTPSuccess`: route to `MainScreen` if `isApproval == true`, else to `YourAccountUnderReviewScreen`.
- **FR-007**: System MUST allow the user to tap "Resend again" to re-request the OTP from Firebase.
- **FR-008**: System MUST persist `rememberMe = true` to `LocalDatabaseRepo` (`LocalKeys.rememberMe`) on success when the user opted in at login.
- **FR-009**: System MUST clear `LocalKeys.last_otp_request` and `LocalKeys.last_otp_phone` on success.
- **FR-010**: System MUST enforce a 60-second cooldown between OTP requests for the same phone. *Restored 2026-05-14 — see [tasks.md T-fix-1](tasks.md).*

### Localization Requirements

Keys referenced (all already present in pt/en/ar):

| Key | Use site |
|---|---|
| `phone_verification` | screen title |
| `enter_otp_that_sent_to` | subtitle |
| `did_not_receive_code` | resend prompt |
| `resend_again` | resend CTA |
| `this_field_cant_be_empty` | empty-code validator |
| `this_field_cant_be_empty_or_less_than`, `character` | short-code validator |

No new keys required by this migration.

### Backend Touchpoints

- **REST**: `POST auth/login` — called a second time after `signInWithCredential` to retrieve the Criarte `UserModel`. Same body shape as the initial phone submission.
- **Firebase Auth**: `signInWithCredential(PhoneAuthProvider.credential(verificationId, smsCode))`. The `verificationId` lives in `LoginImpl` instance state and is **not** owned by `OTPBloc`.
- **No Firestore**.
- **No FCM** (the FCM token was already attached during the initial `auth/login` call).

### Permissions & Approval Gate

- Approval gate honored in the screen's `OTPSuccess` listener.
- No device permissions required by this screen (the SMS code is typed manually; no `SmsRetriever` is wired).

### Key Entities

- **`OTPRequest`** ([otp_requset.dart](../../lib/features/otp/models/otp_requset.dart)) — `{phoneNumber}`. ⚠️ filename typo: `requset`.
- **`OTPErrorModel`** ([otp_error_model.dart](../../lib/features/otp/models/otp_error_model.dart)) — `{code, message}` with named constructors `.timeout()`, `.alreadySent()`, `.verificationIdNotFound()`.
- **`OTPState` (sealed)** — `OTPInitial`, `OTPLoading`, `OTPReady`, `CodeSentVerifyPhoneState` (unused), `OTPSuccess`, `OTPFailure(Failure)`.
- **`ConfirmOTPRequest`** ([confirm_otp_requset.dart](../../lib/features/otp/models/confirm_otp_requset.dart)) — **unused dead code.** (Not read; referenced only in commented-out event code.)
- **`OTPResponse`** ([otp_response.dart](../../lib/features/otp/models/otp_response.dart)) — **likely dead code** parallel to `LoginResponse`. Verify and delete in cleanup.

## Success Criteria

- **SC-001**: A user can verify a valid 6-digit OTP and land on the correct screen within 5 seconds of the SMS arriving.
- **SC-002**: The OTP screen never crashes if the upstream `verificationId` is null — surfaces a clear error (`verification_id_null`).
- **SC-003**: After a successful OTP, `UserBloc.state.user` is non-null in the next screen.
- **SC-004**: A user can resend OTP at most once per 60 seconds for the same phone (currently violated — Gap-3).

## Assumptions

- The user reached this screen via [LoginScreen → LoginReady → push OTPScreen](../../lib/features/login/presentation/login_screen.dart#L84-L97); a fresh `verificationId` is held in the `LoginImpl` singleton.
- Firebase phone-auth is configured for the active flavor (`com.algoriza.criarte` or `com.algoriza.profecriarte`).
- The `OTPBloc` is created with `di<OTPBloc>()` *per OTP screen instance* — `registerFactory`, not singleton. Confirmed in [core/dependency_injection/di.dart:87](../../lib/core/dependency_injection/di.dart#L87).
- The same `LoginBloc` instance from the prior screen is still in the navigator stack (the OTP screen reads `LoginFailure` from it via `BlocSelector<LoginBloc, ...>`).
