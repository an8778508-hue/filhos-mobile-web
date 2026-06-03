# TESTING — Server-Driven Authentication

Manual smoke-test guide for the `server_driven_auth` feature. Covers all 5 scenarios + the `EMAIL_OTP_ENABLED` flag matrix + the rollout-flag matrix.

> **Scope:** the Flutter half of `server_driven_auth` (this repo). The backend half lives in a separate repository and is exercised against staging; see [specs/server_driven_auth/contracts/integration-contract.md](specs/server_driven_auth/contracts/integration-contract.md) for the backend test plan.

---

## 0. Prerequisites

1. Backend staging deployment with all 8 endpoints implemented per [specs/server_driven_auth/contracts/rest-endpoints.md](specs/server_driven_auth/contracts/rest-endpoints.md). Stub responses are acceptable for unit-style smoke tests; production happy-path checks require the full backend.
2. A reachable test Gmail inbox for OTP delivery checks.
3. Both Flutter flavors available:
   ```bash
   flutter run -t lib/main.dart            --flavor parents
   flutter run -t lib/main_professores.dart --flavor professores
   ```
4. Firestore `config/*` document writable so you can toggle `server_driven_auth_enabled`.
5. Backend `.env` editable so you can toggle `EMAIL_OTP_ENABLED` (run `php artisan config:cache` between flips).

## 1. Wire the rollout flag

Set on the org-wide (or per-pilot-school) config doc:

```
config/criarte_parents.server_driven_auth_enabled = true
```

After flipping, cold-restart the app once so the HydratedCubit picks up the new value. Verify in DevTools / on-screen behavior that LoginScreen now shows:
- A phone field + **Avançar** / Next button (no SMS-OTP CTA visible).
- A **Criar nova conta** / Create new account link at the bottom.

If the legacy Firebase phone-SMS LoginScreen still appears, the flag is off / not propagated.

---

## 2. The 5 canonical scenarios

For each, run on **both flavors**. Note the role sent: `parent` (parents flavor) vs `teacher` (professores flavor).

### Scenario 1 — Admin-created user, first login

**Setup** (backend, staging): seed a row with `phone = +5511999990001`, `email = test1@example.com`, `password = NULL`, `status = 'create'`.

| Step | Action | Expected |
|---|---|---|
| 1 | Open the app, reach LoginScreen | Phone field visible; password field NOT visible |
| 2 | Enter `11999990001`, tap **Next** | `POST auth/check-identifier` fires |
| 3 | Server returns `{ action: "CREATE_NEW_PASSWORD", temp_token, user }` | App **navigates** to `SetInitialPasswordScreen`. AppBar shows no back button; OS gesture-back is suppressed (PopScope canPop:false) |
| 4 | Type a password (≥ 8 chars) + matching confirmation, tap **Save** | `POST auth/set-initial-password` fires with the temp_token |
| 5 | Server returns `{ data: UserModel, access_token }` | `UserBloc.loggedIn(user)` called; app routes through the approval gate:<br>• `is_approval == true` → `MainScreen`<br>• `is_approval == false` → `YourAccountUnderReviewScreen` |

**Negative checks:**
- Submit with passwords mismatching → snackbar `sda_error_password_mismatch`. No request fires.
- Submit with password < 8 chars → snackbar `sda_error_password_weak`. No request fires.
- Wait > 10 min before submit → server returns `TOKEN_EXPIRED` → snackbar `sda_error_token_invalid`.

### Scenario 2 — Self-registration via app

**With `EMAIL_OTP_ENABLED = true` (default):**

| Step | Action | Expected |
|---|---|---|
| 1 | LoginScreen → tap **Create new account** | Navigate to `SelfRegisterScreen` |
| 2 | Fill name, phone, email, password, confirm; tap submit | `POST auth/self-register` fires |
| 3 | Server returns `{ action: "VERIFY_EMAIL_OTP", temp_token, expires_in: 600 }` | App navigates to `EmailOtpScreen` |
| 4 | OTP email arrives at the test Gmail inbox within ~30 s | Subject contains "Criarte"; body shows a 6-digit code |
| 5 | Enter the OTP | `POST auth/verify-email-otp` fires |
| 6 | Server returns `{ action: "GO_TO_PENDING_APPROVAL" }` | App navigates to `PendingApprovalScreen` (visually identical to `YourAccountUnderReviewScreen`) |

**With `EMAIL_OTP_ENABLED = false`:**

| Step | Action | Expected |
|---|---|---|
| 2 | Submit registration | `POST auth/self-register` fires |
| 3 | Server returns `{ action: "GO_TO_PENDING_APPROVAL" }` **directly** (no OTP, no email) | App navigates to `PendingApprovalScreen`. **No `EmailOtpScreen` appears.** |
| 4 | Check test Gmail inbox | **No email arrives.** |
| 5 | Check backend logs | A `[WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}` line is present. |

**Negative checks:**
- Email already in DB → `409 EMAIL_ALREADY_REGISTERED` → snackbar `sda_error_generic`.
- 5 rapid submissions in 1 min → `429 RATE_LIMITED` → snackbar `sda_error_generic`.

