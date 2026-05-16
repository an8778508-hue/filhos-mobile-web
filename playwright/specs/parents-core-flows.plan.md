# Parents Core Flows Test Plan

> Flavor: **parents** (`lib/main.dart`, served at `http://127.0.0.1:8765`, Playwright project `parents-generated`).
> Conventions: see [playwright/README.md](../README.md) "Conventions every generated spec must follow" and [.claude/commands/pw-generate.md](../../.claude/commands/pw-generate.md) §1.a.
> Every spec imports `{ test, expect }` from `../../../src/fixtures/index.js`, boots via `app.coldStart()`, locates via the semantics tree, and mocks `**/api/v1/**` (ApiConst.baseUrl is a hard-coded prod `const`).

## Application Overview

The parents app boots: **Splash** (logo, ~2s) → no persisted user → `ChooseLanguageScreen.push`. With a multi-lang remote config, the **language chooser** shows one button per language (live: `English`, `العربية`; Portuguese is the bundled default). Selecting a language persists it (`UserBloc.selectLang`), then for the parents flavor: if `Config.onBoards` is non-empty → **OnBoardScreen** (carousel with `English` language toggle, `Skip`, `Next`), else → **LoginScreen**.

**LoginScreen** (`lib/features/login/presentation/login_screen.dart`): phone form by default (`PhoneField`, country picker defaults to Egypt `+20`), `Keep me logged in` checkbox, `Login` button, `Terms and conditions` / `Privacy policy` links, `Create account` link, and a social row that toggles to an **email/password** form. Validation: empty phone → "This field can't be empty"; invalid email → "This is not a valid email"; password < 6 → "This field can't be empty or less than 6 character".

- `requestOTP` (`LoginBloc`) → in release builds runs the real `FirebaseAuth.verifyPhoneNumber` against the **Auth emulator** → `LoginReady` → pushes **OTPScreen**.
- `OTPScreen` (`lib/features/otp/presentation/otp_screen.dart`): 6-cell `PinCodeTextField`. On 6 digits → `OTPBloc.confirmSMSCode` → `confirmOTP` (Firebase `signInWithCredential` on the Auth emulator) → on success `_successOTP` → `POST auth/login` → `UserModel`. `OTPSuccess` → if `isApproval == true` **MainScreen** (bottom nav: home/diary/events/settings) else **YourAccountUnderReviewScreen**. Invalid code → `OTPFailure` → `ErrorField`. `Resend again` re-requests; back arrow pops to login.
- Email login → `POST auth/login-with-email` → success routes to MainScreen / under-review by `isApproval`; failure → `ErrorField`.
- Social buttons (`auth/social-login`) cannot complete in headless web (Google/Facebook/Apple SDKs unavailable; Apple explicitly rejects web) — negative-only.

**Endpoints to mock** (relative to `**/api/v1/`): `auth/login` (POST), `auth/login-with-email` (POST), `auth/social-login` (POST), `auth/register` (POST), `parent/home` (GET), plus a catch-all `**/api/v1/**` → 503 guard. Firebase Auth is genuinely emulated (do **not** mock `identitytoolkit`/`/emulator/v1`).

**UserModel success body** (`auth/login` → `_successOTP`): `{ "data": { "id": "1", "name": "Ana Test", "phone": "<phone>", "email": "ana@test.com", "access_token": "tok-test", "is_approval": true, "country_code": "EG", "role": "parent" } }`. Set `"is_approval": false` for the under-review branch. `parent/home` accepts `{ "data": {} }` (HomeModel.fromJson tolerates empty).

## Cross-axis coverage targets

| Axis | This plan covers |
|---|---|
| Flavor | parents (professores is a separate plan) |
| Locale | pt-BR (default boot), en-US (select English), ar-SA (select العربية, RTL) |
| Auth state | anonymous, OTP-pending, signed-in-approved (`is_approval:true`→Main), signed-in-pending-approval (`is_approval:false`→under-review) |
| Network | online, `auth/login` request-failed (500), offline on submit |
| Input edges | empty / whitespace / non-numeric / over-length phone & OTP, invalid email, short password, unicode/emoji name on register |
| Viewport | default 1280×900; mobile 390×844 reflow check on login |
| Modern APIs | `page.ariaSnapshot({mode:'ai'})`, `expect(page).toMatchAriaSnapshot()`, `getByRole({description})`, `tracing.group()`, `tracing.startHar()`, async-disposable `page.route()`, `test.abort()` |

