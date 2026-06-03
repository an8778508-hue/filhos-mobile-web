import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import type { Page } from '@playwright/test';

import type { AppPage } from '../fixtures/appPage.js';

/**
 * Shared parents-flavor flow helpers for generated specs.
 *
 * Why this exists: every parents spec must (a) mock the Filhos REST API
 * (`ApiConst.baseUrl` is a hard-coded prod `const`), and (b) walk the
 * boot → language → onboard → login path (no URL routing — imperative
 * `Navigator.push`).
 *
 * HEAL CYCLE 1 — load-bearing discovery: the app fetches `GET /api/v1/config`
 * at startup; the response drives `Config` (languages list, onboarding
 * slides, styling, social providers). If that request is starved (e.g. a
 * blanket 503), the app falls back to a default `Config` whose language
 * entries have null fields, and the language-chooser button's `onPressed`
 * throws a Dart `Error` *before* it navigates — every downstream spec then
 * times out on the chooser. So **every spec must mock `/api/v1/config`** with
 * a realistic payload (captured from prod into
 * `src/fixtures/config-parents.json`). With it, the chooser shows the real
 * languages (English, العربية) and onboarding slides, exactly like a device.
 *
 * Auth note: the release web build never wires the Firebase Auth emulator,
 * so phone-OTP fails `billing-not-enabled`. Email login
 * (`auth/login-with-email`, pure REST) is the automatable authenticated
 * entry. See memory `pw-otp-not-emulated`.
 */

const here = dirname(fileURLToPath(import.meta.url));
const CONFIG_PARENTS = readFileSync(
  resolve(here, '../fixtures/config-parents.json'),
  'utf8',
);

/** The parents Login screen title (English UI after selecting English). */
export const LOGIN_TITLE = 'Login Parents';

/** UserModel-shaped `data` payload for `auth/login*`. `is_approval:true`
 *  routes to MainScreen; `false` routes to your_account_under_review. */
export function userPayload(opts: { approved: boolean } = { approved: true }) {
  return {
    data: {
      id: '1',
      name: 'Ana Test',
      phone: '1099887766',
      email: 'ana@test.com',
      access_token: 'tok-test',
      is_approval: opts.approved,
      country_code: 'EG',
      role: 'parent',
    },
  };
}

/**
 * Register the defensive REST catch-all FIRST (Playwright checks routes in
 * reverse registration order, so later `mockConfig` / `mockJson` calls win).
 */
export async function guardRest(page: Page): Promise<void> {
  await page.route('**/api/v1/**', (route) =>
    route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
  );
}

/**
 * Mandatory for every parents spec — serve the real config so `Config` is
 * populated and the language chooser / onboard / styling behave like a
 * device. Register AFTER `guardRest`.
 */
export async function mockConfig(page: Page): Promise<void> {
  await page.route('**/api/v1/config', (route) =>
    route.fulfill({ status: 200, contentType: 'application/json', body: CONFIG_PARENTS }),
  );
}

/** Mock one REST endpoint. Call AFTER `guardRest`/`mockConfig`. */
export async function mockJson(
  page: Page,
  urlGlob: string,
  body: unknown,
  status = 200,
): Promise<void> {
  await page.route(urlGlob, (route) =>
    route.fulfill({
      status,
      contentType: 'application/json',
      body: typeof body === 'string' ? body : JSON.stringify(body),
    }),
  );
}

/** guardRest + mockConfig, then cold-start. The standard parents boot. */
export async function bootParents(app: AppPage, page: Page): Promise<void> {
  await guardRest(page);
  await mockConfig(page);
  await app.coldStart();
}

/**
 * Boot and walk to the Login screen: chooser (pick **English**) → onboard
 * (Skip) → Login. Assumes the caller has NOT already mocked config; if it
 * has, the extra registration is harmless (idempotent handler).
 */
export async function reachLogin(app: AppPage, page: Page): Promise<void> {
  await mockConfig(page);
  await app.coldStart();
  await page.getByRole('button', { name: 'English' }).click();
  // Real config has 3 onboarding slides → OnBoardScreen with a Skip button.
  await page
    .getByRole('button', { name: 'Skip' })
    .click({ timeout: 15_000 })
    .catch(() => undefined);
  await app
    .semanticText(LOGIN_TITLE)
    .first()
    .waitFor({ state: 'visible', timeout: 20_000 });
}

