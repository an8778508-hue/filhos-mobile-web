# Tasks: Email OTP — login by email-delivered code

Dependency-ordered task list generated from [plan.md](plan.md) + [research.md](research.md). Each task is independently shippable behind the global feature flag `email_otp_globally_visible` (default `false`), so mobile can land partial waves without exposing them to users.

**Numbering**:
- `T-prep-N` — backend / ops prerequisites (NOT mobile)
- `T-EM-NN` — feature implementation tasks (mobile), grouped by area
- `T-qa-N` — quality / hardening tasks

Each task lists: priority, area, dependencies (other task IDs), and the spec FR(s) it satisfies.

---

## Phase A — Backend & ops prerequisites *(not mobile work, but tracked here for visibility)*

These block end-to-end testing. Mobile foundation work (Wave 1-3) can proceed in parallel.

- [ ] **T-prep-1** — Verify the `escola-cede2` Firebase project is on **Blaze plan**. Upgrade if Spark. *(Cloud Functions are a hard prereq for the extension; free quota covers OTP volume.)* — backend/ops
- [ ] **T-prep-2** — Install the **"Trigger Email from Firestore"** Firebase Extension. Configure SMTP connection URI with SendGrid API key + sender `noreply@criarte.filhos.app`. Watch collection: `mail`. Disable the extension's built-in template engine (we render server-side). — backend/ops
- [ ] **T-prep-3** — Configure **DKIM + SPF** records for the sender domain. Wait for DNS propagation (≤ 24h) before launch test. — DevOps/DNS
- [ ] **T-prep-4** — Create the three Firestore docs `email_templates/email_otp_{pt,en,ar}` per [contracts/firestore-mail-schema.md](contracts/firestore-mail-schema.md). PT copy is mandatory; EN required; AR can ship later (backend falls back to PT). — backend + content
- [ ] **T-prep-5** — Implement `POST /auth/email-otp/send` per [contracts/rest-endpoints.md](contracts/rest-endpoints.md) — user lookup, school-flag check, code gen, hash, store in `email_otps`, render template, write `mail/{autoId}`, return 200 with masked_email + retry_after. *(FR-EM-05, FR-EM-13, FR-EM-15, FR-EM-16, FR-EM-20)* — backend
- [ ] **T-prep-6** — Implement `POST /auth/email-otp/verify` per the same — record lookup, expiry check, HMAC compare, attempt counter, mint access token via existing login token path. *(FR-EM-10, FR-EM-11, FR-EM-15, FR-EM-16)* — backend
- [ ] **T-prep-7** — Add `email_otp_enabled` field to `config/{schoolId}` documents (default `false`). Backend reads this in `/send`. — backend/admin
- [ ] **T-prep-8** — Add `email_otp_globally_visible` field to the org-wide `config/*` document (default `false`). Flip to `true` to expose the email tab in mobile builds. — backend/admin
- [ ] **T-prep-9** — Cloud Function: scheduled cleanup of `mail/*` docs where `delivery.state == "SUCCESS"` and `endTime < 30 days ago`. LGPD minimization. — backend
- [ ] **T-prep-10** — Hook the existing "Delete my account" path: on user deletion, purge `email_otps` rows + 90-day audit log for that user. — backend (FR-EM-19)
- [ ] **T-prep-11** — Confirm server logs MUST NOT contain plain-text email or OTP code. Use `email_hash` in all log lines. Spot-check staging. — backend (LGPD)

---

## Phase B — Mobile foundation (Wave 1)

Independent of backend; can start immediately. Each task is ≤ 1 day of work for a senior dev.

- [ ] **T-EM-01** — `OTPDeliveryMode` enum. Create `lib/features/otp/models/otp_delivery_mode.dart`:
  ```dart
  enum OTPDeliveryMode { sms, email }
  ```
  No tests; no DI wiring. *(plan §Project Structure)*
- [ ] **T-EM-02** — Three new `LocalKeys` in `lib/core/local_db/local_db_repo.dart`: `last_email_otp_request`, `last_email_otp_email`, `last_login_mode`. Constants only — no behavior change to `LocalDatabaseImpl`. *(FR-EM-14, FR-EM-02; data-model §LocalKeys)*
- [ ] **T-EM-03** — Extend `ConfigState` / `ConfigCubit`:
  - Add `final bool emailOtpGloballyVisible` (default `false`)
  - Update `toJson` / `fromJson` to round-trip `'email_otp_globally_visible'`
  - Verify cold-start round-trip manually (set field via Firestore → force-kill → reopen → `state.emailOtpGloballyVisible` reflects)
  - *(FR-EM-01; data-model §ConfigCubit)*
