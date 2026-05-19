# Integration Contract — Email OTP

**Audience**: every team that has work to do to ship this feature. **Purpose**: each section below is one team's contract — what they own, what they deliver, what they expect from others, and the "done" checklist they sign off against.

This file is the **coordination layer** on top of two technical contracts:
- [rest-endpoints.md](rest-endpoints.md) — the mobile ↔ backend wire format
- [firestore-mail-schema.md](firestore-mail-schema.md) — the backend ↔ Firebase Extension wire format

If your team's deliverables are below, this is your check-list.

---

## TL;DR — who talks to whom

```text
┌─────────────────┐                                            ┌──────────────────────┐
│   Mobile team   │                                            │  Content / L10n team │
│  (Criarte app)  │                                            │   (PT primary,       │
└────────┬────────┘                                            │    EN inline,        │
         │                                                     │    AR follow-up)     │
         │ POST /auth/email-otp/send                           └─────────┬────────────┘
         │ POST /auth/email-otp/verify                                   │
         ▼                                                               │
┌──────────────────────────┐         writes mail/{autoId}      ┌─────────▼────────────┐
│    Backend team          │ ────────────────────────────────► │  Firebase admin team │
│ (criarte.filhos.app)     │         reads email_templates/    │ (Firestore +         │
│                          │ ◄──────────────────────────────── │  Trigger Email ext) │
│ — new REST endpoints     │         reads config/{schoolId}   └─────────┬────────────┘
│ — new DB table           │                                             │
│ — Firestore Admin SDK    │                                             │ SMTP via
│ — Token mint reuse       │                                             ▼
└──────────────────────────┘                                   ┌──────────────────────┐
                                                                │   DevOps / DNS team  │
                                                                │   (DKIM, SPF,        │
                                                                │    SendGrid account) │
                                                                └──────────────────────┘
```

---

## 1. Mobile team

**Owns**: every screen, widget, state machine, and REST call inside the Flutter app.

### Delivers

| Deliverable | Where | Spec ref |
|---|---|---|
| Login screen tab picker (Telefone / E-mail) | `lib/features/login/presentation/login_screen.dart` | FR-EM-01..03 |
| Email-tab widget (field, format validation, Send CTA) | `lib/features/login/presentation/widgets/email_tab.dart` | FR-EM-04..06 |
| 4 new model classes (`EmailOTPSendRequest/Response`, `EmailOTPVerifyRequest/Response`) | `lib/features/login/models/` | data-model.md |
| `LoginRepository` extension (2 new methods) | `lib/features/login/data_sources/login_repository.dart` + `login_impl.dart` | data-model.md §LoginRepository |
| `OTPBloc` extension (mode-aware methods + cooldown reuse) | `lib/features/otp/presentation/bloc/otp_bloc.dart` | FR-EM-07..15 |
| `OTPScreen` mode-aware chrome (envelope icon, email-mode subline, masked email) | `lib/features/otp/presentation/otp_screen.dart` + new `widgets/delivery_mode_chrome.dart` | FR-EM-08, 09 + US-3 |
| `ConfigCubit` field `emailOtpGloballyVisible` (with toJson/fromJson) | `lib/core/config/cubit/*` | FR-EM-01 |
| 3 new `LocalKeys`: `last_email_otp_request`, `last_email_otp_email`, `last_login_mode` | `lib/core/local_db/local_db_repo.dart` | FR-EM-14, R3 |
| 15 new `email_otp_*` localization keys + PT/EN translations | `lib/core/localization/localization_keys.dart` + `assets/langs/{pt,en}.json` | spec.md §Localization |
| Crashlytics redaction allowlist update | `lib/core/network/network_client.dart` | FR-EM-18 |

### Expects from Backend team

