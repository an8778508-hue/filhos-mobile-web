# Research: Email OTP — login by email-delivered code

Phase 0 research decisions. All three product-level NEEDS CLARIFICATION items were resolved during spec creation on 2026-05-19 (see spec.md §Resolved Decisions: provider = Firebase Extensions + SendGrid; trigger = per-school admin toggle; backend = REST at `criarte.filhos.app`). This file captures the implementation-level unknowns.

---

## R1: OTPBloc extension vs. new EmailOTPBloc

**Decision**: Extend the existing `OTPBloc` (centrally registered in `di.dart:87`) with mode-aware methods. Add `OTPDeliveryMode mode` as a field on the state and parallel `requestEmailOTP` / `confirmEmailOTP` methods on the bloc. Reuse the existing `_init`, `_startTimer`, and cooldown infrastructure unchanged.

**Rationale**: 90% of the logic is shared — cooldown timer, loading/ready/failure states, the call to `UserBloc.loggedIn(user)` on success. A separate `EmailOTPBloc` would duplicate the timer machinery, the state enum, and the post-success routing. The existing OTPBloc constructor `OTPBloc(this.loginRepository, this.localDatabase)` already has the right dependencies — no DI change needed.

**Alternatives rejected**:
- New `EmailOTPBloc` — duplicate timer code, two cubits to maintain, double the test surface.
- Generic base class with SMS/email subclasses — Dart blocs don't lend themselves to inheritance hierarchies cleanly; composition via a mode flag is idiomatic.

**Action**: Bloc keeps its current single-Cubit shape; methods are added, not events (the existing `OTPBloc` is a `Cubit<OTPState>` with an empty `on<OTPEvent>` block — see `otp_bloc.dart:27-35`, the event-based wiring is commented out).

---

## R2: OTPScreen mode parameter

**Decision**: Add `OTPDeliveryMode mode = OTPDeliveryMode.sms` to `OTPScreen`'s constructor. Default value preserves SMS callers without code change. The screen reads `mode` to swap:
- Top icon: envelope (email) vs. phone (sms) — extract into a small `DeliveryModeChrome` widget
- Headline: `email_otp_verify_title` vs. existing `otp_verify_title`
- Subline: localized email-mode line with masked email substituted, vs. existing SMS phone line
- Spam-folder hint: rendered only in email mode

**Rationale**: The screen is structurally identical (same 6-cell pin field, same Resend CTA, same error display, same approval-gate routing). Branching only at the chrome layer keeps the diff small and means the SMS flow never regresses.

**Alternatives rejected**:
- A separate `EmailOTPScreen` widget — layout duplication; the user's "highlight email mode" requirement is purely cosmetic.
- A boolean flag instead of an enum — enum is easier to grep for and accommodates future delivery modes (push, WhatsApp) without an API break.

---

## R3: Cooldown Hive key strategy

**Decision**: Distinct keys per delivery mode:
- Existing: `last_otp_request` (millis), `last_otp_phone` (string)
- New: `last_email_otp_request` (millis), `last_email_otp_email` (string)
- Plus: `last_login_mode` (`"sms" | "email"`) to remember the user's last tab choice

**Rationale**: A user might try SMS, hit the 60 s cooldown, switch to the email tab, and request a new code. Sharing a cooldown key would falsely block the email send. Independent cooldowns match the real semantics: two different delivery channels, two independent rate limits server-side.

**Alternatives rejected**:
- Unified `last_otp_request_{mode}` keys — equivalent but less grep-friendly; chose explicit names.
- Wipe SMS cooldown when switching to email — surprising side-effect; user might switch back and expect SMS cooldown still applies.

---

## R4: Email masking — server-rendered, not mobile-derived

**Decision**: The `/send` endpoint returns `masked_email` (e.g., `"p***@example.com"`) in its 200 response. Mobile displays this string verbatim on the verification screen. Mobile never derives the mask from the raw email it sent.

**Rationale**:
- Single source of truth for display strings (matches how backend already returns formatted user names, etc.).
- Avoids local PII handling on the mobile side.
- Backend can change the mask format (e.g., `p\*\*\*` → `pa\*\*@…`) without a mobile release.

**Alternatives rejected**:
- Derive mask client-side from the input email — duplicate logic; risks divergence between mobile and server-rendered audit logs.

---

## R5: Email validation — inline regex, no new dependency

**Decision**: Use a permissive regex inline:
```dart
final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
bool get isValidEmail => _emailRegex.hasMatch(email);
```

**Rationale**:
- The check is purely UX gating — the **server is the source of truth** for whether the address is real (it does the user lookup).
- Adding `email_validator` or similar packages is over-engineering for one regex.
- The permissive regex matches everything real users will type; pathological cases (TLDs > 63 chars, IDN domains) are caught server-side.

