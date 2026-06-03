# Integration Contract — Server-Driven Authentication

**Audience: every team with work to do to ship this feature.** **Purpose:** each section below is one team's contract — what they own, what they deliver, what they expect from others, and the "done" checklist they sign off against. This is the coordination layer on top of the four technical contracts in this folder.

The backend is in a **separate repository** from this mobile app. This file is the hand-off document: it states what the mobile app guarantees, what it expects from the backend, what mobile is requesting that does not exist yet, and where the open questions sit.

---

## TL;DR — who talks to whom

```text
┌────────────────────────────┐                                ┌────────────────────────────┐
│   Mobile team (this repo)  │                                │   Backend team (other repo)│
│   Criarte Flutter app      │                                │   Laravel 10 + Botble      │
└─────────────┬──────────────┘                                └─────────────┬──────────────┘
              │                                                              │
              │  POST auth/check-identifier                                  │
              │  POST auth/set-initial-password                              │
              │  POST auth/self-register                                     │
              │  POST auth/verify-email-otp                                  │
              │  POST auth/login                                             │
              │  POST auth/forgot-password                                   │
              │  POST auth/verify-reset-otp                                  │
              │  POST auth/reset-password                                    │
              ▼                                                              │
       criarte.filhos.app/api/v1/auth/*                                     │
              │                                                              │
              │  (uniform action envelope, see rest-endpoints.md)            │
              ◄──────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
                                  ┌────────────────────────┐
                                  │   Gmail SMTP (project) │
                                  │   port 465, SSL,       │
                                  │   App Password         │
                                  └────────────────────────┘

  Content / L10n team    →    PT-BR (primary), EN inline, AR follow-up
                              ┌─→ in-app strings → assets/langs/*.json
                              └─→ email templates → resources/views/emails/auth/*.blade.php

  Product / Ops          →    Toggles `server_driven_auth_enabled` (Firestore config) on cutover
                              Toggles `EMAIL_OTP_ENABLED` (.env) for dev/QA only
```

---

## 1. Mobile team (this repo)

**Owns**: every screen, widget, state machine, and REST call inside the Flutter app.

### Delivers (this PR / branch `ahmed_nour_`)

| Deliverable | Where | Spec ref |
|---|---|---|
| `AuthActionDispatcher` (single mapper from `action` string → nav/state) | `lib/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart` | FR-SDA-04, 05 |
| `LoginScreen` rewrite — phone field, inline password reveal on `REQUIRE_PASSWORD`, "Forgot password?" inline, "Create new account" link | `lib/features/server_driven_auth/presentation/login_screen.dart` | FR-SDA-02, 12 + US-3 |
| `SelfRegisterScreen` (name, phone, email, password, confirm) | `lib/features/server_driven_auth/presentation/self_register_screen.dart` | US-2 |
| `SetInitialPasswordScreen` (PopScope canPop:false) | `lib/features/server_driven_auth/presentation/set_initial_password_screen.dart` | FR-SDA-06 |
| `EmailOtpScreen` (registration) with 60 s resend | `lib/features/server_driven_auth/presentation/email_otp_screen.dart` | FR-SDA-09, 10 |
| `PendingApprovalScreen` (server-driven variant of `your_account_under_review`) | `lib/features/server_driven_auth/presentation/pending_approval_screen.dart` | US-2, US-4 |
| `ForgotPasswordEmailScreen` | `lib/features/server_driven_auth/presentation/forgot_password_email_screen.dart` | FR-SDA-13 |
| `ResetOtpScreen` (distinct from EmailOtpScreen) | `lib/features/server_driven_auth/presentation/reset_otp_screen.dart` | FR-SDA-09 |
| `SetNewPasswordScreen` (PopScope canPop:false post-OTP) | `lib/features/server_driven_auth/presentation/set_new_password_screen.dart` | FR-SDA-07 |
| Auth data layer — repository + impl + DI, all 8 endpoints via `NetworkClient.handleRequest` → `Either<Failure, T>` | `lib/features/server_driven_auth/data_sources/` | FR-SDA-18, 19 |
| `AuthAction` enum, request/response models | `lib/features/server_driven_auth/models/` | spec §Key Entities |
| `ConfigCubit.serverDrivenAuthEnabled` field with toJson/fromJson | `lib/core/config/cubit/*` | FR-SDA-01 |
| ~35 new localization keys + PT/EN/AR translations | `lib/core/localization/localization_keys.dart` + `assets/langs/{pt,en,ar}.json` | spec §Localization |
| Crashlytics redaction allowlist for the 8 `auth/*` endpoints | `lib/core/network/network_client.dart` | FR-SDA-20 |
| Routing entry point — when `serverDrivenAuthEnabled == true`, `SplashScreen` / onboard tail routes into the new `LoginScreen` instead of the legacy one | `lib/features/splash/presentation/splash_screen.dart` | FR-SDA-01 |
| `TESTING.md` walkthrough (5 scenarios + flag matrix) | repo root | acceptance |