---

## Test Scenarios

### 1. Boot & Language Chooser

#### 1.1 Cold start lands on language chooser (anonymous)
**Setup:** async-disposable `page.route('**/api/v1/**')` → 503 (no API expected pre-login).
**Steps:**
1. `await app.coldStart()`.
2. Read `page.ariaSnapshot({ mode: 'ai' })` and capture it as a `tracing.group('boot')` block.
**Expected Results:**
- A `button` with name `English` is visible within 20s.
- A `button` with name `العربية` is visible.
- No `**/api/v1/**` request was made (assert via `page.requests()` filter).

#### 1.2 Language chooser structural snapshot
**Setup:** 503 catch-all.
**Steps:**
1. `await app.coldStart()`.
2. `await expect(page).toMatchAriaSnapshot(...)` against the chooser (buttons `English`, `العربية`).
**Expected Results:** page-level aria snapshot contains both language buttons as `button` roles.

#### 1.3 Select English → onboard carousel
**Setup:** 503 catch-all.
**Steps:**
1. `await app.coldStart()`.
2. Click `button` "English".
**Expected Results:** `button` "Skip" and `button` "Next" become visible (OnBoardScreen).

#### 1.4 Select العربية → RTL onboard/login
**Setup:** 503 catch-all. `test.use({ locale: 'ar-SA' })`.
**Steps:**
1. `await app.coldStart()`.
2. Click `button` "العربية".
**Expected Results:** an interactive widget (button/textbox) is visible after selection; `document.dir`/nearest `[dir=rtl]` present (assert via `browser_evaluate`/`page.evaluate`).

### 2. OnBoard → Login

#### 2.1 Skip onboard reaches Login (phone form)
**Setup:** 503 catch-all.
**Steps:**
1. `await app.coldStart()`; click "English".
2. Click `button` "Skip".
**Expected Results:** Login screen — text `Login Parents` visible; a phone `textbox` visible; `button` "Login" visible; texts `Terms and conditions` and `Privacy policy` visible.

#### 2.2 Next through onboard slides reaches Login
**Setup:** 503 catch-all.
**Steps:**
1. `coldStart`; click "English".
2. Click `button` "Next" repeatedly until "Next" disappears / "Login Parents" appears (cap iterations, fail clean if exceeded).
**Expected Results:** Login screen reached (text "Login Parents" visible).

#### 2.3 Login screen page-level aria snapshot
**Setup:** 503 catch-all.
**Steps:** reach Login via 2.1; `await expect(page).toMatchAriaSnapshot()`.
**Expected Results:** snapshot includes the phone textbox, "Login" button, "Create account", "Terms and conditions", "Privacy policy".

### 3. Login — Phone Form Validation

#### 3.1 Submit empty phone → required error
**Setup:** 503 catch-all.
**Steps:** reach Login (2.1); without typing, click `button` "Login".
**Expected Results:** text "This field can't be empty" visible; still on Login (no OTP screen — "Phone verification" not present); no `auth/login` request fired.

#### 3.2 Submit whitespace-only phone → required error
**Setup:** 503 catch-all.
**Steps:** reach Login; focus phone textbox, type spaces; click "Login".
**Expected Results:** "This field can't be empty" visible; no navigation.

#### 3.3 Toggle Keep-me-logged-in persists visual state
**Setup:** 503 catch-all.
**Steps:** reach Login; locate the `Keep me logged in` checkbox; toggle it.
**Expected Results:** checkbox `checked` state flips (assert `toBeChecked()` / aria-checked via semantics).

### 4. Login — Email Form

#### 4.1 Toggle to email form
**Setup:** 503 catch-all.
**Steps:** reach Login; click the email/phone toggle in the social row.
**Expected Results:** email `textbox` and password `textbox` visible.

#### 4.2 Empty email submit → required error
**Setup:** 503 catch-all.
**Steps:** to email form; click "Login".
**Expected Results:** "This field can't be empty" visible.

#### 4.3 Invalid email format → email error
**Setup:** 503 catch-all.
**Steps:** to email form; type `not-an-email` in email, `secret1` in password; click "Login".
**Expected Results:** "This is not a valid email" visible.

#### 4.4 Short password → length error
**Setup:** 503 catch-all.
**Steps:** to email form; email `ana@test.com`, password `123`; click "Login".
**Expected Results:** an error containing "6" and "character" visible.