- **`POST /auth/email-otp/send`** returning `200 { success, masked_email, retry_after }` on the happy path and the 9 documented error codes ([rest-endpoints.md](rest-endpoints.md))
- **`POST /auth/email-otp/verify`** returning the **exact same shape** as the existing `POST /auth/login` (`{data: UserModel, access_token: string}`) — so the existing `UserBloc.loggedIn(user)` path drops in unchanged
- `masked_email` formatted as `<first-char>***@<domain>` (mobile renders verbatim — no client-side masking)
- Backend honors `lang` from request body for the email template (so a user with `pt` gets PT email even if the app's locale at login is EN)
- Errors return a `code` field on the body whose value matches the 9 documented strings (e.g., `email_otp_not_enabled_for_school`)
- HTTP `Retry-After` header on 429 responses so the local cooldown timer can sync

### Expects from Firebase admin team

Nothing directly. Mobile never reads `mail/*` or `email_templates/*` — those are server-side.

Mobile DOES read **one** field from the existing org-wide `config/*` document via `ConfigCubit`:
- `email_otp_globally_visible: bool` — default `false`, set to `true` to expose the email tab to users

### Expects from Content team

- 15 PT-BR strings (primary) — see spec.md §Localization Requirements table
- 15 EN strings — same table
- (AR can follow later — placeholder keys will render the key name until copy arrives)

### Definition of done

- [ ] `flutter analyze` clean on both flavors
- [ ] Both flavors build (`apk` + `appbundle`)
- [ ] When `email_otp_globally_visible = false`: login screen identical to today (no regression, no extra tab visible)
- [ ] When `email_otp_globally_visible = true`: TabBar with 2 tabs renders, Telefone default-selected
- [ ] Tab choice persists across hot-restart (`last_login_mode` Hive read on init)
- [ ] All 9 error codes surface the correct localized message on `ErrorField`
- [ ] No email address or 6-digit code appears in staging Crashlytics breadcrumbs (100+ test events)
- [ ] Approval gate verified: test user with `is_approval = false` lands on `YourAccountUnderReviewScreen` after email-OTP success
- [ ] Existing SMS path verified unchanged (no regression)

---

## 2. Backend team

**Owns**: the REST endpoints, the `email_otps` database table, the server-side template rendering, the Firestore writes, the access-token mint.

### Delivers

| Deliverable | Detail | Spec ref |
|---|---|---|
| `POST /auth/email-otp/send` | Full request/response per [rest-endpoints.md §POST auth/email-otp/send](rest-endpoints.md) | FR-EM-05, 15, 16 |
| `POST /auth/email-otp/verify` | Full request/response per [rest-endpoints.md §POST auth/email-otp/verify](rest-endpoints.md) | FR-EM-10, 11 |
| `email_otps` DB table | Columns: `email_hash`, `otp_hash`, `school_id`, `expires_at`, `attempts`, `created_at`. **One active row per email_hash.** | rest-endpoints.md §Backend behavior |
| HMAC-SHA256 hashing | New server-side secret `EMAIL_OTP_HMAC_SECRET`. Both email and code hashed before storage. **Never** store plaintext. | LGPD |
| 6-digit code generation | Cryptographically random (`/dev/urandom` or language equivalent — never `Math.random`) | Security |
| Firestore Admin SDK integration | Read `config/{schoolId}.email_otp_enabled` + `email_templates/email_otp_{lang}`; write `mail/{autoId}` | rest-endpoints.md §Backend behavior |
| Template variable substitution | Simple `{{code}}` (and optional `{{user_first_name}}`) substitution — no Mustache/Handlebars needed | firestore-mail-schema.md §EmailTemplate |
| Token mint reuse | The `access_token` returned from `/verify` MUST be minted by the same path used by `/auth/login` so the mobile user-bloc treats it identically | FR-EM-11 |
| Account-deletion hook | The existing "Delete my account" path triggers immediate purge of `email_otps` rows + 90-day audit log for that user | FR-EM-19 |
| Log discipline | Server logs MUST contain only `email_hash`, `school_id`, status, request id. **Never** the plain-text email or code. | LGPD, SC-EM-04 |

### Expects from Mobile team

- Requests in the documented shape (`{email, lang}` for send; `{email, code}` for verify)
- `lang` field always present and one of `pt | en | ar`
- Network requests via the same `NetworkClient` — so school/school_id/lang headers are attached (harmless but expected)

### Expects from Firebase admin team

- **Firestore collections exist and are writable via Admin SDK**:
  - `mail` (work queue — extension watches this)
  - `email_templates` (template docs)
  - `config/{schoolId}` already exists; just adds the new boolean field `email_otp_enabled` per school
- **Trigger Email extension installed and active** — backend's Firestore write to `mail/` triggers a real SMTP send (verified by `delivery.state` reaching `SUCCESS`)
- Firebase service-account credentials with Firestore Admin SDK scope (probably already in place for the existing chat / config integration — confirm)

### Expects from DevOps / DNS team

- Sender domain (e.g., `noreply@criarte.filhos.app`) has **DKIM + SPF** records configured before launch
- SendGrid SMTP credentials provisioned and shared with Firebase admin team

### Expects from Content team

- 3 Firestore template docs (`email_templates/email_otp_{pt,en,ar}`) populated with `subject_template`, `html_template`, `text_template` — see [firestore-mail-schema.md §EmailTemplate](firestore-mail-schema.md)

### Definition of done

- [ ] Both endpoints return correct shapes on happy path
- [ ] All 9 error codes implemented and return the documented `code` field
- [ ] 60-second cooldown enforced server-side; `Retry-After` header set on 429
- [ ] 5-minute expiry enforced; expired records return `410 code_expired`
- [ ] 5-attempt limit enforced; over-limit returns `429 too_many_attempts` and invalidates the record
- [ ] Per-school `email_otp_enabled = false` returns `422 email_otp_not_enabled_for_school` (verified by toggling the flag)
- [ ] Firestore `mail/{autoId}` document is written successfully; extension picks it up and `delivery.state` reaches `SUCCESS` within 30 s
- [ ] Staging logs spot-checked: no plaintext email or code in any log line
- [ ] Account-deletion test: trigger deletion → confirm `email_otps` rows and audit log are purged within 10 s

---

## 3. Firebase admin team (Firestore + Extensions + Auth)

**Owns**: the Firebase project (`escola-cede2`) configuration. Sets up the email-sending infrastructure that the backend writes to.

### Delivers

| Deliverable | Where | Detail |
|---|---|---|
| **Blaze plan upgrade** | Firebase Console → Usage & Billing | Required for Cloud Functions (the extension is a function under the hood). Free quota (2M invocations/month) covers OTP volume. |
| **Trigger Email from Firestore extension** | Firebase Console → Extensions → Browse hub → install `firebase/firestore-send-email` | Official extension. Watches `mail/` collection. See [firestore-mail-schema.md §Extension installation cheat-sheet](firestore-mail-schema.md) |
| **Extension configuration** | During install prompts | `SMTP connection URI = smtps://apikey:<SENDGRID_API_KEY>@smtp.sendgrid.net:465`; default FROM = `noreply@criarte.filhos.app`; watch collection = `mail`; leave Users + Templates collections blank |
| **Firestore collection: `mail`** | Firestore Database → Data | Created on first write by the backend. No initial schema/index needed. |
| **Firestore collection: `email_templates`** | Firestore Database → Data | Initial creation; Content team populates the 3 docs |
| **Firestore security rules** | Firestore Database → Rules | Add rules denying client write to `mail/*` and `email_templates/*` (Admin SDK bypasses rules). See [firestore-mail-schema.md §Security rules](firestore-mail-schema.md) |
| **New field on existing `config/{schoolId}` doc** | Firestore Database → Data | `email_otp_enabled: bool` (default `false`). Per-school admin toggles to `true` for pilot. |
| **New field on existing org-wide `config/*` doc** | Firestore Database → Data | `email_otp_globally_visible: bool` (default `false`). Flip to `true` once mobile builds with the feature roll out. |
| **(Optional but recommended) Cleanup Cloud Function** | Firebase Console → Functions | Scheduled (daily at 02:00) deletion of `mail/*` docs where `delivery.state == "SUCCESS"` AND `endTime < 30 days ago`. LGPD minimization. ~20 lines of Node. |

### Expects from Backend team

- Backend writes to `mail/{autoId}` only via Firestore Admin SDK (security rules deny client writes — Admin SDK bypasses)
- Backend reads `config/{schoolId}.email_otp_enabled` and `email_templates/email_otp_{lang}` via Admin SDK

### Expects from DevOps / DNS team

- SendGrid API key with "Mail Send" scope (single key for the project)
- DKIM + SPF DNS records for the sender domain validated by SendGrid's Sender Authentication wizard

### Definition of done

- [ ] Firebase project is on Blaze plan
- [ ] Trigger Email extension status shows green "Active" badge
- [ ] Test send: manually write a sample doc to `mail/test` with a real recipient → confirm `delivery.state` reaches `SUCCESS` within 30 s
- [ ] Security rules deployed and verified (a client-side write to `mail/*` is rejected)
- [ ] `config/{schoolId}.email_otp_enabled` field present on at least the pilot school doc
- [ ] `config/*.email_otp_globally_visible` field present on the org-wide config doc
- [ ] (If implemented) Cleanup function deploys successfully and shows in scheduled-functions list

---

## 4. DevOps / DNS team

**Owns**: the SendGrid account, the sender-domain DNS, the email-delivery health.

### Delivers

| Deliverable | Detail |
|---|---|
| **SendGrid account** | Sign up at sendgrid.com → free tier (100 emails/day) is sufficient for pilot. Create an API key with **only** "Mail Send" scope. Share securely with Firebase admin team (e.g., 1Password / Vault). |
| **Sender domain setup** | Decide sender address (e.g., `noreply@criarte.filhos.app`). Verify via SendGrid Sender Authentication wizard. |
| **DKIM records (3 CNAME)** | Generated by SendGrid wizard. Add to DNS provider. **Verify before launch** — propagation up to 24h. |
| **SPF record (1 TXT)** | `v=spf1 include:sendgrid.net ~all` (or merge with existing SPF if one exists — only one SPF record per domain). |
| **(Optional) DMARC record** | `v=DMARC1; p=none; rua=mailto:dmarc@criarte.filhos.app` — improves deliverability further; can ship in v1.x. |
| **Monitoring** | Set up a SendGrid alert when daily volume exceeds 80 emails (so you know before you hit the 100/day cap) or when bounce rate exceeds 5%. |
| **Upgrade-path plan** | Document the path to Brevo or Mailgun if SendGrid free tier becomes insufficient. The extension is SMTP-agnostic; only the connection URI changes. |

### Expects from Firebase admin team

- Confirmation that the extension was configured with the SendGrid API key (so you know when to revoke the key if rotated)

### Definition of done

- [ ] SendGrid account active, API key generated and shared with Firebase admin team
- [ ] DKIM + SPF records visible in DNS lookups (`dig TXT noreply.criarte.filhos.app`)
- [ ] SendGrid sender authentication shows green "Valid" badge for the domain
- [ ] Test email from SendGrid dashboard lands in a real inbox (not spam) within 30 s
- [ ] Volume + bounce-rate alerts configured

---

## 5. Content / Localization team

**Owns**: every user-visible string + the email-body templates.

### Delivers

| Deliverable | Where | Detail |
|---|---|---|
| **15 in-app strings (PT-BR primary)** | `assets/langs/pt.json` (via PR or Firestore translation overlay) | See spec.md §Localization Requirements table for the 15 `email_otp_*` keys |
| **15 in-app strings (EN)** | `assets/langs/en.json` | Same keys, EN translations |
| **15 in-app strings (AR)** | `assets/langs/ar.json` | Can follow later; placeholder keys will display key name until copy arrives |
| **Email subject template (PT)** | Firestore doc `email_templates/email_otp_pt.subject_template` | e.g., `"Seu código Criarte: {{code}}"` |
| **Email HTML body (PT)** | `email_templates/email_otp_pt.html_template` | Full HTML — see example in [firestore-mail-schema.md §EmailTemplate](firestore-mail-schema.md). Must include `{{code}}` placeholder. |
| **Email plaintext body (PT)** | `email_templates/email_otp_pt.text_template` | Plain-text fallback |
| **Same 3 fields for EN** | `email_templates/email_otp_en` | English versions |
| **Same 3 fields for AR** | `email_templates/email_otp_ar` | Can follow later; backend falls back to PT if `ar` doc is missing |
| **Brand assets** | Logo URL / colors for the email HTML | Coordinate with design team if the email body needs Criarte branding |

### Expects from others

- Backend team will read these Firestore docs at startup + on document update
- Design team review for the HTML email (looks good on Gmail, Outlook, Apple Mail — test in [Litmus](https://litmus.com) or [Email on Acid](https://www.emailonacid.com) if available)

### Definition of done

- [ ] All 15 in-app strings reviewed by a Brazilian Portuguese native speaker
- [ ] All 15 EN strings reviewed by a native English speaker
- [ ] 3 Firestore template docs populated and saved
- [ ] Test email from a real `POST /send` call rendered correctly in Gmail, Outlook, and Apple Mail (no broken layout)
- [ ] `{{code}}` placeholder visible and prominent in the rendered body (large font, easy to copy)

---

## 6. QA / Test team *(can be the same humans as Mobile / Backend)*

**Owns**: end-to-end verification across all the above teams.

### Delivers

| Deliverable | Detail |
|---|---|
| **Staging E2E happy path** | Real test email → full flow → `MainScreen` on both flavors |
| **All 9 error paths verified** | Set up each error condition manually and confirm the right localized message surfaces (see [quickstart.md §Smoke tests Wave 6](../quickstart.md)) |
| **LGPD audit** | Inspect 100+ staging Crashlytics events — confirm zero email or code leaks |
| **Approval-gate verification** | Test user `is_approval = false` → email OTP success → routes to `YourAccountUnderReviewScreen` (not `MainScreen`) |
| **Both-flavor build** | `flutter build apk` for parents + professores, both clean |
| **Deliverability spot-check** | Send 10 test emails to different providers (Gmail, Outlook, Hotmail, Yahoo, ProtonMail) — confirm inbox placement, not spam |
| **Cooldown / expiry** | Verify 60s cooldown is enforced both client + server, and 5-min code expiry returns `410` |

### Definition of done

- All checklists above are green AND a 1-week staging soak with at least 20 real test users completed without finding new bugs.

---

## Critical path — when does what unblock what

```text
Day 0:                                        Day 1-3:                     Day 4-8:
─────────────                                  ─────────                    ──────────
Firebase: upgrade to Blaze     ─────────────► Firebase: install extension ─►
DevOps: sign up SendGrid       ─┐                                          │
DevOps: add DKIM/SPF DNS       ─┴─► wait for DNS propagation              │
Content: write PT/EN strings   ─────────────► Backend: build endpoints   ─┤
                                              Content: populate templates ┤
                                                                          ▼
                                                                    Mobile: waves 1-6 ─► QA wave 7 ─► PILOT
                                                                    (~6 dev-days)        (1 week)
```

The **two prereqs anyone can start RIGHT NOW** without waiting for anyone else:
1. **Firebase admin team** — upgrade to Blaze (5-min approval task)
2. **DevOps team** — SendGrid signup + DKIM/SPF DNS records (DNS propagation up to 24h — start early)

Once those two land, every other team can begin in parallel.

---

## Sign-off checklist (one row per team, marked green when "Definition of done" above is complete)

| Team | Sign-off owner | Status |
|---|---|---|
| Mobile | (assign) | ⬜ |
| Backend | (assign) | ⬜ |
| Firebase admin | (assign) | ⬜ |
| DevOps / DNS | (assign) | ⬜ |
| Content / L10n | (assign) | ⬜ |
| QA | (assign) | ⬜ |

When all 6 rows are green → pilot rollout: flip `email_otp_globally_visible = true` and `config/{pilotSchoolId}.email_otp_enabled = true`. Monitor SendGrid + `mail/*.delivery.state` for the first 7 days.
