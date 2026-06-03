---
status: draft
feature: email_otp
flavor_scope: both
seeded_from: user request 2026-05-19 (SMS provider unreliability in some countries)
clarifications_session: 2026-05-19
created: 2026-05-19
---

# Feature Specification: Email OTP — login by email-delivered code

**Feature Branch**: `(operating on Nour_main alongside sibling work)`

**Created**: 2026-05-19

**Status**: Draft

**Input**: User description (paraphrased): *"Send OTP numbers through email and clearly indicate that OTP was sent to email when the school is configured for email-OTP instead of SMS, because some countries have issues with the SMS provider. We plan to use Firebase to send the email, or pick another provider — recommend based on stability and free tier."*

Cross-references: [specs/otp/spec.md](../otp/spec.md) (existing SMS OTP), [specs/login/spec.md](../login/spec.md), [CLAUDE.md §1.2 Sign-in flow](../../CLAUDE.md#12-core-user-flows). **For per-team responsibilities + setup checklists** see [contracts/integration-contract.md](contracts/integration-contract.md).

> ℹ️ **Relationship to `server_driven_auth`** *(added 2026-06-01).* This spec defines email OTP as a **login** method (the user picks the "E-mail" tab on LoginScreen and verifies via emailed code). The umbrella `server_driven_auth` feature uses a **different** email-OTP machinery for two other purposes — registration email verification (`VERIFY_EMAIL_OTP`) and forgot-password (`VERIFY_RESET_OTP`) — delivered via the project's own **Gmail SMTP** account (not the Firebase "Trigger Email from Firestore" + SendGrid pipeline this spec uses). The two paths are orthogonal: `email_otp_globally_visible` controls whether this spec's login-by-email-OTP tab is shown; `server_driven_auth_enabled` controls whether the umbrella's `check-identifier`-driven flow takes over LoginScreen. See [specs/server_driven_auth/spec.md §Relationship to sibling features](../server_driven_auth/spec.md).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores)
- **Flavor-conditional behavior**: none. The flow is identical to SMS OTP — the existing `OTPScreen` is reused with a mode flag (`OTPDeliveryMode.email | .sms`). The flavor is set during the prior login call (same as today).
- **Server role implication**: the role (`parent` | `teacher`) continues to ride in the body of the login-completion call after verification, exactly as in the SMS flow ([login_impl.dart:30](../../lib/features/login/data_sources/login_impl.dart#L30)).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Receive and verify a 6-digit email OTP (Priority: P1) 🎯 MVP

A user whose school's SMS provider is unreliable taps the **"E-mail"** tab on the login screen, enters their account email, taps Send. They receive a 6-digit code via email within ~30 s, type it into the existing pin field on `OTPScreen` (which now clearly says "Código enviado para s\*\*\*@example.com"), and the app logs them in exactly as the SMS path does today.

**Why this priority**: Without this path, users in regions where SMS is unreliable cannot log in at all — the SMS OTP is the only verification today.

**Independent Test**:
1. Enable email OTP for a test school in Firestore (`config/{schoolId}.email_otp_enabled = true`).
2. On the parents flavor login screen, tap the "E-mail" tab.
3. Type the test user's email, tap Send.
4. Verify (via SendGrid / Firebase Extension logs) that the email is dispatched.
5. Receive the email in the test inbox, copy the 6-digit code.
6. Land on `OTPScreen`. Confirm the masked email is displayed and the localized "código enviado para seu e-mail" indicator is visible (not the SMS phrase).
7. Enter the code → land on `MainScreen` (or `YourAccountUnderReviewScreen` if `isApproval == false`).

**Acceptance Scenarios**:

1. **Given** the login screen, **When** the user taps the "E-mail" tab, **Then** the phone input is replaced by an email input with the localized placeholder `email_otp_email_placeholder`.
2. **Given** a valid email format in the input, **When** the user taps Send, **Then** the app POSTs `/auth/email-otp/send` and navigates to `OTPScreen(mode: email, maskedEmail: "s***@example.com")`.
3. **Given** the user is on `OTPScreen` in email mode, **When** they type the 6-digit code, **Then** the app POSTs `/auth/email-otp/verify` and on success calls `UserBloc.loggedIn(user)` (identical to SMS path).
4. **Given** the verification screen, **When** rendered in email mode, **Then** the line "Código enviado para `<masked-email>`" appears in place of the SMS phone line, with the email visibly distinct (e.g., medium-weight text, copy-to-clipboard disabled).
5. **Given** the user submits an invalid code, **When** the backend returns 400 `invalid-verification-code`, **Then** the existing `ErrorField` surfaces above the pin field with the localized message — same component as SMS.

---

### User Story 2 — Resend email OTP after cooldown (Priority: P2)

The user didn't receive the email (spam folder, slow MTA) and taps **"Enviar novamente"** after the 60-second cooldown elapses.

**Why this priority**: Email deliverability fluctuates more than SMS in some hours/networks; a second-chance path is essential.

**Independent Test**: After sending the first OTP, wait 60 s, tap resend → verify a new email arrives and the cooldown restarts.

**Acceptance Scenarios**:

1. **Given** an active 60-second cooldown, **When** the user taps Resend, **Then** the button is disabled and shows the remaining seconds (parallel to the SMS resend behavior).
2. **Given** the cooldown has elapsed, **When** the user taps Resend, **Then** the app POSTs `/auth/email-otp/send` for the same email, the cooldown timer restarts, and any previous unused code is invalidated server-side.
3. **Given** the server returns 429 with `Retry-After: 30`, **When** the resend fires before the server's window, **Then** the UI surfaces `email_otp_error_too_soon` and aligns the local timer to the server's value.

---

### User Story 3 — UI must clearly signal "email mode" so users don't check the wrong inbox (Priority: P1, bundled with US-1)

This is not a separate flow — it is a requirement *on top of* US-1's verification screen. The user's request explicitly emphasized "highlight that OTP was sent to email." Captured here so it is testable independently.

**Acceptance Scenarios**:

1. **Given** the verification screen in email mode, **When** rendered, **Then** the screen displays an icon distinct from the SMS icon (e.g., envelope vs. phone), the masked email, and the localized line "Verifique sua caixa de entrada e a pasta de spam".
2. **Given** the verification screen in SMS mode, **When** rendered, **Then** the email-mode chrome (envelope icon, "verifique seu e-mail" copy) is absent — no visual ambiguity about which channel was used.
3. **Given** the verification screen in email mode and a slow MTA, **When** more than 30 s elapse with no code entered, **Then** a subtle hint surfaces: "Não chegou? Verifique a pasta de spam ou solicite novamente em {seconds}s".

---

### Edge Cases

- **User picks "E-mail" tab but their school doesn't have email OTP enabled**: Backend returns `422 email_otp_not_enabled_for_school` → mobile surfaces `email_otp_error_not_enabled` ("Sua escola usa OTP por telefone. Use a aba 'Telefone'."). Tab UI nudges the user back to the phone tab.
- **Email format invalid** (no `@`, no TLD): Send button stays disabled; helper text surfaces under the field.
- **Email not registered** in the backend (no user matches): Backend returns `404 email_not_found` → mobile shows `email_otp_error_not_registered` ("Não encontramos uma conta com este e-mail. Verifique com sua escola.").
- **Trigger Email extension / SendGrid SMTP failure**: Backend logs the failure, returns `503 email_send_failed` → mobile shows `email_otp_error_send_failed` ("Não foi possível enviar agora. Tente em alguns minutos."). Cooldown does **not** start so the user can immediately retry.
- **Code expired** (>5 min after send): Backend returns `410 code_expired` → mobile surfaces `email_otp_error_expired` and re-enables Send (skips remaining cooldown).
- **Too many verification attempts** (≥5 wrong codes on the same OTP): Backend returns `429 too_many_attempts`, invalidates the code → mobile forces user back to email entry.
- **User switches from Email tab to Telefone tab mid-flow**: Email state is cleared. No partial state carries across tabs.
- **User has SMS-only school but somehow ends up on email tab via deep link**: Same as "school doesn't have email OTP enabled" — backend gates it.
- **Approval gate**: After email-OTP success, a user with `isApproval == false` is routed to `your_account_under_review` (constitution Principle VIII), exactly like the SMS path.
- **User in transit (locale switch)**: If user switches `lang` between Send and Verify, the next OTP email is rendered in the new language (template lookup uses request-time `lang`). The pending code remains valid; only the email copy language changes.
- **Email delivered to a forwarding alias** (e.g., `parent+criarte@example.com`): Verification works — backend matches against the canonical address registered on the user record, not the alias.

## Requirements *(mandatory)*

### Functional Requirements

#### Login screen — tab/mode picker

- **FR-EM-01**: The login screen MUST render **two tabs** — "Telefone" and "E-mail" — when the global feature flag `email_otp_globally_visible` (in `ConfigCubit`, sourced from Firestore org-wide `config/*`) is `true`. When the flag is `false`, the email tab is absent and the screen renders exactly as today.
- **FR-EM-02**: The "Telefone" tab MUST be the default-selected tab. The selection persists across hot restarts via the existing `LocalDatabaseRepo` (new key: `last_login_mode`).
- **FR-EM-03**: Switching tabs MUST clear the inactive tab's state (entered phone or email), not merge it.

#### Email entry

- **FR-EM-04**: The email field MUST validate format client-side using a permissive RFC-flavored check (`contains '@'`, has a TLD with ≥ 2 chars, no whitespace). The Send button MUST stay disabled until format passes.
- **FR-EM-05**: On Send, the app MUST POST `/auth/email-otp/send` with body `{email: string, lang: "pt" | "en" | "ar"}`. The `lang` is read from `ConfigCubit` (current user language).
- **FR-EM-06**: A loading indicator MUST replace the Send button text while the request is in flight; the field MUST be locked.
- **FR-EM-07**: On a successful response, the app MUST navigate to `OTPScreen(mode: OTPDeliveryMode.email, identifier: <masked-email>)`.

#### Verification screen — email mode

- **FR-EM-08**: `OTPScreen` MUST accept a `mode: OTPDeliveryMode` parameter (`sms` | `email`) and render mode-specific chrome:
  - **icon**: envelope (email) vs. phone (sms)
  - **headline**: `email_otp_verify_title` vs. existing `otp_verify_title`
  - **subline**: "Código enviado para `<masked-email>`. Verifique sua caixa de entrada e a pasta de spam." vs. the SMS phrase
- **FR-EM-09**: The displayed email MUST be **masked** (`s***@example.com`): first character + `***` + everything from `@` onward. Never display the full email on this screen.
- **FR-EM-10**: On 6-digit entry, the app MUST POST `/auth/email-otp/verify` with body `{email: string, code: string}`. The response shape is identical to the SMS verify response: `{access_token: string, data: <UserModel JSON>}`.
- **FR-EM-11**: On success, the app MUST call `UserBloc.loggedIn(user)` (identical to SMS path). The approval gate logic (`isApproval == true` → `MainScreen`; else → `YourAccountUnderReviewScreen`) is unchanged.

#### Resend & cooldown

- **FR-EM-12**: A 60-second cooldown MUST apply between consecutive `/auth/email-otp/send` calls per email. The mobile cooldown mirrors the existing SMS cooldown (`otpTimeout = 60`).
- **FR-EM-13**: The cooldown MUST be enforced **both** client-side (visible timer, disabled button) and server-side (returns `429 already_sent` with `Retry-After` if breached).
- **FR-EM-14**: Cooldown state MUST use parallel Hive keys to the existing pattern: `last_email_otp_request` (millis) and `last_email_otp_email` (string). Distinct keys so SMS and email cooldowns do not interfere with each other.
- **FR-EM-15**: When the server returns `410 code_expired`, the mobile MUST clear `last_email_otp_request` and unlock Send immediately — the cooldown does not apply to an expired-code recovery flow.

#### Errors

- **FR-EM-16**: All error responses MUST map to `NetworkFailure(message: <code>)` and surface via the existing `ErrorField` widget. Error codes used: `email_otp_not_enabled_for_school` (422), `email_not_found` (404), `invalid-verification-code` (400), `code_expired` (410), `too_many_attempts` (429 on verify), `already_sent` (429 on send), `email_send_failed` (503).
- **FR-EM-17**: The mobile app MUST localize each error code via `LocalizationKeys.email_otp_error_*` keys — never display raw API codes to users.

#### LGPD & audit

- **FR-EM-18**: Neither the email address nor the OTP code MUST appear in Crashlytics breadcrumbs. Extend the `network_client._redactBody` allowlist to cover `/auth/email-otp/*` endpoints (same pattern used for medication payloads).
- **FR-EM-19**: The existing "Delete my account" / "Delete my data" path MUST trigger backend cleanup of any pending OTP records and the 90-day audit log for the user's email.
- **FR-EM-20**: Per-school enablement is **not** stored on the device. The mobile app never reads `email_otp_enabled` directly — the backend enforces it on `/send` and returns 422 if disallowed.

### Localization Requirements

All user-visible strings MUST be added as keys in [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) with PT-BR (primary), EN, and AR translations. Keys for v1:

| Key | pt (primary) | en | ar |
|---|---|---|---|
| `email_otp_tab_label` | "E-mail" | "Email" | "بريد إلكتروني" |
| `email_otp_email_placeholder` | "Seu e-mail cadastrado" | "Your registered email" | (AR) |
| `email_otp_send_cta` | "Enviar código" | "Send code" | (AR) |
| `email_otp_verify_title` | "Verifique seu e-mail" | "Check your email" | (AR) |
| `email_otp_verify_subline` | "Código enviado para {maskedEmail}. Verifique sua caixa de entrada e a pasta de spam." | "Code sent to {maskedEmail}. Check your inbox and spam folder." | (AR) |
| `email_otp_check_spam_hint` | "Não chegou? Verifique a pasta de spam ou solicite novamente em {seconds}s." | "Didn't get it? Check spam or resend in {seconds}s." | (AR) |
| `email_otp_resend_cta` | "Enviar novamente" | "Resend" | (AR) |
| `email_otp_error_invalid_format` | "Formato de e-mail inválido." | "Invalid email format." | (AR) |
| `email_otp_error_not_enabled` | "Sua escola usa OTP por telefone. Use a aba 'Telefone'." | "Your school uses phone OTP. Use the 'Phone' tab." | (AR) |
| `email_otp_error_not_registered` | "Não encontramos uma conta com este e-mail. Verifique com sua escola." | "No account found with this email. Check with your school." | (AR) |
| `email_otp_error_send_failed` | "Não foi possível enviar agora. Tente em alguns minutos." | "Could not send right now. Try again in a few minutes." | (AR) |
| `email_otp_error_expired` | "Código expirado. Solicite um novo." | "Code expired. Request a new one." | (AR) |
| `email_otp_error_too_many_attempts` | "Muitas tentativas. Solicite um novo código." | "Too many attempts. Request a new code." | (AR) |
| `email_otp_error_too_soon` | "Aguarde {seconds}s para solicitar novamente." | "Wait {seconds}s before requesting again." | (AR) |
| `email_otp_error_generic` | "Não foi possível verificar agora. Tente novamente." | "Could not verify right now. Try again." | (AR) |

The same keys MUST also be remote-overridable via Firestore `config/*` translations (existing discipline).

**Email body templates** are stored separately, in Firestore `email_templates/email_otp_{lang}` (rendered server-side by the Trigger Email extension flow). Keys above govern the **in-app** copy; the **email body** has its own template doc that the backend renders into the `mail/*` document.

### Backend Touchpoints

#### REST — new endpoints on `criarte.filhos.app/api/v1/`

**`POST /auth/email-otp/send`**

Auth: none (pre-login endpoint, same as `/auth/login` and existing OTP request).

Request:
```json
{
  "email": "parent@example.com",
  "lang": "pt"
}
```

Response (success, `200`):
```json
{
  "success": true,
  "masked_email": "p***@example.com",
  "retry_after": 60
}
```

Errors (mapped to `NetworkFailure`):
- `422 email_otp_not_enabled_for_school` — user's school does not have email OTP enabled
- `404 email_not_found` — no user matches this email
- `429 already_sent` (with `Retry-After` header) — cooldown not yet elapsed
- `503 email_send_failed` — Firebase Extension or SendGrid down

Backend behavior:
1. Look up user by email (single-tenant — emails are unique across schools, or the backend resolves the right school in the rare collision case).
2. Read the user's `school_id` and Firestore `config/{schoolId}.email_otp_enabled` flag. If `false`, return `422`.
3. Generate a cryptographically-random 6-digit numeric code.
4. Store HMAC-SHA256(code, server-secret) in `email_otps` table with `(email, hash, school_id, expires_at = now+5min, attempts = 0)`. Replace any existing pending record for the same email.
5. Render the email body from `email_templates/email_otp_{lang}` Firestore template (server reads at start-up + on change).
6. Write a Firestore doc to `mail/{auto-id}`:
   ```json
   {
     "to": ["parent@example.com"],
     "message": {
       "subject": "Seu código Criarte: 123456",
       "html": "<rendered html with {{code}} substituted>",
       "text": "Seu código Criarte é: 123456. Ele expira em 5 minutos."
     }
   }
   ```
   The Firebase Extension "Trigger Email from Firestore" picks this up and dispatches via configured SendGrid SMTP. Backend does **not** poll — fire-and-forget. The extension writes delivery status back to the same doc (`delivery.state: SUCCESS | ERROR`) which the backend can monitor for failure metrics.
7. Return `200` (success) immediately after Firestore write succeeds (does **not** wait for SMTP send).

**`POST /auth/email-otp/verify`**

Request:
```json
{
  "email": "parent@example.com",
  "code": "123456"
}
```

Response (success, `200`) — same shape as the existing `/auth/login` response:
```json
{
  "data": { /* UserModel JSON */ },
  "access_token": "..."
}
```

Errors:
- `400 invalid-verification-code` — hash mismatch; increment `attempts`
- `410 code_expired` — `expires_at` passed
- `429 too_many_attempts` — `attempts >= 5`; invalidate the record

Backend behavior:
1. Look up the latest pending `email_otps` record for `email`.
2. Compare HMAC-SHA256(submitted_code) to stored hash.
3. On match: delete the record, mint an access token via the existing login token path, return user + token.
4. On mismatch: increment `attempts`; return 400 (or 429 if attempts ≥ 5).

#### Firebase — `mail/{autoId}` document (consumed by Trigger Email extension)

| Field | Type | Notes |
|---|---|---|
| `to` | `string[]` | One entry: the user's email |
| `message.subject` | `string` | Localized: "Seu código Criarte: 123456" (PT primary) |
| `message.html` | `string` | Full HTML body with code substituted |
| `message.text` | `string` | Plain-text fallback |
| `delivery.state` *(written by extension)* | `string` | `PENDING` → `PROCESSING` → `SUCCESS` / `ERROR` |
| `delivery.error` *(written by extension)* | `string?` | SMTP error string on failure |

Backend monitors `delivery.state` for failure metrics. Mobile **does not read this collection** — it is server-side observability only.

#### Firestore — `config/*` flags

- `config/{schoolId}.email_otp_enabled` *(bool)* — per-school toggle. **Backend reads only**; mobile never touches.
- `config/{globalDocId}.email_otp_globally_visible` *(bool)* — controls whether the mobile app shows the "E-mail" tab at all. Mobile reads from `ConfigCubit`.

#### Firestore — `email_templates/email_otp_{lang}`

Template doc per language. Fields:
- `subject_template` *(string)* — e.g., `"Seu código Criarte: {{code}}"`
- `html_template` *(string)* — full HTML body with `{{code}}` placeholder
- `text_template` *(string)* — plain-text body
- `updated_at` *(timestamp)*

Backend renders these into the `mail/` document body. Admin web can edit these without a release.

### Permissions & Approval Gate

- Pre-login endpoint — no `Authorization` header required.
- Post-success, the existing approval gate applies (constitution Principle VIII) — unchanged.
- Device permissions: none new.

### Key Entities

- **`EmailOTPSendRequest`** — `{email: String, lang: String}`. Built by the email-tab login flow.
- **`EmailOTPSendResponse`** — `{maskedEmail: String, retryAfter: int}`. Drives the OTPScreen subline.
- **`EmailOTPVerifyRequest`** — `{email: String, code: String}`.
- **`EmailOTPVerifyResponse`** — `{accessToken: String, user: UserModel}`. Identical shape to existing `/auth/login` response.
- **`OTPDeliveryMode`** *(new enum)* — `sms` | `email`. Threaded through `OTPScreen` so the same widget renders both flows.
- **`MailDocument`** *(Firestore, server-written)* — `{to: List<String>, message: {subject, html, text}, delivery: ...}`. Mobile does not interact with this; documented for backend ↔ extension contract.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-EM-01**: For pilot schools with `email_otp_enabled = true`, 95% of OTP emails are delivered (`delivery.state = SUCCESS`) within **30 seconds** of `/send` returning 200, measured over a 7-day window.
- **SC-EM-02**: Inbox deliverability (not bounced, not spam-foldered) is ≥ **98%** as reported by SendGrid dashboard over 30 days post-launch.
- **SC-EM-03**: For users whose first action is "tap E-mail tab", login success rate (= `/verify` returned 200) within 5 minutes of `/send` ≥ **90%**.
- **SC-EM-04**: 0 audit findings of OTP codes or email addresses appearing in Crashlytics breadcrumbs (extends FR-EM-18). Spot-check at least 100 staging-environment events.
- **SC-EM-05**: When an `email_otp_enabled = true` pilot is rolled out to a school previously suffering from SMS-delivery issues, that school's login completion rate (= reaching `MainScreen` from `LoginScreen`) increases by ≥ **15 percentage points** within 14 days.
- **SC-EM-06**: Server-side `/send` p95 latency ≤ **1.5 s** (the write to Firestore + the synchronous validation work). The email delivery itself is asynchronous and bounded by SendGrid SLA.

## Assumptions

- The **Firebase Extension "Trigger Email from Firestore"** is installable in the Criarte Firebase project (`escola-cede2`) and supports SendGrid SMTP credentials. (Verified: official extension by Firebase, public docs at `extensions.dev/extensions/firebase/firestore-send-email`.)
- A **SendGrid free-tier account** (100 emails/day) is sufficient for the pilot rollout. Volume will be re-evaluated after 30 days; upgrade path to Brevo/Mailgun is straightforward (the extension is SMTP-agnostic — only the SMTP creds change).
- The sender domain `noreply@criarte.filhos.app` (or similar) has **DKIM and SPF** records configured before launch. Without these, deliverability suffers significantly.
- **Email uniqueness**: emails are globally unique across schools in the backend user table. Collision handling (same email in multiple schools) is out of scope for v1 — if needed later, the `/send` endpoint can return a school picker.
- The existing `OTPScreen` is **refactored once** to accept the new `mode` parameter — both SMS and email paths use the same widget. No duplicate screen.
- The existing **`UserBloc.loggedIn(user)`** entry point is the single materialization path for a logged-in user, regardless of how they verified. Email OTP success calls the same method.
- **Rate-limit observability**: SendGrid dashboard + Firestore `mail/{autoId}.delivery.state` queries provide enough visibility for v1. No mobile-side delivery metric.
- **No client-side per-school flag read**: mobile never reads `email_otp_enabled` directly — see FR-EM-20. This keeps the mobile out of pre-login Firestore reads.
- **No email confirmation for new users**: this feature handles **login** OTP only. Email collection for new accounts happens via the school's admin web (out of mobile scope for this feature).

## Resolved Decisions

Three product decisions settled on 2026-05-19 via clarification:

1. **Email provider** — **Firebase Extensions "Trigger Email from Firestore" + SendGrid SMTP**. Rationale: Firebase-native pattern matches "we plan to use Firebase" intent; extension is free; SendGrid SMTP free tier (100/day) covers pilot scale; provider can be swapped to Brevo/Mailgun later without code change (only SMTP creds in the extension config). Considered and not chosen: **Resend** (newer, fewer war stories — would have been the recommendation for a greenfield project) and **Brevo** (EU-hosted; not Firebase-native).

2. **Trigger mode** — **Per-school admin toggle** via Firestore `config/{schoolId}.email_otp_enabled`. Backend reads this flag; if disabled, `/send` returns 422. Mobile never reads the flag directly. Considered and not chosen: user-choice toggle (extra UI complexity) and auto-fallback (more failure paths to test). The per-school approach matches the user's framing ("some countries have SMS issues") and lets pilots run school-by-school.

3. **Backend home** — **Existing REST backend at `criarte.filhos.app`** with new endpoints `POST /auth/email-otp/send` and `POST /auth/email-otp/verify`. Token issuance reuses the same path as `/auth/login`. Considered and not chosen: Firebase Cloud Functions (new infra, IAM setup, but no architectural win for this use case).

## Open items (defer to `/speckit-clarify email_otp` if blocking)

- Email-uniqueness collision handling (same email across multiple schools) — deferred to v1.x if it surfaces in pilot data.
- Should email OTP also be available for **first-time onboarding** (new account creation), or strictly login? Current spec is login-only.
- Should the user be able to **switch from SMS to email mid-session** (e.g., on the OTP screen, "Tente por e-mail")? Current spec says no — mode is locked at tab selection.
- DKIM/SPF setup is assumed; coordination with infra/DNS is out of mobile scope but tracked as a backend dependency.