#### 4.5 Valid email login, approved user → MainScreen
**Setup:** mock `POST **/api/v1/auth/login-with-email` → 200 `{data:{...is_approval:true}}`; mock `GET **/api/v1/parent/home` → 200 `{data:{}}`; 503 catch-all for the rest. Wrap the submit→land transition in `tracing.group('email-login')`; record a `tracing.startHar()` for this flow.
**Steps:** to email form; email `ana@test.com`, password `secret1`; click "Login".
**Expected Results:** bottom navigation visible (home/diary/events/settings semantics); "Login Parents" no longer visible.

#### 4.6 Valid email login, unapproved user → Account Under Review
**Setup:** mock `auth/login-with-email` → 200 `{data:{...is_approval:false}}`; 503 catch-all.
**Steps:** as 4.5.
**Expected Results:** Account-under-review screen content visible (review/approval copy); bottom nav NOT visible.

#### 4.7 Email login backend 500 → error field
**Setup:** mock `auth/login-with-email` → 500; 503 catch-all.
**Steps:** as 4.5 with valid input.
**Expected Results:** an `ErrorField` message visible; still on Login (email textbox visible).

### 5. OTP Flow (real Auth emulator)

> **Setup (all §5):** `import { pollSmsCode } from '../../../src/helpers/auth.js'`. Phone: build a unique E.164 per run as `+20` + 10 digits derived from `Date.now()` so re-runs don't collide (Egypt is the picker default). Mock `POST **/api/v1/auth/login` per case; mock `GET **/api/v1/parent/home` → `{data:{}}`; async-disposable 503 catch-all. Do NOT mock Firebase Auth.

#### 5.1 Request OTP → OTP screen shown
**Steps:** reach Login (English→Skip); type the local 10-digit number into the phone textbox; click "Login".
**Expected Results:** text "Phone verification" visible; text "Enter OTP that sent to" visible; texts "Did not receive code" and "Resend again" visible.

#### 5.2 Valid OTP, approved user → MainScreen
**Setup:** `auth/login` → 200 `{data:{...is_approval:true}}`.
**Steps:** 5.1; `const code = await pollSmsCode(phoneE164)`; type the 6 digits into the pin field; (fallback) tap the submit arrow.
**Expected Results:** bottom navigation visible; "Phone verification" gone. Wrap OTP→home in `tracing.group('otp-login')`.

#### 5.3 Valid OTP, unapproved user → Account Under Review
**Setup:** `auth/login` → 200 `{data:{...is_approval:false}}`.
**Steps:** as 5.2.
**Expected Results:** account-under-review copy visible; no bottom nav.

#### 5.4 Invalid OTP code → error
**Steps:** 5.1; type `000000` (emulator never minted this) into the pin field.
**Expected Results:** an `ErrorField` visible (code `invalid-verification-code`); still on OTP screen ("Phone verification" visible); no `auth/login` request fired.

#### 5.5 OTP screen back button returns to Login
**Steps:** 5.1; click the back arrow (semantics: button at top-start).
**Expected Results:** Login screen ("Login Parents" / phone textbox) visible again.

#### 5.6 Resend again re-requests a code
**Steps:** 5.1; click "Resend again"; `pollSmsCode` again resolves a (new) code; enter it (approved login mock).
**Expected Results:** still functional — a fresh code resolves and entering it reaches bottom nav.

#### 5.7 `auth/login` 500 after valid OTP → OTPFailure error
**Setup:** `auth/login` → 500.
**Steps:** 5.1; enter the valid `pollSmsCode` code.
**Expected Results:** an `ErrorField` visible on the OTP screen; no bottom nav.

#### 5.8 Offline at OTP confirm → graceful failure
**Setup:** after reaching OTP screen, async-disposable route that aborts `**/api/v1/auth/login`.
**Steps:** 5.1; enter valid code.
**Expected Results:** error surfaced; app does not crash (no `pageerror`); OTP screen still present.

### 6. Register

#### 6.1 Navigate to Register
**Setup:** 503 catch-all.
**Steps:** reach Login; click "Create account".
**Expected Results:** Register screen visible (name/email/password fields — assert by visible textboxes + a register/submit button).

#### 6.2 Register validation — empty submit
**Setup:** 503 catch-all.
**Steps:** to Register; submit empty.
**Expected Results:** at least one "This field can't be empty" visible.

