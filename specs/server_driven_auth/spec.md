---
status: draft
feature: server_driven_auth
flavor_scope: both
seeded_from: master prompt 2026-05-25 (server-driven authentication refactor)
created: 2026-05-25
---

# Feature Specification: Server-Driven Authentication

**Feature Branch**: `ahmed_nour_` (operating alongside sibling auth work)

**Created**: 2026-05-25

**Status**: Draft

**Input**: Master prompt (paraphrased): *"Replace the client-driven login (Flutter guesses account state, e.g. expects admin-created users to leave the password field empty) with a server-driven model. Flutter sends the phone number to one unified `check-identifier` endpoint; the server reads the database, decides what happens next, and returns an explicit `action` string. Flutter only obeys. Add a Forgot-Password flow. Email OTP is delivered by the project's own Gmail SMTP (no Firebase/Twilio/paid SMS for auth). A server-side `EMAIL_OTP_ENABLED` flag toggles OTP enforcement."*

Cross-references:
- [specs/login/spec.md](../login/spec.md) — existing Firebase phone-SMS / social / email-password login (the flow this **supersedes** behind a flag).
- [specs/otp/spec.md](../otp/spec.md) — existing SMS verification screen (reused chrome).
- [specs/email_otp/spec.md](../email_otp/spec.md) — active email-OTP **login** fallback; this feature folds its OTP machinery into the `VERIFY_EMAIL_OTP` / `VERIFY_RESET_OTP` actions (see §Relationship to sibling features).
- [specs/phone_password_login/spec.md](../phone_password_login/spec.md) — draft phone+password primary; this feature is the umbrella that `REQUIRE_PASSWORD` + `login` realize.
- [.specify/memory/constitution.md](../../.specify/memory/constitution.md) — Principles III (networking), IV (persistence), V (flavor), VI (localization), VIII (approval gate).
- **For per-team responsibilities + backend hand-off** see [contracts/integration-contract.md](contracts/integration-contract.md).

> **Scope note for this repo.** The Laravel + Botble backend lives in a **separate repository** that is not checked out here. Therefore this spec splits cleanly into two halves:
> - **Mobile half** — implemented in this repo (Flutter screens, `AuthActionDispatcher`, data layer), behind the `server_driven_auth_enabled` rollout flag.
> - **Backend half** — **documented, not coded**, in [contracts/](contracts/). Those files are the requirement + integration contract handed to the backend team so they can update their own spec and build the 8 endpoints. Any API change this feature requests is listed there.

## Relationship to sibling features *(read this first)*

This feature is the **umbrella** for app authentication. It does not throw away the in-flight work; it gives it one coherent control plane:

| Sibling feature | How it folds in under server-driven auth |
|---|---|
| `phone_password_login` (draft) | The `REQUIRE_PASSWORD` action + `POST /auth/login` (phone+password) **are** the phone-password primary. Biometric login remains a separate Layer-2 concern on top. |
| `email_otp` (active) | Its OTP generation/hashing/TTL/attempts machinery is reused for the `VERIFY_EMAIL_OTP` (registration) and `VERIFY_RESET_OTP` (password reset) actions. **Difference from `email_otp`:** that feature uses email OTP as a *login* method; here OTP verifies a *newly registered email* and *authorizes a password reset*. Same machinery, different trigger. The login-by-email-OTP path may continue to exist independently, gated by `email_otp_globally_visible`. |
| `login` / `otp` / `register` (migrated) | Their Firebase-SMS + client-driven flow stays in the codebase and runs whenever `server_driven_auth_enabled == false`. When the flag is `true`, the `check-identifier`-driven flow described here takes over. |

**Two distinct flags, do not conflate them:**