- [ ] **T-EM-04** — Add the 15 new localization keys to `lib/core/localization/localization_keys.dart`. PT-BR + EN translations into `assets/langs/pt.json` and `assets/langs/en.json`. AR keys added with placeholder values (the key string itself as fallback) until localization team supplies copy. *(FR-EM-17, spec §Localization Requirements)*
- [ ] **T-EM-05** — Extend `network_client.dart`'s `_redactBody` allowlist to redact request/response bodies for paths matching `auth/email-otp/*`. Mirror the medication redaction pattern. *(FR-EM-18, plan §Constitution Check III)*

**Gate before Wave 2**: `flutter analyze` green on both flavors. Cold-start round-trip of `emailOtpGloballyVisible` verified. All 5 tasks merged or sitting on the same branch.

---

## Phase C — Repository methods (Wave 2)

Depends on: T-EM-01 (for the enum if used in signatures — actually not used; the enum is presentation-only). No dependencies from Phase B.

- [ ] **T-EM-06** — Create wire-format model classes under `lib/features/login/models/`:
  - `email_otp_send_request.dart` — `{email, lang}` with `toJson`
  - `email_otp_send_response.dart` — `{maskedEmail, retryAfter}` with `fromJson`
  - `email_otp_verify_request.dart` — `{email, code}` with `toJson`
  - `email_otp_verify_response.dart` — `{accessToken, user: UserModel}` with `fromJson` (delegates to `UserModel.fromJson`)
  - *(data-model §EmailOTP* entries)*
- [ ] **T-EM-07** — Extend `LoginRepository` interface (`lib/features/login/data_sources/login_repository.dart`):
  ```dart
  static const String emailOtpSendEndpoint = 'auth/email-otp/send';
  static const String emailOtpVerifyEndpoint = 'auth/email-otp/verify';
  Future<Either<Failure, EmailOTPSendResponse>> requestEmailOTP({required String email});
  Future<Either<Failure, EmailOTPVerifyResponse>> confirmEmailOTP({required String email, required String code});
  ```
  *(data-model §LoginRepository)*
- [ ] **T-EM-08** — Implement both methods in `LoginImpl`. Both go through `networkClient.handleRequest` with `NetworkRequest(method: HttpMethod.post, ...)` and the `lang` from `ConfigCubit.state`. No manual auth header. *(FR-EM-05, FR-EM-10; plan §Constitution Check III)*
- [ ] **T-EM-09** — Smoke test against backend staging once T-prep-5/6 land: from a debug/test harness call `loginRepository.requestEmailOTP(email: '<staging test email>')` and confirm a 200 response with non-empty `maskedEmail`. Then verify with the code that arrives in the test inbox.

**Gate before Wave 3**: smoke test passes against backend staging.

---

## Phase D — OTPBloc extension (Wave 3)

Depends on: T-EM-06 through T-EM-08.

- [ ] **T-EM-10** — Add non-state fields to `OTPBloc`:
  ```dart
  OTPDeliveryMode currentMode = OTPDeliveryMode.sms;
  String? currentMaskedEmail;
  ```
  *(data-model §OTPBloc)*
- [ ] **T-EM-11** — Implement `requestEmailOTP(email, remember)` mirroring the SMS path but using `last_email_otp_request` / `last_email_otp_email` Hive keys. Reuse `_startTimer`. Set `currentMode = email` and store the returned `maskedEmail`. *(FR-EM-05, FR-EM-12, FR-EM-13)*
- [ ] **T-EM-12** — Implement `confirmEmailOTP(email, code)` that POSTs verify, calls `UserBloc.loggedIn(response.user)` on success, deletes the email-specific Hive cooldown keys, persists `rememberMe` if set. *(FR-EM-10, FR-EM-11)*
- [ ] **T-EM-13** — Implement `resendEmailOTP(email)` — thin wrapper around `requestEmailOTP` preserving `rememberMe`. *(spec User Story 2)*
- [ ] **T-EM-14** — Private helper `_initEmailCooldown(String email)` mirroring the existing `_init(String phone)` logic but reading the email-specific Hive keys. *(FR-EM-14, R3)*
- [ ] **T-EM-15** — Verify the SMS path still works: cold-start parents flavor → enter phone → receive SMS → enter code → login. **Both flows must coexist without regression.**