#### 6.3 Register with unicode/emoji name accepted by field
**Setup:** mock `POST **/api/v1/auth/register` → 200 `{data:{...is_approval:false}}`.
**Steps:** to Register; name `Añá 😀 الاسم`, valid email/password/confirm; submit.
**Expected Results:** no client validation error on the name; request fired; routes to under-review (or success copy) — assert no `pageerror`.

### 7. Legal Screens

#### 7.1 Terms and conditions opens
**Setup:** 503 catch-all.
**Steps:** reach Login; click "Terms and conditions".
**Expected Results:** Terms screen content visible (heading/back affordance); differs from Login (no phone textbox / "Login" submit).

#### 7.2 Privacy policy opens
**Setup:** 503 catch-all.
**Steps:** reach Login; click "Privacy policy".
**Expected Results:** Privacy screen content visible.

### 8. Post-login Home / Bottom Nav (approved)

> **Setup (all §8):** mock `auth/login-with-email` → 200 approved; `GET **/api/v1/parent/home` → 200 `{data:{}}`; mock any other `**/api/v1/**` → 503 catch-all so unimplemented sections fail soft. Reach Main via email login (4.5 path) — fastest deterministic route.

#### 8.1 MainScreen exposes the four nav destinations
**Steps:** email-login approved.
**Expected Results:** semantics expose Home, Diary, Events, Settings destinations (text/labels). Capture `page.ariaSnapshot({ mode:'ai' })` of the shell.

#### 8.2 Navigate to Diary tab
**Steps:** email-login approved; tap the Diary destination.
**Expected Results:** Diary surface rendered (no `pageerror`); a Diary-specific affordance/text visible; nav still present.

#### 8.3 Navigate to Settings tab
**Steps:** email-login approved; tap Settings.
**Expected Results:** Settings list visible (e.g. profile / my children / about entries); nav present.

#### 8.4 Navigate to Events tab
**Steps:** email-login approved; tap Events.
**Expected Results:** Events surface rendered without crash; nav present.

#### 8.5 `parent/home` 500 → home error state, no crash
**Setup:** `auth/login-with-email` 200 approved; `parent/home` → 500.
**Steps:** email-login approved.
**Expected Results:** app reaches the shell or an error/retry affordance; no `pageerror`; bottom nav still navigable.

### 9. Resilience / Abort

#### 9.1 Auth emulator unreachable → clean abort
**Setup:** in a `beforeEach`/early step, probe the Auth emulator REST root; if not reachable, `test.abort('Auth emulator down')` instead of a misleading mid-flow failure. (Documents the 1.60 `test.abort` path; normally a no-op since the emulator is up in attach mode.)
**Steps:** probe; then run 5.1 happy path.
**Expected Results:** either aborts cleanly (emulator down) or OTP screen reached.

#### 9.2 Mobile viewport login reflow
**Setup:** 503 catch-all; `test.use({ viewport: { width: 390, height: 844 } })`.
**Steps:** reach Login (English→Skip).
**Expected Results:** phone textbox and "Login" button still visible and hit-testable at mobile width.

---

## 10. Professores flavor (mirror)

> Flavor: **professores** (`lib/main_professores.dart`, port 8766, project `professores-generated`, dir `tests/generated/professores/`). Helper: `src/helpers/professoresFlow.ts`. Differences vs parents (captured live): Login title **"Login Professors"** + a "Professors" badge; **no onboarding carousel** (chooser → Login directly after language); auth role `teacher`; home endpoint `teacher/home`. `/api/v1/config` is flavor-agnostic (reuse fixture). OTP blocked identically (fixme).

Mirror the green parents cases for the durable subset:
- 10.1 boot: cold-start chooser (English+العربية, only /config), language-chooser aria-snapshot, select-English→Login (no onboard), select-العربية RTL.
- 10.2 login: login aria-snapshot, empty-phone-keeps-login-disabled, keep-me-logged-in, email-form-toggle, email-empty/invalid/short-password validation, mobile-viewport reflow.
- 10.3 auth: email-login approved→shell, unapproved→under-review, backend-500→error (teacher role, `teacher/home`).
- 10.4 otp: request-otp `test.fixme` (same billing blocker).
- 10.5 legal: terms, privacy. 10.6 register: navigate-to-register. 10.7 home: approved login → interactive shell.
