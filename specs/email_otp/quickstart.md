# Quickstart: Email OTP — login by email-delivered code

How to pick up the email-OTP implementation. Read order: [spec.md](spec.md) (the *what*) → [plan.md](plan.md) (the *how/sequence*) → [research.md](research.md) (resolved unknowns) → [data-model.md](data-model.md) + [contracts/](contracts/) (the shapes) → [tasks.md](tasks.md) (the checklist).

---

## Before any mobile code — three backend prereqs

These three must land first. Mobile work can be drafted in parallel but cannot be fully tested without them.

| # | What | Owner |
|---|---|---|
| T-prep-1 | Verify Firebase project `escola-cede2` is on **Blaze plan** (Cloud Functions requirement). Upgrade if still on Spark. | Backend / ops |
| T-prep-2 | Install **"Trigger Email from Firestore"** extension; configure SendGrid SMTP creds; install cheat-sheet in [contracts/firestore-mail-schema.md](contracts/firestore-mail-schema.md). | Backend / ops |
| T-prep-3 | Configure **DKIM + SPF** records for the sender domain (e.g., `noreply@criarte.filhos.app`). DNS propagation can take up to 24h — schedule early. | DevOps / DNS |
| T-prep-4 | Create the three Firestore template docs (`email_templates/email_otp_pt`, `_en`, `_ar`). PT-BR copy is in spec.md §Localization Requirements; HTML body example in [contracts/firestore-mail-schema.md](contracts/firestore-mail-schema.md). | Backend + content |
| T-prep-5 | Implement REST endpoints **`POST /auth/email-otp/send`** and **`POST /auth/email-otp/verify`** per [contracts/rest-endpoints.md](contracts/rest-endpoints.md). | Backend |
| T-prep-6 | Add **`config/{schoolId}.email_otp_enabled`** flag to the per-school config doc (default `false`). Flip to `true` for the pilot school only. | Backend / admin |
| T-prep-7 | Add **`email_otp_globally_visible: true`** to the org-wide `config/*` document. Without this the mobile-side feature stays hidden. | Backend / admin |

---

## Then ship in this order on mobile

| Wave | Work | Key files | Gate before next wave |
|---|---|---|---|
| 1 | **Foundation** — 15 localization keys + PT/EN translations; 3 new `LocalKeys` constants; `OTPDeliveryMode` enum; `ConfigCubit` field `emailOtpGloballyVisible` (with toJson/fromJson round-trip); `_redactBody` allowlist extension | `localization_keys.dart`, `local_db_repo.dart`, `otp_delivery_mode.dart`, `config/cubit/*.dart`, `network_client.dart` | `flutter analyze` green both flavors; cold-start round-trip of `emailOtpGloballyVisible` verified |
| 2 | **Repository methods** — `requestEmailOTP` + `confirmEmailOTP` on `LoginRepository` and `LoginImpl`; 4 new model classes (`EmailOTPSendRequest/Response`, `EmailOTPVerifyRequest/Response`) | `login_repository.dart`, `login_impl.dart`, `lib/features/login/models/email_otp_*.dart` | Methods callable in DI; smoke test against backend staging returns 200 |
| 3 | **OTPBloc extension** — add `currentMode`, `currentMaskedEmail` fields; `requestEmailOTP`, `confirmEmailOTP`, `resendEmailOTP`, `_initEmailCooldown` methods; reuse `_startTimer` | `otp_bloc.dart` | SMS path still works unchanged; email methods exposed |
| 4 | **OTPScreen mode-aware chrome** — accept `mode` ctor param; new `DeliveryModeChrome` widget; render envelope icon + email-mode subline when `mode == email`; spam-folder hint after 30s | `otp_screen.dart`, `widgets/delivery_mode_chrome.dart` | Manual render: pass `mode: email` from a test harness → confirm envelope + masked-email subline visible; SMS path visually unchanged |
| 5 | **Login screen tab picker** — TabBar with "Telefone" / "E-mail" tabs, visible only when `ConfigCubit.state.emailOtpGloballyVisible == true`; `email_tab.dart` widget (field, format validation, Send CTA); persist `last_login_mode` on submit | `login_screen.dart`, `widgets/email_tab.dart` | When global flag is OFF: screen renders exactly as today (no regression). When ON: two tabs visible, Telefone default-selected |
| 6 | **End-to-end** — wire the email tab's Send → `OTPBloc.requestEmailOTP` → navigate to `OTPScreen(mode: email)` → verify flow; error mapping for all 9 backend codes | All files above + `login_screen.dart` listener | Full happy path works on staging; all 9 error paths surface the right localized message |
| 7 | **QA + hardening** — verify Crashlytics redaction (no email or code in breadcrumbs in staging); approval-gate test (set `isApproval=false` on test user → email-OTP success routes to `your_account_under_review`); both-flavor release build | — | Both flavors build; analyze clean; redaction confirmed; approval gate confirmed |