### Expects from Backend team

- **All 8 endpoints** implemented per [rest-endpoints.md](rest-endpoints.md) with the **exact `action` strings** (case-sensitive) and the uniform error envelope `{ error: { code, message } }`.
- **DB migration** per [database-changes.md](database-changes.md) — `users.password` nullable, `status` enum, `email_verified` + `email_verified_at`, indexes, backfill, `password_reset_otps` table (+ `email_verification_otps` recommended).
- **Security rules** per [security.md](security.md) — scoped single-use `temp_token`s, OTP attempt limit, session invalidation on reset, rate limits, enumeration prevention.
- **Gmail SMTP + queued Mailable** per [email-otp.md](email-otp.md) — `OtpMail implements ShouldQueue`, queue worker documented in deploy README.
- **`EMAIL_OTP_ENABLED` flag** in `.env` (default `true`) read via `config('auth.email_otp_enabled')`, with the `auth:check-config` artisan command and the warning log line.
- **Token issuance**: `set-initial-password` and `login` return the existing `{ data: UserModel, access_token }` shape so `UserBloc.loggedIn(user)` parses unchanged.
- **`Authorization` headers**: pre-login endpoints ignore them; final endpoints return the standard JWT.
- The mobile interceptor attaches `school` / `school_id` / `lang` headers automatically — endpoints may ignore `school`/`school_id`; `lang` SHOULD pick the OTP email language.

### Expects from Product / Ops

- Firestore `config/*` doc gets a new field `server_driven_auth_enabled: bool` (default `false`). Flip to `true` per-school or org-wide once the backend ships the 8 endpoints and the mobile build is in store.
- A documented cutover playbook: backend deploys → smoke tests on a pilot school → flip the flag for that school → monitor → expand.

### Expects from Content / L10n

- ~35 PT-BR strings (primary) + EN parallel translations — see spec.md §Localization for the full key list.
- AR can follow later (placeholder keys will display the key name until copy arrives).
- 3 email-body language variants reviewed before launch (PT primary).

### Definition of done (mobile)

- [ ] `flutter analyze` clean on both flavors.
- [ ] Both flavors build (`apk` + `appbundle`).
- [ ] With `server_driven_auth_enabled == false`: login screen and flow are byte-for-behavior identical to today on both flavors (no regression; SC-SDA-01).
- [ ] With `server_driven_auth_enabled == true` against a backend stub: all 5 scenarios complete end-to-end on both flavors.
- [ ] Every `action` string in code matches the spec exactly (case-sensitive — grep verifies).
- [ ] No client-side account-state inference in the server-driven path (SC-SDA-05).
- [ ] No new Firebase / Twilio / AWS-SNS reference for auth (SC-SDA-07).
- [ ] Approval gate verified: an `is_approval = false` test user lands on `PendingApprovalScreen` after Scenario 1's final JWT and after Scenario 3's login.
- [ ] Localization keys present in all three lang files (AR may be placeholder).
- [ ] Crashlytics: 100+ staging events spot-checked, no phone / email / password / OTP / temp_token leaks (FR-SDA-20).

---

## 2. Backend team (other repo) — what mobile is requesting

**Owns**: the Laravel migrations, the 8 REST controllers + Form Request validators, the Mailable + queue worker, the `EMAIL_OTP_ENABLED` config + artisan command, the security rules.

### Delivers

