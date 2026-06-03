# Quickstart — Server-Driven Authentication

This is the "pick it up and ship it" walkthrough for engineers landing on `server_driven_auth` mid-flight. It covers (a) where the code lives, (b) how to run the flow locally, (c) how to flip the two flags, (d) how to verify each of the 5 scenarios, and (e) the cutover playbook.

## 1. Mental model in 60 seconds

- Flutter sends `phone` (and later `email` or `password`) to one of 8 endpoints under `/auth/`.
- Every entry/step endpoint returns a uniform envelope `{ action, temp_token?, expires_in?, user? }`.
- `AuthActionDispatcher` maps the 8 `action` strings → a navigation/state change. Nothing else routes.
- Two flags govern the system:
  - **Client `server_driven_auth_enabled`** (Firestore `config/*`, default `false`) — switches the app between **legacy Firebase login** and **new server-driven login**. "Flag on Firebase, pass not delete."
  - **Server `EMAIL_OTP_ENABLED`** (backend `.env`, default `true`) — enforces OTP email step in self-register + forgot-password. Mobile never reads it; only obeys whichever `action` the server returns.

## 2. Where the code lives

```
lib/features/server_driven_auth/
├── server_driven_auth_di.dart                 # GetIt registrations
├── dispatcher/auth_action_dispatcher.dart     # the only `switch (action)` in the app
├── data_sources/
│   ├── server_driven_auth_repository.dart     # abstract: 8 methods
│   └── server_driven_auth_impl.dart           # NetworkClient.handleRequest impls
├── models/                                    # AuthAction + 6 request models + 2 response envelopes
├── presentation/
│   ├── bloc/
│   │   ├── server_driven_auth_cubit.dart      # one method per endpoint
│   │   └── server_driven_auth_state.dart
│   ├── login_screen.dart                      # phone + inline password + forgot + register
│   ├── self_register_screen.dart
│   ├── set_initial_password_screen.dart       # PopScope canPop:false
│   ├── email_otp_screen.dart                  # registration OTP
│   ├── pending_approval_screen.dart           # delegates to YourAccountUnderReviewScreen
│   ├── forgot_password_email_screen.dart
│   ├── reset_otp_screen.dart                  # reset OTP (distinct screen)
│   ├── set_new_password_screen.dart           # PopScope canPop:false
│   └── widgets/
│       ├── password_field.dart
│       ├── otp_pin.dart
│       └── inline_forgot_button.dart
```

Legacy auth (`lib/features/login/`, `lib/features/otp/`, `lib/features/register/`) is untouched and continues to run when the flag is off.

## 3. Run it locally

### 3.1 Both flavors

```bash
# Parents (default)
flutter run -t lib/main.dart --flavor parents

# Teachers
flutter run -t lib/main_professores.dart --flavor professores
```

Same flavor matrix as the rest of the app — nothing new.

### 3.2 Toggle the rollout flag

The rollout flag lives in the Firestore `config/*` org-wide doc (or per-school doc) as `server_driven_auth_enabled: bool`.

- For local dev without flipping Firestore, temporarily seed `ConfigState.serverDrivenAuthEnabled = true` in `ConfigCubit.fromJson` defaults, OR force it via `LocalDatabaseRepo` debug entry, OR override in the splash route at a known debug build flag. **Do not commit the override.**
- The HydratedCubit picks up the new value on the next cold start (or `ConfigCubit.refresh()` if you wire one).

### 3.3 Toggle the backend OTP flag