**Gate before Wave 4**: SMS path verified unchanged; email methods callable in DI; tracked states transition correctly via Cubit observer in debug.

---

## Phase E — OTPScreen mode-aware chrome (Wave 4)

Depends on: T-EM-01 (enum), T-EM-04 (localization keys for new copy).

- [ ] **T-EM-16** — Add `OTPDeliveryMode mode = OTPDeliveryMode.sms` parameter to `OTPScreen` constructor. Default preserves all current callers. *(FR-EM-07, R2)*
- [ ] **T-EM-17** — Create `lib/features/otp/presentation/widgets/delivery_mode_chrome.dart` — small widget that renders:
  - **mode == sms**: phone icon + existing localized phone-mode subline (unchanged copy)
  - **mode == email**: envelope icon + `email_otp_verify_title` headline + `email_otp_verify_subline` with masked email substituted via `bloc.currentMaskedEmail` + spam-folder hint
  *(FR-EM-08, FR-EM-09, User Story 3)*
- [ ] **T-EM-18** — Wire `DeliveryModeChrome` into `otp_screen.dart`. Pass `mode` from the constructor parameter; the masked email comes from the bloc. *(FR-EM-09)*
- [ ] **T-EM-19** — After 30 s on the screen without code entry in email mode, surface the `email_otp_check_spam_hint` text. Reuse the existing cooldown timer's tick to drive this — no new timer. *(User Story 3 Scenario 3)*
- [ ] **T-EM-20** — Confirm the SMS-mode render is **pixel-identical** to today (no copy or icon regressions). This is the single most likely place for a stealth regression — verify on both flavors before merging Wave 4.

**Gate before Wave 5**: pass `mode: email` from a debug harness route → confirm envelope + masked-email subline + spam hint visible. SMS path visually unchanged.

---

## Phase F — Login screen tab picker (Wave 5)

Depends on: T-EM-03 (config field), T-EM-04 (localization), T-EM-10 through T-EM-14 (bloc methods callable).

- [ ] **T-EM-21** — Create `lib/features/login/presentation/widgets/email_tab.dart`:
  - Email `TextFormField` with `email_otp_email_placeholder` placeholder
  - Inline format validator using the permissive regex from research R5
  - Send CTA (`email_otp_send_cta`) disabled until format valid
  - Loading state replaces CTA text while the request is in flight
  - On Send tap: `OTPBloc.requestEmailOTP(email: ..., remember: rememberMeFromLoginScreen)`
  *(FR-EM-04, FR-EM-05, FR-EM-06)*
- [ ] **T-EM-22** — Modify `LoginScreen`:
  - Wrap existing phone-form content in a `DefaultTabController` + `TabBar` with two tabs: "Telefone" and "E-mail"
  - **Render the TabBar only when `context.read<ConfigCubit>().state.emailOtpGloballyVisible == true`** — when false, the screen renders exactly as today (no regression)
  - On tab change: clear the inactive tab's state; persist `last_login_mode` to Hive (FR-EM-03, FR-EM-02)
  - Pre-select the matching tab on init based on `last_login_mode` (default `"sms"`)
  *(FR-EM-01, FR-EM-02, FR-EM-03, R11)*
- [ ] **T-EM-23** — In the LoginScreen state listener, when `OTPBloc.state` becomes `OTPReady` AND `currentMode == email`, navigate to `OTPScreen(mode: OTPDeliveryMode.email)`. The existing SMS branch (navigate to default `OTPScreen()`) is unchanged. *(FR-EM-07)*
- [ ] **T-EM-24** — Verify when `emailOtpGloballyVisible == false`, the LoginScreen has no visible change from today's behavior (no TabBar, just the phone form). This is the **kill-switch** for shipping the feature dark.

**Gate before Wave 6**: with global flag OFF — login screen identical to today. With flag ON — both tabs render, tab persistence works across hot-restart.

---