/**
 * From the Login screen, switch to the email/password form. The social row's
 * toggle is an unlabeled image button rendered last in that row
 * (`social_login_widget.dart`), i.e. immediately before "Create account".
 * It is the second-to-last button on screen.
 */
export async function openEmailForm(page: Page): Promise<void> {
  const buttons = page.getByRole('button');
  const count = await buttons.count();
  await buttons.nth(count - 2).click();
  await page
    .getByRole('textbox', { name: 'Email' })
    .waitFor({ state: 'visible', timeout: 10_000 });
}

/**
 * Type into a Flutter Web text field. `.fill()` does NOT commit to a Flutter
 * `EditableText` (Flutter mounts a transient `<input>` only while focused and
 * reads it via its own pipeline). The harness README's prescribed pattern is
 * click-to-focus then `page.keyboard.type`. We clear any prior value first.
 */
export async function typeInto(
  page: Page,
  label: string | RegExp,
  text: string,
): Promise<void> {
  const field = page.getByRole('textbox', { name: label }).first();
  await field.click();
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.press('Delete');
  await page.keyboard.type(text, { delay: 20 });
}

/**
 * Enter a phone number into the PhoneField. Tapping the field can pop the
 * country-picker dialog (its search box is a textbox named
 * "Search for country …"); if it does, Escape returns focus to the number
 * input (verified behaviour), then we type via the keyboard.
 */
export async function enterPhone(page: Page, localNumber: string): Promise<void> {
  const phone = page.getByRole('textbox').first();
  await phone.click();
  const search = page.getByRole('textbox', { name: /search for country/i });
  if (await search.isVisible().catch(() => false)) {
    await page.keyboard.press('Escape');
    await search.waitFor({ state: 'hidden', timeout: 5_000 }).catch(() => undefined);
  }
  await page.keyboard.type(localNumber, { delay: 20 });
}

/** Fill + submit the email login form. Assumes `openEmailForm` already ran. */
export async function submitEmailLogin(
  page: Page,
  creds: { email: string; password: string },
): Promise<void> {
  await typeInto(page, 'Email', creds.email);
  await typeInto(page, 'Password', creds.password);
  await page.getByRole('button', { name: 'Login' }).click();
}

// ─── Server-driven auth (SDA) helpers ─────────────────────────────────────
//
// Active when the Flutter build is compiled with
// `lib/core/utils/debug_flags.dart`'s `kSdaDevTest = true` — that const flips
// `Config.serverDrivenAuthEnabled` to `true` regardless of `/api/v1/config`,
// AND wires `SdaMockImpl` in place of the real HTTP impl. So auth calls
// (`auth/check-identifier`, `auth/self-register`, `auth/verify-email-otp`,
// `auth/login`, etc.) do NOT go through the network — no `page.route()`
// needed for `/auth/*`. The `/api/v1/config` boot fetch still happens, so
// `mockConfig` is still mandatory.
//
// References:
//  • lib/features/server_driven_auth/presentation/login_screen.dart
//  • lib/features/server_driven_auth/presentation/self_register_screen.dart
//  • lib/features/server_driven_auth/presentation/email_otp_screen.dart
//  • lib/features/server_driven_auth/data_sources/sda_mock_impl.dart
//  • Localization keys in assets/langs/en.json (sda_*)

/** Unique-to-SDA marker on the new LoginScreen (legacy LoginScreen does not
 *  render this string). Used as the "we have reached SDA login" gate. */
export const SDA_CREATE_ACCOUNT_LINK = 'Create new account';

/** Title on SelfRegisterScreen (en: sda_register_title). */
export const SDA_REGISTER_TITLE = 'Create account';

/** Title on EmailOtpScreen (en: sda_email_otp_title). */
export const SDA_EMAIL_OTP_TITLE = 'Verify your email';

/** Title on PendingApprovalScreen — reuses the legacy
 *  YourAccountUnderReviewScreen wording (en: your_account_is_under_review). */
export const SDA_PENDING_APPROVAL_TITLE = /under\s+review/i;

/** The single OTP code the mock accepts (see SdaMockImpl). */
export const SDA_VALID_OTP = '123456';

/** Test phone that maps to `VERIFY_EMAIL_OTP` in SdaMockImpl — directly opens
 *  EmailOtpScreen from LoginScreen without going through the register form. */
export const SDA_TEST_PHONE_VERIFY_OTP = '11111110003';

