---
status: migrated
feature: login
flavor_scope: both
migrated_from: specs/features.md#login--b
migrated_date: 2026-05-14
---

# Feature Specification: Login

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/login/](../../lib/features/login/) and the existing [features.md `## login · B`](../features.md#login--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores)
- **Flavor-conditional behavior**:
  - Title copy interpolates `LocalizationKeys.professors` or `LocalizationKeys.parents` based on `context.isProfessors` (see [login_screen.dart:194-203](../../lib/features/login/presentation/login_screen.dart#L194-L203)).
  - Teachers see a `ProfessorsContainer` badge above the title ([login_screen.dart:181-190](../../lib/features/login/presentation/login_screen.dart#L181-L190)).
  - Google Sign-In uses different iOS OAuth client IDs per flavor (currently hardcoded in [login_impl.dart:218-228](../../lib/features/login/data_sources/login_impl.dart#L218-L228)).
- **Server role implication**: The `role` field in every auth request is derived from the flavor binary — `'teacher'` for `professores`, `'parent'` for `parents`. Pre-login there is no `UserBloc.user`, so the source of truth is the process-wide flavor flag (`isProfessorsFlavor` in phone-OTP login; legacy `mainKey.currentContext?.isProfessors` still used in social/email/register paths — see Gaps).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Phone + SMS OTP login (Priority: P1) 🎯 MVP

A user enters a country code and phone number, taps **Login**, receives an SMS code from Firebase, types it on the OTP screen, and lands on the home screen (or `your_account_under_review` if `isApproval == false`).

**Why this priority**: This is the primary auth path. Without it neither flavor can be used.

**Independent Test**:
1. Launch parents flavor on a real device or emulator with Google Play Services.
2. Enter a valid Brazilian phone number, tap Login.
3. Receive SMS, enter the 6-digit code in the OTP screen.
4. Land on home (approved) or `your_account_under_review` (pending).

**Acceptance Scenarios**:

1. **Given** a new user with a valid phone number, **When** they submit the phone form, **Then** the app calls `POST auth/login` with `{phone, country_code, device_token, role}` and Firebase sends an SMS code.
2. **Given** a user with a pending OTP within the 60-second cooldown, **When** they re-request OTP for the same phone, **Then** the app skips the Firebase call and goes straight to the OTP screen (`LoginReady`).
3. **Given** OTP verification succeeds and the server returns `isApproval == true`, **When** the user completes OTP, **Then** they land on the main shell.
4. **Given** OTP verification succeeds and the server returns `isApproval == false`, **When** the user completes OTP, **Then** they land on `your_account_under_review`.
5. **Given** OTP verification fails with `invalid-verification-code`, **When** the user submits the wrong code, **Then** the OTP screen surfaces an error and allows retry.
6. **Given** debug mode and FCM unavailable (emulator without Play Services), **When** the user submits the phone form, **Then** a fallback `device_token: 'debug-device-token'` is used and login proceeds.

---

### User Story 2 - Social login (Google / Facebook / Apple) (Priority: P2)

A user taps one of the social-provider buttons (visibility gated by `ConfigCubit.socialLogin`), completes the provider's sheet, and the backend exchanges the provider token for a Criarte session.

**Why this priority**: Reduces friction for parents who already have a Google/Facebook/Apple identity; complements phone OTP. Provider availability is server-driven via `ConfigSelector(selector: (config) => config.socialLogin)`.

**Independent Test**:
1. With `config.socialLogin.googleEnabled == true`, tap the Google button.
2. Complete the Google chooser.
3. Confirm the app posts to `auth/social-login` with `{token, provider, role, platform}` and emits `LoginSocialSuccess`.

**Acceptance Scenarios**:

1. **Given** `googleEnabled = true`, **When** the user taps Google and completes the chooser, **Then** the app sends `accessToken + provider: 'google'` to `auth/social-login` and routes to main or approval-gate.
2. **Given** `facebookEnabled = true`, **When** the user completes Facebook auth, **Then** the app sends `tokenString + provider: 'facebook'` to `auth/social-login`.
3. **Given** running on Android, **When** the user sees the social row, **Then** the Apple button is hidden ([social_login_widget.dart:80](../../lib/features/login/presentation/widget/social_login_widget.dart#L80) — `Platform.isIOS && state.appleEnabled`).
4. **Given** the user cancels the provider sheet, **When** the provider returns no credential, **Then** the app emits `LoginFailure('Sign in aborted by user')` (Google) / `'Facebook login failed or was cancelled'` (Facebook) without crashing.
5. **Given** all three providers are disabled in remote config, **When** the user reaches the login screen, **Then** the social row collapses to `SizedBox.shrink()` ([social_login_widget.dart:42-44](../../lib/features/login/presentation/widget/social_login_widget.dart#L42-L44)).

---

### User Story 3 - Email + password login (Priority: P3)

A user toggles the social row's "email" icon, fills email and password fields, and submits.

**Why this priority**: Fallback for users who can't use phone OTP or social. Lower volume than P1/P2.

**Independent Test**:
1. Tap the email-icon in the social row to flip `isEmailLogin = true`.
2. Enter a valid email (regex-matched) and password ≥ 6 characters.
3. Tap Login.
4. Confirm `POST auth/login-with-email` returns a `UserModel` and the app routes correctly.

**Acceptance Scenarios**:

1. **Given** a registered email and password, **When** the user submits, **Then** the app calls `auth/login-with-email` with `{email, password, role}` and emits `LoginWithEmailSuccess(userModel)`.
2. **Given** an invalid email format, **When** the user attempts to submit, **Then** the form validator blocks submission with `this_is_not_a_valid_email`.
3. **Given** a password under 6 characters, **When** the user attempts to submit, **Then** the validator blocks with `this_field_cant_be_empty_or_less_than 6 character`.
4. **Given** the server returns `{error: true, data: null}`, **When** the user submits, **Then** the app emits `LoginFailure` with the server-provided message.

---

### Edge Cases

- **Cold start with stale `last_otp_request`**: `LoginBloc._init` reads `last_otp_request` + `last_otp_phone` from Hive; if within 60s for the same phone, the cooldown resumes.
- **Cooldown for a different phone**: `_init` ignores the cooldown if `phone != lastOtpPhone`, allowing immediate OTP for the new number.
- **Debug bypass code `123456`**: In `kDebugMode`, Firebase phone verification is skipped entirely and `123456` is accepted on the OTP screen ([login_impl.dart:61-80](../../lib/features/login/data_sources/login_impl.dart#L61-L80), [login_impl.dart:133-145](../../lib/features/login/data_sources/login_impl.dart#L133-L145)). **Risk**: `_isDebugBypass` lives in the `LazySingleton` repo and is never reset, so a release build that flips `kDebugMode` after the singleton is constructed (impossible today but worth noting) would carry stale state.
- **FCM token unavailable in release mode**: `getToken()` rethrows; login fails.
- **Provider returns no idToken** (Google misconfigured `serverClientId`): explicit `Exception('No ID token returned - check serverClientId configuration')`.
- **Approval gate**: Both `LoginSocialSuccess` and `LoginWithEmailSuccess` listeners check `UserBloc.get.state.user?.isApproval == true` before routing to main; otherwise routes to `your_account_under_review`. The phone-OTP path delegates this to the OTP screen.
- **No password reset path**: not implemented; not in scope here.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow a user to request an SMS OTP for their phone via `POST auth/login` with body `{phone, country_code, device_token, role}`.
- **FR-002**: System MUST set `role: 'teacher'` for the `professores` flavor and `role: 'parent'` for the `parents` flavor, derived from the flavor binary (not from `UserBloc`, which is empty pre-login).
- **FR-003**: System MUST verify the SMS code via Firebase `signInWithCredential` and return a `UserModel` on success.
- **FR-004**: System MUST enforce a 60-second cooldown between OTP requests for the same phone, persisted in Hive (`last_otp_request`, `last_otp_phone`).
- **FR-005**: System MUST support social login via Google, Facebook, and Apple, with each provider's visibility controlled by `ConfigCubit.socialLogin.{googleEnabled, facebookEnabled, appleEnabled}`.
- **FR-006**: System MUST hide the Apple button on Android and web.
- **FR-007**: System MUST support email + password login via `POST auth/login-with-email`.
- **FR-008**: System MUST route to `your_account_under_review` after login if `UserBloc.user.isApproval == false`, and to the main shell otherwise.
- **FR-009**: System MUST persist `last_otp_phone` and `last_otp_request` through [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart), not Hive directly.
- **FR-010**: System MUST call `UserBloc.loggedIn(userModel)` on successful social or email auth so persisted state hydrates downstream features.
- **FR-011**: System MUST allow a "Remember me" toggle that propagates to the OTP screen ([login_screen.dart:93](../../lib/features/login/presentation/login_screen.dart#L93)).
- **FR-012**: System MUST surface terms and privacy links inline beneath the Login CTA, navigating to `TermsAndConditions` and `PrivacyPolicy` screens.
- **FR-013**: System MUST handle 401 responses from any auth endpoint via the interceptor at [network_interceptor.dart](../../lib/core/network/network_interceptor.dart) (forces `UserBloc.loggedOut()`).
- **FR-014**: System MUST, in `kDebugMode` only, bypass Firebase phone verification and accept the hard-coded code `123456`.
- **FR-015**: System MUST, on FCM `getToken()` failure in `kDebugMode`, fall back to `device_token: 'debug-device-token'` so emulator login still works.

### Localization Requirements

All user-visible strings already routed through `LocalizationKeys`. Keys actually referenced by this feature:

| Key | Use site |
|---|---|
| `login_title` | screen title |
| `professors`, `parents` | flavor-specific suffix in title |
| `login` | CTA button |
| `keep_me_logged_in` | remember-me checkbox |
| `by_continuing_i_agree`, `terms_and_conditions`, `and`, `privacy_policy` | T&C/Privacy inline links |
| `or_login_with` | social-login row label |
| `email`, `password` | email-form field hints |
| `dont_have_account`, `create_account` | register CTA |
| `this_field_cant_be_empty` | required-field error |
| `this_is_not_a_valid_email` | email-format error |
| `this_field_cant_be_empty_or_less_than`, `character` | password-length error |
| `please_enter_a_valid_phone_number` | phone-format error |

No new keys required by this migration. Existing translations live in [assets/langs/pt.json](../../assets/langs/pt.json) / [en.json](../../assets/langs/en.json) / [ar.json](../../assets/langs/ar.json). [features.md](../features.md#cross-feature-tasks) notes `ar.json` is ~40% behind — flagged as cross-feature work, not blocking here.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `POST auth/login` — request OTP. Body: `{phone, country_code, device_token, role}`. Response: `{data: UserModel}`.
  - `POST auth/social-login` — exchange provider token. Body: `{token, provider, role, platform}`. Response: `{data: UserModel}`.
  - `POST auth/login-with-email` — email/password. Body: `{email, password, role}`. Response: `{data: UserModel}` or `{error: true, message: string}`.
  - `POST auth/register` — implemented in this same repo but reached from the register screen (see [specs/register/](../register/) once migrated).
- **Headers**: `school: StaticConfig.schoolId` set explicitly on phone-OTP login; standard auth/`school_id`/`lang` headers added by [NetworkInterceptor](../../lib/core/network/network_interceptor.dart) for the others.
- **Firebase Auth**: `verifyPhoneNumber` + `signInWithCredential` — Criarte uses Firebase for SMS delivery and credential verification, then exchanges that for a Criarte session via `auth/login`.
- **FCM**: `FirebaseMessaging.instance.getToken()` is called per login attempt; the token rides in the request body as `device_token`. Token refreshes are wired in [background_services/](../../lib/features/background_services/) via `onTokenRefresh`.
- **Firestore**: not used by this feature.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **No** — login is the entry point that *determines* approval state. The post-login routers (`LoginSocialSuccess`, `LoginWithEmailSuccess`) honor the gate by checking `UserBloc.get.state.user?.isApproval` before pushing `MainScreen` vs `YourAccountUnderReviewScreen`.
- Device permissions:
  - **Notifications** — required to retrieve the FCM `device_token`.
  - No camera/mic/storage permissions for login itself.

### Key Entities

- **`LoginRequest`** ([login_requset.dart](../../lib/features/login/models/login_requset.dart)) — `{phone, country_code}`. Note the file-name typo (`requset`).
- **`LoginEmailParamaters`** ([login_email_paramaters.dart](../../lib/features/login/models/login_email_paramaters.dart)) — `{email, password}`. Note the file-name typo (`Paramaters`).
- **`LoginResponse`** ([login_response.dart](../../lib/features/login/models/login_response.dart)) — `{token}`. **Unused in current code** — `LoginImpl` returns `UserModel` directly. Dead code.
- **`UserModel`** (shared from [lib/core/models/user_model.dart](../../lib/core/models/user_model.dart)) — emitted via `UserBloc.loggedIn(...)`. Persisted by `HydratedCubit`.
- **`OTPRequest`** / **`OTPErrorModel`** (shared with [otp/](../../lib/features/otp/)) — the contract between `LoginRepository.confirmOTP` and the OTP screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can complete phone OTP login end-to-end on a real device in under 60 seconds (provided Firebase SMS delivery is timely).
- **SC-002**: 401 responses from any auth endpoint terminate the session via the global interceptor without leaving the user on a broken screen.
- **SC-003**: With all three social providers disabled in `ConfigCubit.socialLogin`, the login screen renders with phone form only and the social row collapses.
- **SC-004**: A user with `isApproval == false` cannot reach the main shell via any login path — always lands on `your_account_under_review`.
- **SC-005**: Debug-mode bypass code `123456` works on emulators without Google Play Services in `kDebugMode` builds only.

## Assumptions

- Firebase project `escola-cede2` is configured for phone-auth in both Android applicationIds (`com.algoriza.criarte`, `com.algoriza.profecriarte`).
- Backend at `https://criarte.filhos.app/api/v1/` handles `role: teacher` vs `role: parent` correctly via the dedicated endpoints; the same phone may be valid in only one role.
- `StaticConfig.schoolId` is set by the build configuration or onboarding flow before the user reaches the login screen.
- `ConfigCubit` is hydrated before the login screen renders (otherwise `ConfigSelector(selector: socialLogin)` reads empty state and the row collapses).
- The 60-second OTP cooldown matches Firebase's default `codeAutoRetrievalTimeout` window (`Duration(seconds: 120)` in code — they don't match exactly; cooldown is shorter, intentional UX choice).