---

## R6: Pre-login Firestore reads — none

**Decision**: Mobile does NOT read `config/{schoolId}.email_otp_enabled` (impossible — schoolId is unknown before login) nor any per-school Firestore document during the login flow. The backend enforces the per-school flag and returns `422 email_otp_not_enabled_for_school` if the user's school doesn't have email OTP enabled.

**Mobile DOES read** the org-wide `ConfigCubit` field `emailOtpGloballyVisible` — this gates whether the "E-mail" tab is even rendered. It's a single boolean in the existing global `config/*` document, sourced via the existing `ConfigCubit` hydration path.

**Rationale**: Matches FR-EM-20 and the existing pattern (mobile reads `ConfigCubit` only; per-school details are server-side).

---

## R7: Firebase Extension billing tier

**Decision**: Confirm before backend work starts that the Criarte Firebase project (`escola-cede2`) is on the **Blaze** (pay-as-you-go) plan. The "Trigger Email from Firestore" extension itself is free, but it runs as a Cloud Function under the hood, and Cloud Functions require Blaze even for invocations within the free quota.

**Free quota**: 2M function invocations/month — comfortably covers OTP volume.

**Action**: Backend prerequisite task T-prep-1 (in tasks.md) — verify Blaze, upgrade if needed.

---

## R8: SendGrid SMTP setup

**Decision**: Configure the extension to use SendGrid's SMTP relay (`smtp.sendgrid.net:587`, username `apikey`, password = SendGrid API key with "Mail Send" scope). Free tier: 100 emails/day forever. Sender domain: `noreply@criarte.filhos.app` (or operations team's pick). DKIM and SPF records configured before pilot.

**Rationale**: SendGrid free tier matches expected pilot volume comfortably. The extension is SMTP-agnostic so swapping to Brevo / Mailgun later means changing only the SMTP creds in the extension config — no code change.

**Action**: Backend prerequisite task T-prep-2.

---

## R9: Email template storage

**Decision**: Templates live in Firestore at `email_templates/email_otp_{pt|en|ar}`. Each doc has fields:
- `subject_template: string` (e.g., `"Seu código Criarte: {{code}}"`)
- `html_template: string` (full HTML body)
- `text_template: string` (plain-text fallback)
- `updated_at: timestamp`

Backend reads the doc matching the request's `lang`, substitutes `{{code}}`, and writes the rendered body into `mail/{autoId}.message`.

**Rationale**: Remote-editable matches the existing translation discipline (translations are also Firestore-overridable via `ConfigCubit`). Admin web can fix typos or update copy without a release. Templates are versioned via `updated_at` if a rollback is needed.

**Alternatives rejected**:
- Hardcoded templates in the backend — requires deploys for copy fixes.
- Template strings in the Firestore `config/*` doc — pollutes the config doc and mixes concerns.

---

## R10: Existing SMS OTP cooldown timer bug — not in scope

**Observation**: The existing `OTPBloc.requestOTP` at [otp_bloc.dart:97-104](../../lib/features/otp/presentation/bloc/otp_bloc.dart#L97-L104) has a commented-out `// if(l.code == 'already_sent')` branch — a latent bug where the cooldown's "already sent" recovery is half-wired. The SMS cooldown semantics are slightly fragile as a result.

**Decision**: Do NOT fix in this feature. The new email-OTP methods will have correct cooldown logic (mirroring what the SMS path *should* do). The existing SMS flow is left unchanged so the email feature ships in isolation.

**Rationale**: Scope discipline. Fixing the SMS bug in this PR would conflate two changes and complicate review. Track the SMS bug separately in [specs/otp/tasks.md](../otp/tasks.md) if not already.

---

## R11: Tab persistence across hot restarts

**Decision**: Persist the user's tab choice via `LocalDatabaseRepo` under key `last_login_mode` (`"sms" | "email"`). On `LoginScreen.initState`, read the key and default-select the matching tab. Default if absent: `"sms"`.

**Rationale**: Matches FR-EM-02. Small UX win — a user who already uses email OTP doesn't have to switch the tab on every cold start.

---

## Open items carried into implementation

| Item | Tracked in |
|------|-----------|
| Email uniqueness collision (same email across multiple schools) | spec.md §Open items |
| First-time-onboarding email-OTP (vs. login-only) | spec.md §Open items |
| Mid-session tab switch ("try email instead") on OTP screen | spec.md §Open items |
| DKIM/SPF DNS setup for sender domain | tasks.md T-prep-3 (backend coord) |
| SMS OTP latent cooldown bug (`already_sent` branch) | specs/otp/tasks.md (separate PR) |