/**
 * Boot → chooser (pick English) → skip onboard → wait for the SDA LoginScreen.
 *
 * Identical to `reachLogin` until the last assertion: the SDA LoginScreen's
 * AppBar title is "Login" (no flavor suffix), so we gate on the unique
 * `Create new account` link instead. Caller has NOT mocked config; the
 * idempotent `mockConfig` call inside is safe to re-register.
 */
export async function reachSdaLogin(app: AppPage, page: Page): Promise<void> {
  await mockConfig(page);
  await app.coldStart();
  await page.getByRole('button', { name: 'English' }).click();
  await page
    .getByRole('button', { name: 'Skip' })
    .click({ timeout: 15_000 })
    .catch(() => undefined);
  await page
    .getByRole('button', { name: SDA_CREATE_ACCOUNT_LINK })
    .first()
    .waitFor({ state: 'visible', timeout: 20_000 });
}

/** Open SelfRegisterScreen by tapping the bottom "Create new account" link.
 *  There are two such controls on LoginScreen (the inline `NOT_FOUND` prompt
 *  button and the always-visible bottom link); the bottom one is always
 *  present, so `.first()` is deterministic. */
export async function openSdaRegister(page: Page): Promise<void> {
  await page.getByRole('button', { name: SDA_CREATE_ACCOUNT_LINK }).first().click();
  await page
    .getByText(SDA_REGISTER_TITLE, { exact: false })
    .first()
    .waitFor({ state: 'visible', timeout: 10_000 });
}

/** Fill all five SelfRegisterScreen fields. Field labels come from the
 *  English translations of the `sda_*_label` keys. */
export async function fillSdaRegisterForm(
  page: Page,
  form: { name: string; phone: string; email: string; password: string },
): Promise<void> {
  await typeInto(page, 'Full name', form.name);
  await typeInto(page, 'Phone', form.phone);
  await typeInto(page, 'Email', form.email);
  await typeInto(page, 'Password', form.password);
  await typeInto(page, 'Confirm password', form.password);
}

/** Tap the bottom CTA on SelfRegisterScreen — same English string as the
 *  AppBar title ("Create account"). `nth(-1)` would also work; the button
 *  role narrows correctly without it. */
export async function submitSdaRegister(page: Page): Promise<void> {
  await page.getByRole('button', { name: SDA_REGISTER_TITLE }).click();
}

/** Type the 6-digit OTP into the SDA OTP screens (registration + reset).
 *
 *  `pin_code_fields` keeps the real input as a hidden `TextField` underneath
 *  6 tappable Containers that Flutter Web exposes as `role=button`. The
 *  cells cover the textbox geometrically, so `.click()` on the textbox is
 *  intercepted (we saw this on the first iteration). `.focus()` uses focus
 *  events — not pointer events — and bypasses the button overlay.
 *
 *  Re-focusing is also necessary on RETRY: after an invalid-code SnackBar
 *  surfaces, the pin field loses keyboard focus, so subsequent keystrokes
 *  go nowhere. Focusing the underlying textbox restores the input target.
 *
 *  `waitFor({ visible })` defends against the autoFocus race: on slow
 *  builds the hidden `<input>` mounts a few frames after EmailOtpScreen
 *  paints, and typing before it's there silently drops keystrokes — the
 *  spec then hangs on the SnackBar assertion (root cause of the only spec
 *  flake observed in CI). Waiting up to 10 s eliminates that window.
 *
 *  Backspace x6 first to clear any stale digits (the field enforces a
 *  6-char limit at the controller level — typing on a full field is dropped
 *  and `onCompleted` never re-fires). 6 backspaces on an empty field are a
 *  no-op, so the same helper is correct on both first call and retry. */
export async function typeSdaOtp(page: Page, code: string): Promise<void> {
  const pinBox = page.getByRole('textbox').first();
  await pinBox.waitFor({ state: 'visible', timeout: 10_000 });
  await pinBox.focus();
  for (let i = 0; i < 6; i++) {
    await page.keyboard.press('Backspace');
  }
  await page.keyboard.type(code, { delay: 30 });
}

/** Enter the SDA LoginScreen phone field. The new screen has only one
 *  textbox visible until `REQUIRE_PASSWORD` reveals the inline password
 *  field, so the first textbox is unambiguous. */