| Deliverable | Detail | Spec ref |
|---|---|---|
| Migration: `users` table changes | nullable `password`, `status` enum, `email_verified`, `email_verified_at`, indexes, backfill rule | [database-changes.md §1](database-changes.md) |
| Migration: `password_reset_otps` + `email_verification_otps` tables | per shape in [database-changes.md §2, §3](database-changes.md) | — |
| `auth_temp_tokens` table OR Redis store | per shape in [database-changes.md §4](database-changes.md) | — |
| `users.token_version` column + JWT middleware update | per [database-changes.md §5](database-changes.md) + [security.md §4](security.md) | — |
| 8 REST endpoints | full request/response shapes per [rest-endpoints.md](rest-endpoints.md), including uniform error envelope | FR-SDA-04, 18, 19 |
| Form Request validators | one per endpoint; password rule = min 8, confirmation match; phone+country_code shape | [security.md §6](security.md) |
| `OtpMail` Mailable (`implements ShouldQueue`) + 3 blade views | per [email-otp.md §2, §4](email-otp.md) | — |
| Queue worker in deploy README | per [email-otp.md §2](email-otp.md) | — |
| `config/auth.php` entry + `EMAIL_OTP_ENABLED` env wiring | per [email-otp.md §3](email-otp.md) | — |
| `auth:check-config` artisan command | warns when `APP_ENV=production AND email_otp_enabled = false` | [email-otp.md §3](email-otp.md) |
| Warning log on every flag-bypassed request | `[WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}` | [email-otp.md §3](email-otp.md) |
| Rate-limit rules | per [security.md §1](security.md) — 5/min on entry, 10/min on verify, hashed bucket keys | — |
| Enumeration prevention | `check-identifier` → 200 NOT_FOUND; `forgot-password` → same response shape regardless of email existence + dummy `temp_token`; constant-time login | [security.md §5, §9](security.md) | — |
| Session invalidation on `reset-password` | `token_version` bump (recommended) | [security.md §4](security.md) | — |
| Log discipline | no plaintext PII / secrets in logs | [security.md §7](security.md) | — |
| `.env.example` block | with the inline warning comment block | [email-otp.md §3](email-otp.md) | — |

### Expects from Mobile team

- Requests in the documented JSON shapes.
- Calls to `verify-email-otp` / `verify-reset-otp` **never** sent when `EMAIL_OTP_ENABLED = false` (defense-in-depth still implemented: the endpoint returns 503 `OTP_BYPASSED` regardless).
- The mobile dispatcher handles **only** the 8 documented `action` strings; any new action requires a coordinated spec update.

### Expects from Product / Ops

- The Gmail account + 16-char App Password (provided out of band, dropped into `.env`).
- A pilot school for the first flag flip.
- The decision on `users` vs `app_users` table (open item — see below).

### Definition of done (backend)

- [ ] Migration runs cleanly on staging; admin Botble login still works post-migration.
- [ ] Backfill verified: all prior `password IS NOT NULL` rows have `status = 'active'` and `email_verified = true`.
- [ ] All 8 endpoints return the documented shapes for the happy path and all error codes.
- [ ] `temp_token`s are scoped, single-use, 10-min TTL, HMAC-hashed at rest; cross-scope use returns `403 TOKEN_SCOPE_MISMATCH`.
- [ ] OTP attempt limit (5) and TTL (10 min) enforced.
- [ ] `reset-password` invalidates all existing sessions (verified by old token returning 401 after a reset on a different device).
- [ ] Rate-limit table verified on a staging load test.
- [ ] `forgot-password` returns identical shape for known and unknown emails (verified with two test inputs).
- [ ] `check-identifier` returns `200 NOT_FOUND` for unknown phones (not 404).
- [ ] `EMAIL_OTP_ENABLED=true` + happy path: OTP email arrives in test Gmail inbox within 30 s of `200` response.
- [ ] `EMAIL_OTP_ENABLED=false` + self-register → `GO_TO_PENDING_APPROVAL` directly; no email sent; warning log emitted.
- [ ] `EMAIL_OTP_ENABLED=false` + forgot-password → `403 PASSWORD_RESET_UNAVAILABLE`; warning log emitted.
- [ ] `auth:check-config` errors when `APP_ENV=production AND email_otp_enabled = false`.
- [ ] Toggle `EMAIL_OTP_ENABLED` without restart — only `php artisan config:cache` needed.
- [ ] Log spot-check (50 lines) on staging: no plaintext phone / email / code / token.

---

## 3. Product / Ops

**Owns**: the rollout flags, the cutover playbook, the SMTP credentials.

### Delivers