## Phase G — End-to-end wiring & error states (Wave 6)

Depends on: all prior waves merged on the same branch.

- [ ] **T-EM-25** — Map all 9 backend error codes from [contracts/rest-endpoints.md §Error code → localization key mapping](contracts/rest-endpoints.md) to the `email_otp_error_*` localization keys. Confirm `OTPBloc` propagates these into `OTPFailure(NetworkFailure(message: <code>))` so the existing `ErrorField` widget surfaces them. *(FR-EM-16, FR-EM-17)*
- [ ] **T-EM-26** — Special handling for `code_expired` (410): clear `last_email_otp_request` immediately on receipt so the user can resend without waiting out the cooldown. *(FR-EM-15)*
- [ ] **T-EM-27** — Special handling for `email_send_failed` (503): do NOT start the cooldown — user retries immediately. *(spec §Edge Cases, FR-EM-12)*
- [ ] **T-EM-28** — Special handling for `email_otp_not_enabled_for_school` (422): surface the localized message and visually nudge the user back to the "Telefone" tab (e.g., subtle arrow or highlighted tab). *(spec §Edge Cases)*
- [ ] **T-EM-29** — Full happy-path E2E on staging: parents flavor, real test email, full request → email arrives → enter code → land on MainScreen. Repeat on teachers flavor.
- [ ] **T-EM-30** — Test each error path on staging (set up the conditions described in [quickstart.md §Smoke tests per wave - Wave 6](quickstart.md)).

**Gate before Wave 7**: all 9 error paths surface the right localized message on both flavors.

---

## Phase H — QA & hardening (Wave 7)

- [ ] **T-qa-1** — **LGPD verification**: inspect staging Crashlytics breadcrumbs after 100+ test sends. Confirm zero occurrences of plain-text emails or 6-digit codes. If anything leaks, broaden the `_redactBody` allowlist before merge. *(FR-EM-18, SC-EM-04)*
- [ ] **T-qa-2** — **Approval gate**: set a test user's `is_approval = false`, run the full email-OTP flow → verify the user lands on `YourAccountUnderReviewScreen` (NOT `MainScreen`). *(FR-EM-11; constitution Principle VIII)*
- [ ] **T-qa-3** — **Both-flavor release build**:
  - `flutter build apk --flavor parents -t lib/main.dart`
  - `flutter build apk --flavor professores -t lib/main_professores.dart`
  Confirm both succeed. *(Quality Gate)*
- [ ] **T-qa-4** — **`flutter analyze`** final pass on both flavors. Zero warnings, zero errors. *(Quality Gate)*
- [ ] **T-qa-5** — **Documentation**: add a short note to [CLAUDE.md §1.2 Core user flows](../../CLAUDE.md) describing the email-OTP path so future contributors aren't surprised by the dual flow.
- [ ] **T-qa-6** — **Pilot rollout plan**: identify 1 pilot school with SMS-delivery issues; coordinate with that school's admin to flip their `email_otp_enabled = true` after merge. Monitor SendGrid dashboard + Firestore `mail/*.delivery.state` for the first week. *(SC-EM-05)*

---

## Deferred to v1.x (not in this scope)

- **Email-uniqueness collision** (same email across multiple schools) — handled trivially server-side (pick first match) for v1; needs a school picker if it surfaces.
- **First-time onboarding via email OTP** — current scope is login-only.
- **Mid-session "try email instead" link** on the SMS OTP screen — not in spec.
- **NPS prompt after successful email-OTP login** — analytics measurement only, not required for v1.
- **Mobile-side SendGrid delivery state visualization** — ops uses Firestore console for now.
- **SMS OTP cooldown latent bug fix** (research R10) — separate PR against the OTP feature.

---

## Estimate

| Phase | Mobile dev-days (senior) |
|---|---|
| A — prereqs (backend; tracked for visibility) | (out of scope) |
| B — Foundation | 1 |
| C — Repository | 0.5 |
| D — OTPBloc | 1 |
| E — OTPScreen chrome | 1 |
| F — Login tab picker | 1 |
| G — E2E + errors | 1 |
| H — QA | 0.5 |
| **Total** | **~6 mobile dev-days** |

Backend work (T-prep-1 through T-prep-11) is parallel-trackable; estimate ~3-5 backend dev-days depending on existing infra.