export async function enterSdaPhone(page: Page, phone: string): Promise<void> {
  await typeInto(page, 'Phone', phone);
}

/** Tap the SDA LoginScreen primary CTA. The button label is the
 *  state-dependent "Next" / "Log in" string from the cubit's current state;
 *  on the initial state it is "Next". */
export async function tapSdaNext(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Next' }).click();
}

/**
 * Variant of `mockConfig` that injects `server_driven_auth_enabled: true`
 * into the canned config payload. The harness builds the Flutter app with
 * `--dart-define=SDA_DEV_TEST=false` (so `DebugFlags.kSdaDevTest` is false at
 * runtime), which means LoginScreen routing depends solely on
 * `Config.serverDrivenAuthEnabled` — i.e. the value in the `config/*` JSON.
 * Flipping that one field activates the new SDA flow per-spec without
 * affecting any legacy spec.
 *
 * Register AFTER `guardRest` and BEFORE `app.coldStart()`.
 */
export async function mockConfigWithSdaOn(page: Page): Promise<void> {
  const base = JSON.parse(CONFIG_PARENTS) as Record<string, unknown>;
  // ConfigCubit reads `data.config` from the response (see
  // lib/core/config/cubit/cubit.dart init()). `Config` then reads
  // `config['server_driven_auth_enabled']` via the getter on `Config`.
  const data = (base.data ?? {}) as Record<string, unknown>;
  const config = { ...((data.config ?? {}) as Record<string, unknown>) };
  config.server_driven_auth_enabled = true;
  const merged = { ...base, data: { ...data, config } };
  await page.route('**/api/v1/config', (route) =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(merged),
    }),
  );
}

/**
 * Walk to the SDA LoginScreen against the real `ServerDrivenAuthImpl` (via
 * page.route mocks). Differs from `reachSdaLogin` only in which config
 * mock it uses — this one flips `server_driven_auth_enabled = true`, so the
 * harness build (with `SDA_DEV_TEST=false`) still ends up on the SDA login.
 */
export async function reachSdaLoginViaConfigFlag(
  app: AppPage,
  page: Page,
): Promise<void> {
  await mockConfigWithSdaOn(page);
  await app.coldStart();
  await page.getByRole('button', { name: 'English' }).click();
  await page
    .getByRole('button', { name: 'Skip' })
    .click({ timeout: 15_000 })
    .catch(() => undefined);
  await page
    .getByRole('button', { name: SDA_CREATE_ACCOUNT_LINK })
    .first()
    .waitFor({ state: 'visible', timeout: 20_000 });
}

/** Uniform success envelope per
 *  `specs/server_driven_auth/contracts/rest-endpoints.md` §0. */
export function sdaActionEnvelope(
  action: string,
  opts: { tempToken?: string; expiresIn?: number } = {},
): { action: string; temp_token?: string; expires_in?: number } {
  return {
    action,
    ...(opts.tempToken !== undefined ? { temp_token: opts.tempToken } : {}),
    ...(opts.expiresIn !== undefined ? { expires_in: opts.expiresIn } : {}),
  };
}

/** Uniform error envelope per
 *  `specs/server_driven_auth/contracts/rest-endpoints.md` §0. */
export function sdaErrorEnvelope(code: string, message = code) {
  return { error: { code, message } };
}

/** Fake terminal-login response (mirrors the existing `/auth/login` shape so
 *  `UserBloc.loggedIn` parses unchanged). */
export function sdaLoginPayload(
  opts: { approved?: boolean; role?: string } = {},
) {
  return {
    data: {
      id: 1,
      name: 'Test User',
      phone: '11111110002',
      email: 'test@example.com',
      access_token: 'mock-sda-jwt',
      is_approval: opts.approved ?? true,
      role: opts.role ?? 'parent',
    },
  };
}

/** Register a JSON-fulfilling route for one of the 8 SDA `auth/*` endpoints.
 *  Thin sugar so each spec reads as a sequence of "endpoint → response". */
export async function mockSdaEndpoint(
  page: Page,
  endpoint:
    | 'check-identifier'
    | 'set-initial-password'
    | 'self-register'
    | 'verify-email-otp'
    | 'login'
    | 'forgot-password'
    | 'verify-reset-otp'
    | 'reset-password',
  body: unknown,
  status = 200,
): Promise<void> {
  await mockJson(page, `**/api/v1/auth/${endpoint}`, body, status);
}