| Deliverable | Detail |
|---|---|
| **Gmail account + App Password** | Already created. Hand to backend team for `.env` insertion. **Strip spaces** from the 16-character App Password. 2-Step Verification enabled on the Gmail account. |
| **Firestore `config/*` field** `server_driven_auth_enabled: bool` (default `false`) | Per-school or org-wide. Flip to `true` to roll the new flow out. |
| **`EMAIL_OTP_ENABLED` value per environment** | `true` in production (default). `false` allowed in dev/QA only. |
| **Cutover playbook** | Backend ships → staging smoke tests → pick pilot school → flip `server_driven_auth_enabled` for that school's config → monitor 7 days → expand. |
| **Decision on `users` vs `app_users`** | Confirm with backend team before they write the migration. |

### Expects from Mobile

- A reliable "off" path: when the flag is `false`, login is identical to today. (SC-SDA-01.)

### Expects from Backend

- An honest `auth:check-config` that yells when prod is misconfigured.

### Definition of done

- [ ] `server_driven_auth_enabled` field present on the org-wide config doc.
- [ ] Pilot school identified.
- [ ] Cutover playbook in `specs/server_driven_auth/quickstart.md` reviewed.
- [ ] `EMAIL_OTP_ENABLED=true` confirmed in production `.env`.

---

## 4. Content / Localization

**Owns**: every user-visible string + the email-body templates.

### Delivers

| Deliverable | Where |
|---|---|
| ~35 PT-BR strings (primary) — `sda_*` keys | `assets/langs/pt.json` |
| ~35 EN strings | `assets/langs/en.json` |
| ~35 AR strings (can follow later) | `assets/langs/ar.json` |
| 3 blade email views | `resources/views/emails/auth/otp_{pt,en,ar}.blade.php` (in the backend repo) |
| `lang/{pt,en,ar}/auth_otp.php` files | in the backend repo |
| Brand assets for the email body | logo URL / colors if the design team wants HTML branding |

### Definition of done

- [ ] PT-BR copy reviewed by a Brazilian native speaker.
- [ ] EN copy reviewed.
- [ ] Email subject + body rendered correctly in Gmail / Outlook / Apple Mail (no broken layout).
- [ ] `{{ code }}` placeholder large, monospaced, easy to copy.

---

## 5. QA

**Owns**: cross-team E2E verification of all 5 scenarios + the flag matrix.

### Delivers

| Deliverable | Detail |
|---|---|
| All 5 scenarios end-to-end on staging | Both flavors. Real test Gmail inbox. |
| Flag matrix verified | `EMAIL_OTP_ENABLED` true → false → true; observed behavior matches [email-otp.md §3](email-otp.md). |
| Rollout-flag verified | `server_driven_auth_enabled` false → true; legacy login identical when off, new flow active when on. |
| Approval-gate audit | `is_approval = false` → `PendingApprovalScreen` (not `MainScreen`) on every terminal-JWT path. |
| Crashlytics audit | 100+ staging events; no leaks. |
| Rate-limit audit | Burst 6 requests at `check-identifier` → 6th returns 429 with `Retry-After`. |
| Enumeration audit | `forgot-password` with two emails (one real, one fabricated) → identical response time + shape. |

### Definition of done

- All 5 scenarios + both flag states pass on staging on both flavors, with no findings.

---

## 6. Requested API changes (delta from what exists today)

This is the explicit list of changes the mobile team is asking the backend team to make in the other repo. Items marked **NEW** do not exist today; items marked **CHANGE** modify existing behavior.