### Scenario 3 — Admin-created user, subsequent logins

**Setup:** the user from Scenario 1 is now `password != NULL, status = 'active'`.

| Step | Action | Expected |
|---|---|---|
| 1 | LoginScreen → enter phone, tap **Next** | `POST auth/check-identifier` fires |
| 2 | Server returns `{ action: "REQUIRE_PASSWORD" }` | **No navigation.** Password field reveals **inline** on the same LoginScreen. Keyboard stays open. No screen flicker. "Forgot password?" link appears below the password field. |
| 3 | Enter the password, tap **Log in** | `POST auth/login` fires |
| 4 | Server returns `{ data, access_token }` | `UserBloc.loggedIn(user)`; approval-gate routing as in Scenario 1 step 5. |

**Negative checks:**
- Wrong password → `401 INVALID_CREDENTIALS` → snackbar `sda_error_invalid_credentials`. Field stays for re-entry.
- `status = 'suspended'` → server returns `403 ACCOUNT_SUSPENDED` on login attempt (or `check-identifier` returns `ACCOUNT_SUSPENDED` action) → inline suspended message.

### Scenario 4 — Self-registered user, post-admin-approval

**Setup:** flip a `pending` user from Scenario 2 to `status = 'active'` server-side.

| Step | Action | Expected |
|---|---|---|
| 1 | Enter the phone the user registered with | `REQUIRE_PASSWORD` (not `GO_TO_PENDING_APPROVAL` anymore) |
| 2 | Enter the registration-time password | Login succeeds; `MainScreen` reached. |

### Scenario 5 — Forgot password

**With `EMAIL_OTP_ENABLED = true`:**

| Step | Action | Expected |
|---|---|---|
| 1 | From the `LoginPasswordRequired` inline state in Scenario 3, tap **Forgot password?** | Navigate to `ForgotPasswordEmailScreen` |
| 2 | Enter the registered email, tap **Send code** | `POST auth/forgot-password` fires |
| 3 | Server returns `{ action: "VERIFY_RESET_OTP", temp_token, expires_in }` | App navigates to `ResetOtpScreen` |
| 4 | OTP email arrives at the test inbox | Subject indicates password reset; body has 6-digit code |
| 5 | Enter the OTP | `POST auth/verify-reset-otp` fires |
| 6 | Server returns `{ action: "SET_NEW_PASSWORD", temp_token }` | App navigates to `SetNewPasswordScreen`. Back gesture suppressed (PopScope canPop:false). |
| 7 | Enter new password + confirm, tap Save | `POST auth/reset-password` fires |
| 8 | Server returns `{ success: true }` | App clears the navigation stack back to LoginScreen; success snackbar surfaces `sda_reset_success`. |
| 9 | Enter the phone, tap Next, enter NEW password | Login succeeds. |
| 10 | On a second device that was logged in as the same user pre-reset, perform any authenticated request | Server returns 401 (token_version stale) → interceptor force-logouts → LoginScreen. |

**With `EMAIL_OTP_ENABLED = false`:**

| Step | Action | Expected |
|---|---|---|
| 2 | Enter email, tap Send code | `POST auth/forgot-password` fires |
| 3 | Server returns `403 PASSWORD_RESET_UNAVAILABLE` | Snackbar `sda_error_reset_unavailable`. App **stays on `ForgotPasswordEmailScreen`** — no navigation to OTP screen. No email sent. |
| 4 | Check backend logs | `[WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}` line is present. |

**Negative check (enumeration prevention):**
- Send Forgot Password with an **unregistered** email. Response must have the **same shape** as the success case (returns `VERIFY_RESET_OTP` with a dummy temp_token, OR `403 PASSWORD_RESET_UNAVAILABLE` if flag off). **No clue from the response** that the email doesn't exist. The dummy token will fail at `verify-reset-otp`.
- Time the response on a known-existing vs unknown email — they should be indistinguishable from the client (server adds synthetic delay if real path is faster).

---

## 3. `EMAIL_OTP_ENABLED` flag matrix (dedicated section)

Run this whole matrix in one session.

### 3.1 Flag ON (production-safe default)

```env
EMAIL_OTP_ENABLED=true
```
(`php artisan config:cache` after editing.)

| Flow | Expected |
|---|---|
| Self-register | Returns `VERIFY_EMAIL_OTP` envelope; email arrives; user enters code → `GO_TO_PENDING_APPROVAL`. |
| Forgot password (known email) | Returns `VERIFY_RESET_OTP` envelope; email arrives; reset completes. |
| Forgot password (unknown email) | Returns the same `VERIFY_RESET_OTP` envelope with a dummy token; **no email sent**; subsequent OTP entry fails. |
| Direct `POST verify-email-otp` | Validates OTP against stored hash; standard error codes apply. |

### 3.2 Flag OFF (dev/QA only)

```env
EMAIL_OTP_ENABLED=false
```
(`php artisan config:cache` after editing. **NEVER use in production** — `php artisan auth:check-config` warns if `APP_ENV=production` AND flag is false.)