In the backend repo's `.env`:
```env
EMAIL_OTP_ENABLED=true   # default — OTP enforced
# or
EMAIL_OTP_ENABLED=false  # dev/QA only — bypass self-register OTP; block forgot-password
```
After flipping:
```bash
php artisan config:cache
```
No app rebuild required (master-prompt acceptance #17). The artisan command `php artisan auth:check-config` warns if `APP_ENV=production AND EMAIL_OTP_ENABLED=false`.

### 3.4 Queue worker (backend)

OTP delivery is queued. In the backend repo:
```bash
php artisan queue:work --tries=3 --backoff=30 --queue=default
```
In production, run it under Supervisor / systemd / Horizon (long-running, supervised). If the worker stops, the API still returns 200 on send — the queue piles up; restarting drains it.

## 4. Verify the 5 scenarios

Run these against the staging backend, both flavors. The full smoke-test transcript lives in `TESTING.md` at the repo root; this is the abbreviated checklist for the spec.

### Scenario 1 — Admin-created user, first login
1. Seed DB row: `phone = X, email = Y, password = NULL, status = 'create'`.
2. In app: enter phone, tap Next.
3. **Expect:** navigate to `SetInitialPasswordScreen`. OS back gesture suppressed.
4. Set + confirm password, submit.
5. **Expect:** JWT received; `MainScreen` if `is_approval = true`, else `PendingApprovalScreen`.

### Scenario 2 — Self-registration
1. Tap "Create new account" on LoginScreen.
2. Fill the form, submit.
3. **`EMAIL_OTP_ENABLED=true`**: receive OTP at test Gmail within ~30 s, enter it on `EmailOtpScreen`, expect `PendingApprovalScreen`.
4. **`EMAIL_OTP_ENABLED=false`**: expect `PendingApprovalScreen` immediately (no OTP screen, no email).

### Scenario 3 — Admin-created user, subsequent logins
1. From Scenario 1, log out, return to LoginScreen.
2. Enter the same phone, tap Next.
3. **Expect:** the password field appears **inline** (no navigation, no flicker).
4. Enter the password, submit.
5. **Expect:** `MainScreen`.

### Scenario 4 — Self-registered user, post-admin-approval
1. Flip the user's `status` from `pending` to `active` server-side.
2. Enter phone, tap Next.
3. **Expect:** `REQUIRE_PASSWORD` → inline password reveal (not `GO_TO_PENDING_APPROVAL`).
4. Submit registration-time password.
5. **Expect:** `MainScreen`.

### Scenario 5 — Forgot password
1. From the `LoginPasswordRequired` inline state, tap "Forgot password?".
2. **Expect:** navigate to `ForgotPasswordEmailScreen`.
3. Enter registered email, tap Send code.
4. **`EMAIL_OTP_ENABLED=true`**: receive reset OTP, enter on `ResetOtpScreen`, set new password, expect return to a cleared LoginScreen with success snackbar.
5. **`EMAIL_OTP_ENABLED=false`**: expect a `sda_error_reset_unavailable` message on `ForgotPasswordEmailScreen`; no email sent; no navigation.
6. Verify (with the flag back on) that the **prior JWT for this user on a second device is invalidated** — that device hits 401 on its next API call and force-logouts.

### Enumeration check
- `check-identifier` on an unknown phone → inline "create one?" prompt (NOT a 422/401 error).
- `forgot-password` on an unknown email returns the same response shape as a known email; no email is sent.

## 5. Cutover playbook

1. Confirm backend has shipped all 8 endpoints + migration + Gmail SMTP + `EMAIL_OTP_ENABLED=true` + the artisan check passes.
2. QA runs all 5 scenarios + both flag-matrix states on staging on both flavors.
3. Pick a single **pilot school**. In Firestore, set `config/{pilotSchoolId}.server_driven_auth_enabled = true`. Leave the org-wide flag `false` for now.
4. Ship a new mobile build to the stores containing this PR (the new feature is dark behind the flag; the legacy flow is the default).
5. Soak the pilot school for **7 days**. Monitor:
   - Login success rate.
   - Crashlytics for any `sda_error_unknown_action` reports (would indicate backend/app version skew).
   - Backend logs for `EMAIL_OTP_ENABLED=false` warnings (should be zero in prod).
   - SMTP / queue health.
6. If clean: flip the org-wide flag to `true`. Monitor full rollout.
7. Two weeks after full rollout: open Wave 8 cleanup PR (delete legacy auth feature folders, remove `firebase_auth` if otherwise unused, mark sibling specs deprecated).

## 6. Common pitfalls

- **The dispatcher must be the only `switch (action)` in the app.** Grep before merging: `grep -r "REQUIRE_PASSWORD\|CREATE_NEW_PASSWORD" lib/features/server_driven_auth/presentation` should hit only the dispatcher file (and the localization strings, if any).
- **The inline password reveal is a state transition, NOT a `Navigator.push`.** If you find yourself pushing a route on `REQUIRE_PASSWORD`, you've misread the spec — fix it to a `BlocBuilder` switch on `LoginPasswordRequired`.
- **`temp_token`s are in-memory only.** Do not persist them. Cold-restarting a flow in the middle of OTP entry returns the user to LoginScreen by design.
- **Approval gate runs on every JWT issuance.** `set-initial-password` and `login` both go through `UserBloc.loggedIn` → the gate. Easy to forget on the new screens.
- **PII redaction.** When adding new endpoints, remember to extend `NetworkClient._redactBody` allowlist or the redaction tests will fail.
- **Flavor role.** The `role` field at `check-identifier` is `context.isProfessors ? 'teacher' : 'parent'`. Don't infer from `UserBloc` pre-login (there is no user yet).

## 7. When something goes wrong

- **`sda_error_unknown_action` surfaces in prod** → backend returned an `action` string the dispatcher doesn't recognize. Most likely cause: backend added a new action; app version is behind. Add the action to `AuthAction` + dispatcher and ship a build.
- **OTP email never arrives** → check `php artisan queue:work` is running. Check `failed_jobs` table. Check Gmail "Sent" folder. Check that 2-Step Verification is on for the project Gmail account and the App Password in `.env` has no embedded spaces.
- **Login succeeds but app immediately logouts** → 401 from a stale `token_version` (Scenario 5 follow-up on a second device). This is correct behavior; the user just needs to log in fresh.
- **`auth:check-config` warns in production** → flip `EMAIL_OTP_ENABLED=true` immediately and `php artisan config:cache`. The warning means OTP enforcement is currently bypassed — production is in a degraded security state.