---

## Smoke tests per wave (no `test/` dir — manual, both flavors)

- **Wave 1**: Toggle `emailOtpGloballyVisible` in the test Firestore config doc. Force-kill app, reopen → `ConfigCubit.state.emailOtpGloballyVisible` reflects the change. Set Hive `last_login_mode = "email"`, reopen → field is readable via `LocalDatabaseRepo`.
- **Wave 2**: From a DI-aware test harness or a temporary debug button, call `loginRepository.requestEmailOTP(email: 'test@criarte.filhos.app')` → 200 + masked email in response.
- **Wave 3**: Trigger `requestEmailOTP` from a test button → `OTPBloc.state` reaches `OTPReady`; `currentMode == email`; `currentMaskedEmail` populated; SMS `requestOTP` from a different test button still works.
- **Wave 4**: Open `OTPScreen(mode: email)` via a test route. Envelope icon + email-mode subline visible. After 30s without code entry, spam-folder hint appears. Open `OTPScreen(mode: sms)` (default) — chrome unchanged from today.
- **Wave 5**: With global flag OFF: login screen is identical to today's. With global flag ON: two tabs visible; Telefone is default-selected on first install; switching to E-mail clears phone state; cold-restart with `last_login_mode = "email"` opens directly on E-mail tab.
- **Wave 6**: Full happy path on staging. Then test each error:
  - Disable `email_otp_enabled` for test school → expect 422 → "Sua escola usa OTP por telefone…" message
  - Send with unknown email → 404 → "Não encontramos uma conta…"
  - Send twice within 60s → 429 → countdown message
  - Wait 6 minutes between Send and Verify → 410 → "Código expirado"
  - Enter wrong code 5 times → 429 → "Muitas tentativas"
- **Wave 7**: Inspect staging Crashlytics breadcrumbs for any email or 6-digit code — must be absent. Set test user `is_approval=false` → email-OTP success → lands on `YourAccountUnderReviewScreen` not `MainScreen`.

---

## Known limitations carried into v1

- AR translations of the 15 `email_otp_*` keys are TBD (localization team). PT-BR + EN ship; AR placeholder keys are present so AR users see the key name rather than crashing.
- SendGrid free tier is 100 emails/day — sufficient for the pilot. Track volume; upgrade plan or swap to Brevo if a school's pilot pushes the cap.
- Email uniqueness collision (same email across multiple schools) — deferred to v1.x if it surfaces. Backend `/send` will pick the first match in the meantime.
- The mid-session "try email instead" link on the SMS OTP screen — deferred. Users must restart from the login tab to switch modes.
- Mobile does not display SendGrid delivery state (`mail/{autoId}.delivery.state`). If users report "didn't receive", support uses the Firestore console.

---

## Backend coordination (one umbrella ticket)

Open one ticket with the backend team covering:
1. `POST /auth/email-otp/send` per [contracts/rest-endpoints.md](contracts/rest-endpoints.md)
2. `POST /auth/email-otp/verify` per the same
3. `email_otps` table schema (`email_hash`, `otp_hash`, `school_id`, `expires_at`, `attempts`, `created_at`)
4. Firestore template doc reader + `{{code}}` substitution
5. Firestore `mail/{autoId}` writer per [contracts/firestore-mail-schema.md](contracts/firestore-mail-schema.md)
6. 90-day audit log retention + "Delete my account" purge hook
7. LGPD: server logs MUST NOT contain plain-text email or OTP code (use email_hash)
8. `email_otp_enabled` per-school flag reader (Firestore `config/{schoolId}`)
9. `mail/*` cleanup Cloud Function (delete SUCCESS docs older than 30 days)