| Flow | Expected |
|---|---|
| Self-register | Returns `GO_TO_PENDING_APPROVAL` directly; `email_verified = true` immediately; **no OTP screen**, **no email**. |
| Forgot password | Returns `403 PASSWORD_RESET_UNAVAILABLE`; **reset is blocked entirely**. |
| Direct `POST verify-email-otp` | Returns `503 OTP_BYPASSED` (defense in depth — mobile should never call it then). |
| Direct `POST verify-reset-otp` | Returns `503 OTP_BYPASSED`. |

### 3.3 Toggle test

1. Verify a self-register flow with flag = `true` (Scenario 2 happy path).
2. Set flag = `false`, run `php artisan config:cache`. **No code change, no app rebuild.**
3. Self-register a new user → confirm immediate `GO_TO_PENDING_APPROVAL` arrival (no OTP screen).
4. Set flag = `true` again, run `php artisan config:cache`.
5. Self-register a third user → OTP behavior is back. (Master-prompt acceptance #17.)

---

## 4. Rollout-flag matrix

### 4.1 `server_driven_auth_enabled = false` (default)

- LoginScreen renders the **legacy Firebase phone-OTP** screen, byte-for-behavior identical to today.
- Social-login buttons (Google / FB / Apple) visible per the existing `ConfigCubit.socialLogin.*` flags.
- "Create account" link goes to the legacy `RegisterScreen`.
- Firebase SMS path works as before.

### 4.2 `server_driven_auth_enabled = true`

- LoginScreen renders the **new server-driven** screen.
- Phone + Next; inline password reveal on `REQUIRE_PASSWORD`; inline "Forgot password?" under the password field; "Create new account" link goes to `SelfRegisterScreen`.
- All 5 scenarios above are reachable.

### 4.3 Toggle test

1. Flag = `false`: legacy login works.
2. Flip flag = `true` server-side, cold-restart the app: new login appears; legacy code is still in the bundle (verify no missing-class errors in logs).
3. Flip back to `false`, cold-restart: legacy works again.

---

## 5. Approval-gate audit

For each of Scenarios 1, 3, 4, and the "log in fresh after reset" step of Scenario 5:

- Test once with `is_approval = true` → assert `MainScreen` is the terminal destination.
- Test once with `is_approval = false` → assert `YourAccountUnderReviewScreen` is the terminal destination (NOT `MainScreen`).

This verifies Constitution Principle VIII is honored on every new terminal JWT path.

---

## 6. Crashlytics audit (LGPD)

Run 50+ representative actions across all 5 scenarios on staging. Then inspect Crashlytics breadcrumbs:

- **Zero** plaintext phone numbers.
- **Zero** plaintext email addresses.
- **Zero** plaintext passwords.
- **Zero** OTP codes.
- **Zero** `temp_token` values.

The redaction allowlist in `lib/core/network/network_client.dart` covers all 8 `auth/*` endpoints (FR-SDA-20). If a leak appears, the allowlist is incomplete or a path didn't match.

---

## 7. Both-flavor sanity check

Repeat at least Scenarios 1, 3, 5 on both flavors:

```bash
flutter run -t lib/main.dart            --flavor parents
flutter run -t lib/main_professores.dart --flavor professores
```

Verify:
- The `role` field in `check-identifier` / `self-register` / `login` differs (`parent` vs `teacher`).
- LoginScreen visual identity matches the flavor (per the existing flavor-conditional theming).
- All scenarios complete on both flavors.

---

## 8. What this guide does NOT cover

- Backend unit / integration tests — owned by the backend team; see [specs/server_driven_auth/contracts/email-otp.md §8](specs/server_driven_auth/contracts/email-otp.md).
- Biometric login (Face ID / Fingerprint) — see the `phone_password_login` draft; deferred from this feature's v1.
- Multi-school edge cases (`users` vs `app_users`) — pending the backend team's table-choice decision (open item).
- Performance / load — out of scope for the manual smoke pass.

---

## 9. Sign-off

Mark complete when every section above passes on both flavors:

- [ ] Section 1 — Rollout flag wired.
- [ ] Section 2.1 — Scenario 1 (admin first login).
- [ ] Section 2.2 — Scenario 2 (self-register, flag on).
- [ ] Section 2.2 — Scenario 2 (self-register, flag off).
- [ ] Section 2.3 — Scenario 3 (admin subsequent login).
- [ ] Section 2.4 — Scenario 4 (self-registered approved).
- [ ] Section 2.5 — Scenario 5 (forgot password, flag on, both devices).
- [ ] Section 2.5 — Scenario 5 (forgot password, flag off — blocked).
- [ ] Section 2.5 — Enumeration prevention.
- [ ] Section 3 — `EMAIL_OTP_ENABLED` toggle (without rebuild).
- [ ] Section 4 — Rollout-flag toggle (legacy path unchanged when off).
- [ ] Section 5 — Approval-gate on every terminal JWT path.
- [ ] Section 6 — Crashlytics has no PII leaks.
- [ ] Section 7 — Both flavors checked.