| # | Endpoint | NEW / CHANGE | Detail |
|---|---|---|---|
| 1 | `POST auth/check-identifier` | **NEW** | Unified entry; returns `action` envelope (see [rest-endpoints.md §1](rest-endpoints.md)) |
| 2 | `POST auth/set-initial-password` | **NEW** | Consumes `set-password` temp_token; sets password; flips `status = active`; returns login shape |
| 3 | `POST auth/self-register` | **NEW** (replaces today's `auth/register`) | Creates `pending` user; branches on `EMAIL_OTP_ENABLED` |
| 4 | `POST auth/verify-email-otp` | **NEW** | Verifies registration OTP; flips `email_verified = true`; returns `GO_TO_PENDING_APPROVAL` |
| 5 | `POST auth/login` | **CHANGE** | Add `password` field for the phone+password path; preserve existing fields. Returns `INVALID_CREDENTIALS` (not generic `error: true`) per uniform envelope |
| 6 | `POST auth/forgot-password` | **NEW** | Email-based reset; branches on `EMAIL_OTP_ENABLED`; enumeration-safe |
| 7 | `POST auth/verify-reset-otp` | **NEW** | Verifies reset OTP; issues `reset-password`-scoped temp_token |
| 8 | `POST auth/reset-password` | **NEW** | Consumes `reset-password` temp_token; updates hash; invalidates all sessions |
| — | `users` table | **CHANGE** | Nullable password, `status` enum, `email_verified` + `email_verified_at`, indexes, backfill, `token_version` |
| — | OTP tables | **NEW** | `password_reset_otps`, `email_verification_otps` |
| — | Temp-token store | **NEW** | `auth_temp_tokens` table OR Redis with the documented scopes |
| — | `config/auth.php` + `EMAIL_OTP_ENABLED` env | **NEW** | Flag wiring + `.env.example` block + `auth:check-config` artisan command |
| — | `OtpMail` Mailable + queued job + 3 blade views + 3 lang files | **NEW** | Gmail SMTP delivery per [email-otp.md](email-otp.md) |
| — | JWT middleware | **CHANGE** | Honor `users.token_version` claim for session invalidation |
| — | Rate limiter | **CHANGE** | Add the buckets in [security.md §1](security.md) |

### Endpoints that should NOT exist after this lands
- `auth/login-with-email { email, password }` — superseded by the unified flow. **Keep for backward compatibility** during the flag-gated rollout; deprecate once the cutover completes. Mobile stops calling it when `server_driven_auth_enabled == true`.
- `auth/email-otp/send` and `auth/email-otp/verify` (from the `email_otp` feature) — **continue to exist** if the `email_otp_globally_visible` flag is also true; they serve a different purpose (login by email OTP) and are orthogonal to this feature.

---

## 7. Open questions awaiting backend team's answer

| # | Question | Why mobile cares | Suggested default |
|---|---|---|---|
| 1 | Is the auth table `users` or `app_users`? | If separate, the FK in `password_reset_otps` and the migration target both need adjustment. | Confirm before backend writes the migration. |
| 2 | Temp-token storage — DB table or Redis? | Mobile is indifferent; ops impact is yours. | Redis if already provisioned; DB table otherwise. |
| 3 | Session invalidation — `token_version` bump or `revoked_tokens` table? | Mobile is indifferent; the 401-on-stale-token path is unchanged either way. | `token_version` for v1. |
| 4 | Email-verification OTP table — mirror as `email_verification_otps`, or polymorphic `otp_codes(kind)` table? | Mobile is indifferent. | Mirror as separate table for v1. |
| 5 | Does the social login (Google / FB / Apple) remain visible when `server_driven_auth_enabled == true`? | Affects whether mobile keeps the social buttons on the new `LoginScreen`. | Hidden in v1; revisit. |
| 6 | After `verify-email-otp` success, should the user be auto-active or always go to `pending`? | Affects whether the response is the login shape or `GO_TO_PENDING_APPROVAL`. | Always pending in v1 (matches master prompt). |

---

## 8. Critical path

```text
Day 0:                              Day 1-5:                              Day 6-10:
─────                               ─────                                 ─────
Product: provide Gmail App Password ─► Backend: .env + Mailable + Hello World email send
Backend: confirm users vs app_users ─► Backend: migration + backfill on staging
Mobile: spec-kit ready (this PR)    ─► Backend: 8 endpoints + tests
                                     ─► Content: PT-BR + EN strings + email templates
                                     ─► Mobile: data layer + dispatcher + 9 screens (flag off)
                                                                            │
                                                                            ▼
                                                                    QA: 5 scenarios + flag matrix on staging
                                                                            │
                                                                            ▼
                                                                    Product: flip server_driven_auth_enabled for pilot school
                                                                            │
                                                                            ▼
                                                                    7-day soak → expand → full cutover
```

Two prereqs anyone can start **right now** without waiting for anyone else:
1. **Backend team**: confirm `users` vs `app_users` table choice (Question 1 above).
2. **Mobile team**: build the data layer + dispatcher + 9 screens against a stub (already in flight in this PR; runs dark behind `server_driven_auth_enabled = false`).

---

## 9. Sign-off (one row per team, marked green when "Definition of done" above is complete)

| Team | Sign-off owner | Status |
|---|---|---|
| Mobile | (assign) | ⬜ |
| Backend | (assign) | ⬜ |
| Product / Ops | (assign) | ⬜ |
| Content / L10n | (assign) | ⬜ |
| QA | (assign) | ⬜ |

When all 5 rows are green → cutover: flip `server_driven_auth_enabled = true` for the pilot school and monitor.