1. **`server_driven_auth_enabled`** — *client-side rollout flag*, read from Firestore `config/*` via `ConfigCubit` (default `false`). Controls whether the **app** uses the new server-driven flow or the legacy Firebase flow. This is the "flag, don't delete" lever.
2. **`EMAIL_OTP_ENABLED`** — *server-side flag* (Laravel `config('auth.email_otp_enabled')`, default `true`). Controls whether the **backend** enforces the OTP email step in self-register and forgot-password. **Mobile never reads this** — it only obeys whichever `action` the server returns.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**: minimal. The same screens serve both flavors. The only flavor input to auth is the **role sent at the unified entry call** — `context.isProfessors ? 'teacher' : 'parent'` — preserved from today ([login_impl.dart:30](../../lib/features/login/data_sources/login_impl.dart#L30)). The server's response (`action`, `user.type`) is canonical thereafter.
- **Server role implication**: role rides in the `check-identifier` / `self-register` request body, exactly as it rides in `/auth/login` today. No client-side role inference after login.

## User Scenarios & Testing *(mandatory)*

The master prompt defines **five canonical scenarios**. They map to the user stories below. Every story is independently testable against a backend stub returning the documented `action`.

### User Story 1 — Admin-created user, first login (Priority: P1) 🎯 MVP

An admin created the account in Botble (phone + email; `password = NULL`, `status = 'create'`). The user opens the app, enters their phone, taps **Next**. `check-identifier` returns `CREATE_NEW_PASSWORD` + a `set-password`-scoped `temp_token`. The app force-navigates to **SetInitialPasswordScreen** (no back button). The user sets a password → `set-initial-password` → server hashes it, flips `status = 'active'`, returns the final JWT → the app stores it and routes through the approval gate to Home.

**Why this priority**: This is the only way an admin-provisioned family/teacher can ever get into the app. Without it, admin-created accounts are unusable.

**Independent Test**:
1. Point the app at a backend stub (or staging) where the test phone resolves to `password IS NULL, status = 'create'`.
2. Enter the phone, tap Next.
3. Assert the app navigates to `SetInitialPasswordScreen` and the OS/app back gesture is suppressed.
4. Enter a valid matching password + confirm, submit.
5. Assert `POST /auth/set-initial-password` is sent with the `temp_token`, a JWT comes back, and the app lands on `MainScreen` (or `YourAccountUnderReviewScreen` if `is_approval == false`).

**Acceptance Scenarios**:
1. **Given** a phone whose DB row has `password IS NULL AND status = 'create'`, **When** the user taps Next, **Then** the app POSTs `check-identifier` and receives `{ action: "CREATE_NEW_PASSWORD", temp_token, user }`.
2. **Given** that response, **When** the dispatcher runs, **Then** the app navigates to `SetInitialPasswordScreen` wrapped in `PopScope(canPop: false)`.
3. **Given** a valid password + matching confirmation, **When** the user submits, **Then** the app POSTs `set-initial-password` with the `temp_token`, receives a JWT + UserModel, calls `UserBloc.loggedIn(user)`, and applies the approval gate.

---

### User Story 2 — Self-registration via app (Priority: P1)

On the login screen the user taps **"Create new account"** → **SelfRegisterScreen** (name, phone, email, password, confirm). On submit, `self-register` creates a `status = 'pending'`, `email_verified = false` row.

- **If `EMAIL_OTP_ENABLED = true` (default):** server emails a 6-digit OTP (queued Gmail SMTP job) and returns `VERIFY_EMAIL_OTP` + `temp_token`. App → **EmailOtpScreen** → user enters OTP → `verify-email-otp` flips `email_verified = true` → server returns `GO_TO_PENDING_APPROVAL` → app → **PendingApprovalScreen**.
- **If `EMAIL_OTP_ENABLED = false`:** server skips OTP, sets `email_verified = true` immediately, returns `GO_TO_PENDING_APPROVAL`. App goes straight to **PendingApprovalScreen** — no OTP screen, no email.

**Why this priority**: Self-service onboarding for families whose school did not pre-provision them.

**Independent Test**: With the flag `true`, register a new account, receive an OTP in the test Gmail inbox within ~30 s, enter it, and assert arrival on `PendingApprovalScreen`. Repeat with the flag `false` and assert the OTP screen is skipped.

**Acceptance Scenarios**:
1. **Given** the registration form is valid, **When** submitted, **Then** the app POSTs `self-register` and obeys whichever of `VERIFY_EMAIL_OTP` / `GO_TO_PENDING_APPROVAL` the server returns — **with no client knowledge of the flag**.
2. **Given** `VERIFY_EMAIL_OTP`, **When** the user enters the correct OTP on `EmailOtpScreen`, **Then** `verify-email-otp` returns `GO_TO_PENDING_APPROVAL` and the app navigates to `PendingApprovalScreen`.
3. **Given** `EmailOtpScreen`, **When** 60 s elapse, **Then** a Resend control becomes enabled and re-triggers the OTP email.

---

### User Story 3 — Admin-created user, subsequent logins (Priority: P1)

The user already set their password (`password != NULL, status = 'active'`). They enter their phone → `check-identifier` returns `REQUIRE_PASSWORD`. The app **does not navigate** — it reveals a password field **inline on the same LoginScreen** (state `LoginPasswordRequired`). The user enters the password → `login` → JWT → Home.

**Why this priority**: The steady-state daily login for every returning admin-provisioned user.

**Independent Test**: Enter a known-active phone, tap Next, assert the password field appears *inline* (no route push, no flicker). Enter the password, assert `POST /auth/login` and arrival on Home.

**Acceptance Scenarios**:
1. **Given** an `active` phone with a password set, **When** the user taps Next, **Then** the app receives `REQUIRE_PASSWORD` and transitions `LoginScreen` to `LoginPasswordRequired` (inline reveal, no navigation).
2. **Given** the inline password field, **When** the user submits the correct password, **Then** `POST /auth/login` returns a JWT + UserModel and the app applies the approval gate.
3. **Given** `LoginPasswordRequired` is active, **When** the screen renders, **Then** a **"Forgot password?"** control is visible directly below the password field (see US-5).

---

### User Story 4 — Self-registered user, post-admin-approval (Priority: P2)

Identical to US-3. Once an admin flips the self-registered user from `pending` → `active`, `check-identifier` returns `REQUIRE_PASSWORD` and the user logs in with the password they chose at registration.

**Independent Test**: Flip a `pending` test user to `active` server-side, then log in with phone + the registration password; assert success.

**Acceptance Scenarios**:
1. **Given** a previously `pending` user is now `active`, **When** they enter their phone, **Then** `check-identifier` returns `REQUIRE_PASSWORD` (not `GO_TO_PENDING_APPROVAL`).
2. **Given** the inline password, **When** they submit the registration password, **Then** login succeeds.

---

### User Story 5 — Forgot password (Priority: P2) *(NEW)*

While the inline password field is shown (`LoginPasswordRequired`), a **"Forgot password?"** control is visible. Tapping it → **ForgotPasswordEmailScreen** (single email field + Send code). The user enters their email → `forgot-password`.

- **If `EMAIL_OTP_ENABLED = true`:** server emails a reset OTP and returns `VERIFY_RESET_OTP` + `temp_token`. App → **ResetOtpScreen** → user enters OTP → `verify-reset-otp` returns `SET_NEW_PASSWORD` + a `reset-password`-scoped `temp_token` → app → **SetNewPasswordScreen**.
- **If `EMAIL_OTP_ENABLED = false`:** **password reset is blocked** server-side (returns `PASSWORD_RESET_UNAVAILABLE`). Disabling OTP for reset would let anyone who knows an email reset the password — so reset, unlike self-register, is *not* bypassed. App surfaces the localized "reset unavailable" message.

On submit, `reset-password` consumes the `reset-password` token, updates the hash, **invalidates all existing JWTs** for the user, returns success. App shows a success snackbar and returns to **LoginScreen** with the stack cleared.

**Why this priority**: Account recovery; without it a forgotten password is a support ticket.

**Independent Test**: From `LoginPasswordRequired`, tap Forgot password, enter a registered email, receive the reset OTP, enter it, set a new password, assert return to a cleared `LoginScreen`, then log in with the new password.

**Acceptance Scenarios**:
1. **Given** `LoginPasswordRequired`, **When** the user taps "Forgot password?", **Then** the app navigates to `ForgotPasswordEmailScreen`.
2. **Given** a registered, active email, **When** the user taps Send code, **Then** the app POSTs `forgot-password` and obeys the returned action (`VERIFY_RESET_OTP` when OTP enforced).
3. **Given** a correct reset OTP, **When** entered on `ResetOtpScreen`, **Then** `verify-reset-otp` returns `SET_NEW_PASSWORD` + a `reset-password`-scoped `temp_token`.
4. **Given** a valid new password on `SetNewPasswordScreen`, **When** submitted, **Then** `reset-password` succeeds and the app returns to `LoginScreen` with the navigation stack cleared.
5. **Given** an **unregistered** email, **When** Send code is tapped, **Then** the server returns the **same response shape** as success (no enumeration leak); the dummy `temp_token` fails at the next step.

---

### Edge Cases

- **`NOT_FOUND`**: phone not in DB → `check-identifier` returns `NOT_FOUND` → LoginScreen shows an inline "No account found. Create one?" prompt linking to SelfRegisterScreen. **No 422/401.**
- **`ACCOUNT_SUSPENDED`**: `status = 'suspended'` → `ACCOUNT_SUSPENDED` → inline suspended-account error; no password field, no navigation.
- **Expired / reused `temp_token`**: any `set-password` / `reset-password` token is single-use and 10-min TTL. A consumed or expired token on `set-initial-password` / `reset-password` returns the documented `TOKEN_INVALID` error → app surfaces a localized message and routes back to the start of that sub-flow.
- **Wrong-scope token**: a `set-password` token presented to `reset-password` (or vice versa) is rejected server-side → `TOKEN_SCOPE_MISMATCH`.
- **OTP attempts exhausted**: ≥ 5 wrong OTP entries invalidate the code → app forces the user back to the email/registration entry point.
- **Forgot-password while OTP disabled**: server returns `PASSWORD_RESET_UNAVAILABLE` → app shows `sda_error_reset_unavailable`; the user is told to contact the administrator.
- **Approval gate after every terminal success**: any path that yields a JWT (`set-initial-password`, `login`) must route through the existing `isApproval` gate (Principle VIII).
- **Flag off (`server_driven_auth_enabled == false`)**: none of the above applies; LoginScreen renders the legacy Firebase phone-OTP / social / email-password UI exactly as today.
- **Mid-flow app kill**: `temp_token`s are **not** persisted across cold start (they are short-lived, in-memory). Relaunching returns the user to LoginScreen; they restart the relevant sub-flow.
- **Unknown action string**: any `action` the dispatcher does not recognize surfaces `sda_error_unknown_action` and logs to Crashlytics (defends against backend/app version skew).

## Requirements *(mandatory)*

### Functional Requirements

#### Rollout flag & entry

- **FR-SDA-01**: When `ConfigCubit.serverDrivenAuthEnabled == false`, the app MUST render and behave exactly as the legacy login (Firebase phone-OTP + social + email-password). No new screen, no behavior change. The legacy code path MUST remain in the codebase (not deleted).
- **FR-SDA-02**: When `serverDrivenAuthEnabled == true`, `LoginScreen` MUST show a phone field + Next button, a **"Create new account"** link, and (post-`REQUIRE_PASSWORD`) an inline password field. The Firebase SMS path is bypassed, not removed.
- **FR-SDA-03**: On Next, the app MUST POST `auth/check-identifier` with `{ phone, country_code, role }` (role from flavor) and route solely on the returned `action`. The app MUST perform **zero** local inference of account state (no empty-password detection, no account-type guessing, no cached account-state flags).

#### Action dispatch

- **FR-SDA-04**: A single `AuthActionDispatcher` MUST map every `action` string to exactly one navigation/state transition. No `action`-branching `if/else` may live in widgets. The complete vocabulary:

| `action` | Dispatcher behavior |
|---|---|
| `CREATE_NEW_PASSWORD` | navigate to `SetInitialPasswordScreen(tempToken)` |
| `REQUIRE_PASSWORD` | reveal inline password field on `LoginScreen` (no navigation) |
| `VERIFY_EMAIL_OTP` | navigate to `EmailOtpScreen(tempToken)` (registration flow) |
| `GO_TO_PENDING_APPROVAL` | navigate to `PendingApprovalScreen` |
| `VERIFY_RESET_OTP` | navigate to `ResetOtpScreen(tempToken)` |
| `SET_NEW_PASSWORD` | navigate to `SetNewPasswordScreen(tempToken)` |
| `NOT_FOUND` | show inline "no account found — create one?" prompt |
| `ACCOUNT_SUSPENDED` | show inline suspended-account error |
| *(unrecognized)* | show `sda_error_unknown_action`, log to Crashlytics |

- **FR-SDA-05**: The dispatcher MUST treat `action` strings as **case-sensitive, exact** matches to the table above.

#### Set / reset password screens

- **FR-SDA-06**: `SetInitialPasswordScreen` MUST be wrapped in `PopScope(canPop: false)` — the user cannot leave until the password is saved. On success it POSTs `auth/set-initial-password` with the `set-password` `temp_token`, receives a JWT + UserModel, calls `UserBloc.loggedIn(user)`, applies the approval gate.
- **FR-SDA-07**: `SetNewPasswordScreen` MUST be wrapped in `PopScope(canPop: false)` once the user is past OTP verification. On success it POSTs `auth/reset-password` with the `reset-password` `temp_token`. On success the app clears the navigation stack and returns to `LoginScreen` with a success snackbar.
- **FR-SDA-08**: Both screens MUST enforce client-side password rules (min length, confirm-match) before enabling submit, and surface server validation errors via the existing `ErrorField`.

#### OTP screens

- **FR-SDA-09**: `EmailOtpScreen` (registration) and `ResetOtpScreen` (reset) MUST be **distinct screens** (separate copy, separate back behavior) even though they share the pin widget. `EmailOtpScreen` POSTs `auth/verify-email-otp`; `ResetOtpScreen` POSTs `auth/verify-reset-otp`.
- **FR-SDA-10**: Both OTP screens MUST show a 60-second resend timer; the Resend control re-invokes the originating endpoint (`self-register` resend / `forgot-password`) and restarts the timer.
- **FR-SDA-11**: OTP screens MUST surface the documented OTP error codes (`code_expired`, `too_many_attempts`, `invalid_code`) via localized keys, never raw codes.

#### Forgot password

- **FR-SDA-12**: The "Forgot password?" control MUST appear **inline, directly below the password field, only when the state is `LoginPasswordRequired`** — never on the initial phone-entry state, never on its own standalone screen.
- **FR-SDA-13**: `ForgotPasswordEmailScreen` MUST contain a single email field + Send-code button. On send it POSTs `auth/forgot-password` with `{ email }` and obeys the returned action.
- **FR-SDA-14**: When `forgot-password` (or any reset step) returns `PASSWORD_RESET_UNAVAILABLE`, the app MUST surface `sda_error_reset_unavailable` and remain on `ForgotPasswordEmailScreen`.

#### Token & session

- **FR-SDA-15**: The final JWT returned by `set-initial-password` / `login` MUST be stored via the **existing** `UserBloc.loggedIn(user)` path (token inside `UserModel.accessToken`, persisted by the HydratedCubit). The app MUST NOT introduce a parallel token store. *(Deviation from the master prompt's `flutter_secure_storage` — see §Deviations.)*
- **FR-SDA-16**: `temp_token`s (`set-password`, `reset-password`) MUST be held only in transient screen/dispatcher state, never persisted to Hive/HydratedBloc.
- **FR-SDA-17**: After a successful password reset, the app MUST assume all prior sessions are invalidated server-side; if the current device held a session for that user, the next 401 triggers the existing interceptor logout.

#### Networking & errors

- **FR-SDA-18**: Every one of the 8 endpoints MUST be called through `NetworkClient.handleRequest` returning `Either<Failure, T>` (Constitution Principle III). No bespoke HTTP.
- **FR-SDA-19**: Non-success responses follow the uniform shape `{ "error": { "code": "...", "message": "..." } }`; the app MUST map `code` → a localized key and never display the raw `message`/`code`.
- **FR-SDA-20**: Phone numbers, emails, passwords, OTP codes, and `temp_token`s MUST be redacted from Crashlytics breadcrumbs — extend the `network_client` redaction allowlist to cover the 8 `auth/*` endpoints.

### Localization Requirements

All user-visible strings MUST be added to [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) with PT-BR (primary), EN, and AR translations, and be remote-overridable via Firestore `config/*`. New keys for v1:

| Key | pt (primary) | en | ar |
|---|---|---|---|
| `sda_phone_label` | "Telefone" | "Phone" | "الهاتف" |
| `sda_next_cta` | "Avançar" | "Next" | "التالي" |
| `sda_password_label` | "Senha" | "Password" | "كلمة المرور" |
| `sda_confirm_password_label` | "Confirmar senha" | "Confirm password" | "تأكيد كلمة المرور" |
| `sda_login_cta` | "Entrar" | "Log in" | "تسجيل الدخول" |
| `sda_create_account_link` | "Criar nova conta" | "Create new account" | "إنشاء حساب جديد" |
| `sda_forgot_password_cta` | "Esqueceu a senha?" | "Forgot password?" | "هل نسيت كلمة المرور؟" |
| `sda_set_initial_password_title` | "Crie sua senha" | "Create your password" | "أنشئ كلمة المرور" |
| `sda_set_new_password_title` | "Defina uma nova senha" | "Set a new password" | "تعيين كلمة مرور جديدة" |
| `sda_register_title` | "Criar conta" | "Create account" | "إنشاء حساب" |
| `sda_register_name_label` | "Nome completo" | "Full name" | "الاسم الكامل" |
| `sda_register_email_label` | "E-mail" | "Email" | "البريد الإلكتروني" |
| `sda_email_otp_title` | "Verifique seu e-mail" | "Verify your email" | "تحقق من بريدك الإلكتروني" |
| `sda_email_otp_subline` | "Enviamos um código para {email}." | "We sent a code to {email}." | "أرسلنا رمزًا إلى {email}." |
| `sda_reset_otp_title` | "Recuperar senha" | "Reset password" | "استعادة كلمة المرور" |
| `sda_reset_otp_subline` | "Digite o código enviado para {email}." | "Enter the code sent to {email}." | "أدخل الرمز المرسل إلى {email}." |
| `sda_forgot_email_title` | "Recuperar senha" | "Reset password" | "استعادة كلمة المرور" |
| `sda_forgot_email_hint` | "Seu e-mail cadastrado" | "Your registered email" | "بريدك الإلكتروني المسجل" |
| `sda_send_code_cta` | "Enviar código" | "Send code" | "إرسال الرمز" |
| `sda_resend_cta` | "Reenviar" | "Resend" | "إعادة إرسال" |
| `sda_resend_in` | "Reenviar em {seconds}s" | "Resend in {seconds}s" | "إعادة الإرسال خلال {seconds}ث" |
| `sda_pending_approval_title` | "Conta em análise" | "Account under review" | "الحساب قيد المراجعة" |
| `sda_pending_approval_body` | "Sua conta foi criada e está aguardando aprovação da escola." | "Your account was created and is awaiting school approval." | "تم إنشاء حسابك وهو بانتظار موافقة المدرسة." |
| `sda_back_to_login_cta` | "Voltar ao login" | "Back to login" | "العودة لتسجيل الدخول" |
| `sda_reset_success` | "Senha alterada. Faça login com a nova senha." | "Password changed. Log in with your new password." | "تم تغيير كلمة المرور. سجّل الدخول بكلمة المرور الجديدة." |
| `sda_no_account_prompt` | "Nenhuma conta encontrada. Deseja criar uma?" | "No account found. Create one?" | "لم يتم العثور على حساب. هل تريد إنشاء واحد؟" |
| `sda_error_account_suspended` | "Conta suspensa. Entre em contato com a escola." | "Account suspended. Contact your school." | "الحساب موقوف. تواصل مع مدرستك." |
| `sda_error_reset_unavailable` | "A recuperação de senha está indisponível no momento. Contate o administrador." | "Password reset is currently unavailable. Contact the administrator." | "استعادة كلمة المرور غير متاحة حاليًا. تواصل مع المسؤول." |
| `sda_error_token_invalid` | "Sessão expirada. Recomece o processo." | "Session expired. Please start over." | "انتهت الجلسة. ابدأ من جديد." |
| `sda_error_otp_expired` | "Código expirado. Solicite um novo." | "Code expired. Request a new one." | "انتهت صلاحية الرمز. اطلب رمزًا جديدًا." |
| `sda_error_otp_too_many` | "Muitas tentativas. Solicite um novo código." | "Too many attempts. Request a new code." | "محاولات كثيرة. اطلب رمزًا جديدًا." |
| `sda_error_invalid_credentials` | "Telefone ou senha incorretos." | "Incorrect phone or password." | "رقم الهاتف أو كلمة المرور غير صحيحة." |
| `sda_error_password_mismatch` | "As senhas não coincidem." | "Passwords do not match." | "كلمتا المرور غير متطابقتين." |
| `sda_error_password_weak` | "A senha deve ter no mínimo 8 caracteres." | "Password must be at least 8 characters." | "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل." |
| `sda_error_unknown_action` | "Não foi possível continuar. Atualize o aplicativo." | "Could not continue. Please update the app." | "تعذّر المتابعة. يرجى تحديث التطبيق." |
| `sda_error_generic` | "Algo deu errado. Tente novamente." | "Something went wrong. Try again." | "حدث خطأ ما. حاول مرة أخرى." |

### Backend Touchpoints

All under `criarte.filhos.app/api/v1/auth/`. The full request/response contract, error codes, DB schema, security rules, and the Gmail-SMTP/`EMAIL_OTP_ENABLED` model are documented for the backend team in [contracts/](contracts/):

- [contracts/rest-endpoints.md](contracts/rest-endpoints.md) — all 8 endpoints + action vocabulary + flag branching.
- [contracts/database-changes.md](contracts/database-changes.md) — `users` changes + `password_reset_otps` + backfill.
- [contracts/security.md](contracts/security.md) — rate limits, scoped single-use tokens, session invalidation, enumeration prevention.
- [contracts/email-otp.md](contracts/email-otp.md) — Gmail SMTP, queued job, OTP lifecycle, `EMAIL_OTP_ENABLED` flag matrix + artisan health-check.
- [contracts/integration-contract.md](contracts/integration-contract.md) — team-by-team hand-off.

The 8 endpoints: `check-identifier`, `set-initial-password`, `self-register`, `verify-email-otp`, `login`, `forgot-password`, `verify-reset-otp`, `reset-password`.

> **Mobile does NOT use Firebase for any of these.** Firebase Auth remains in the codebase only for the legacy SMS path (flag off) and for non-auth Firebase usage (Firestore chat, FCM, Crashlytics). No Firebase/Twilio/AWS SNS is added for server-driven auth.

### Permissions & Approval Gate

- `check-identifier`, `self-register`, `forgot-password`, the OTP-verify endpoints, and `set-initial-password`/`reset-password` are **pre-login** (no `Authorization` header).
- Every terminal JWT success routes through the existing approval gate (Principle VIII): `isApproval == false` → `YourAccountUnderReviewScreen`.
- No new device permissions.

### Key Entities (mobile-side)

- **`AuthAction`** *(new enum)* — the 8 strings above, parsed from the server response; an `unknown` fallthrough variant.
- **`CheckIdentifierRequest`** — `{ phone, countryCode, role }`.
- **`AuthActionResponse`** — `{ action: AuthAction, tempToken: String?, user: UserModel?, expiresIn: int? }` — the uniform envelope every entry/step endpoint returns.
- **`SelfRegisterRequest`** — `{ name, phone, countryCode, email, password, confirmPassword, role }`.
- **`SetPasswordRequest`** — `{ tempToken, password, confirmPassword }` (used by both set-initial and reset; the scope is enforced server-side by token).
- **`OtpVerifyRequest`** — `{ tempToken, code }`.
- **`ForgotPasswordRequest`** — `{ email }`.
- The final authenticated response reuses the existing **`UserModel`** + `access_token` shape so `UserBloc.loggedIn` drops in unchanged.

## Success Criteria *(mandatory)*

- **SC-SDA-01**: With the flag `false`, the login screen and flow are byte-for-behavior identical to today (zero regression in the legacy Firebase path), verified on both flavors.
- **SC-SDA-02**: With the flag `true`, all five scenarios complete end-to-end against a backend stub returning the documented actions, on both flavors.
- **SC-SDA-03**: A non-existent phone returns a clean "create account?" prompt — **no 422/401 surfaced to the user** (master-prompt acceptance #7).
- **SC-SDA-04**: A non-existent email in forgot-password yields the same UX as a valid email (no enumeration leak; acceptance #8), as observed from the client.
- **SC-SDA-05**: Static audit: **zero** client-side account-state inference remains in the server-driven path (acceptance #9). Grep for empty-password detection / account-type inference in the new code returns nothing.
- **SC-SDA-06**: All 8 endpoints have request/response examples in the spec-kit (acceptance #11); all action strings in code match the spec exactly (case-sensitive).
- **SC-SDA-07**: No new Firebase/Twilio/AWS-SNS reference is introduced for auth (acceptance #13).
- **SC-SDA-08**: `flutter analyze` clean and both flavors build with the new screens compiled in (flag on and off).

## Assumptions

- The backend (separate repo) will implement the 8 endpoints, the DB migration, the queued Gmail-SMTP OTP mail, and the `EMAIL_OTP_ENABLED` flag exactly as documented in [contracts/](contracts/). Until then, the mobile flow is exercised against a stub and ships dark behind `server_driven_auth_enabled = false`.
- Email uniqueness across schools holds (same assumption as `email_otp`); collision handling is out of scope for v1.
- The `users` table is the app-user table the mobile API already authenticates against (`/auth/login`). Whether that is the Botble-managed `users` table or a separate `app_users` table is an **open question for the backend team** — flagged in [contracts/database-changes.md](contracts/database-changes.md) so admin-panel auth is not collided with.
- The existing `UserModel` JSON (`access_token`, `is_approval`, `role`) is returned unchanged by `set-initial-password` / `login` / `verify-email-otp`.
- Gmail SMTP App Password + `EMAIL_OTP_ENABLED` live only in the backend `.env`; mobile never sees them.

## Deviations from the master prompt *(deliberate, with rationale)*

1. **"Delete all old client-driven auth" → kept, flag-gated.** The backend endpoints do not exist yet (separate repo). A hard cutover now would brick login for every user. Instead the new flow ships behind `server_driven_auth_enabled` (default `false`); the legacy Firebase path stays until the backend is live and the flag is flipped per the cutover task in [tasks.md](tasks.md). *(Confirmed with product owner 2026-05-25: "flag on Firebase, pass not delete.")*
2. **`flutter_secure_storage` → existing `UserBloc`/Hydrated storage.** The codebase has no `flutter_secure_storage` dependency and CLAUDE.md + Constitution Principle IV forbid bypassing `LocalDatabaseRepo`/HydratedBloc for token state. The JWT continues to live in `UserModel.accessToken` persisted by `UserBloc`. Migrating to secure storage is tracked as a separate hardening item, not bundled into this refactor.
3. **Backend coded here → backend documented here.** The Laravel/Botble backend is in another repository; per the product owner this feature delivers the backend half as a **requirement + integration contract** ([contracts/](contracts/)) for that team, plus the fully-implemented Flutter half.

## Open items

- Confirm `users` vs `app_users` with the backend team before they write the migration (see [contracts/database-changes.md](contracts/database-changes.md)).
- Decide whether the legacy social-login (Google/FB/Apple) buttons remain visible when `server_driven_auth_enabled == true` (current assumption: hidden in the server-driven flow; revisit with product).
- Biometric login (from `phone_password_login` draft) layering on top of `REQUIRE_PASSWORD` — deferred to that feature.
