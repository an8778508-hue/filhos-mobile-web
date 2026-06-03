import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import type { Page } from '@playwright/test';

import type { AppPage } from '../fixtures/appPage.js';

/**
 * Professores-flavor flow helpers — mirror of `parentsFlow.ts`. Differences
 * captured live in cycle-3 exploration:
 *  - Login title is "Login Professors" (login_title + professors), and a
 *    "Professors" badge (ProfessorsContainer) renders above it.
 *  - `ChooseLanguageScreen` routes professores STRAIGHT to LoginScreen after
 *    language selection — there is no onboarding carousel (parents-only).
 *  - Auth role is `teacher`; the home endpoint is `teacher/home`.
 *
 * The `/api/v1/config` response is flavor-agnostic (init sends only a `lang`
 * header, no role), so the parents config fixture is reused. Same blockers
 * apply: mock `/config` (see memory pw-config-mock-required) and OTP is
 * un-testable (pw-otp-not-emulated) — email login is the automatable entry.
 */

const here = dirname(fileURLToPath(import.meta.url));
const CONFIG_JSON = readFileSync(resolve(here, '../fixtures/config-parents.json'), 'utf8');

export const LOGIN_TITLE = 'Login Professors';

/** UserModel-shaped `data` for `auth/login*`, teacher role. */
export function teacherPayload(opts: { approved: boolean } = { approved: true }) {
  return {
    data: {
      id: '1',
      name: 'Prof Test',
      phone: '1099887766',
      email: 'prof@test.com',
      access_token: 'tok-test',
      is_approval: opts.approved,
      country_code: 'EG',
      role: 'teacher',
    },
  };
}

export async function guardRest(page: Page): Promise<void> {
  await page.route('**/api/v1/**', (route) =>
    route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
  );
}

export async function mockConfig(page: Page): Promise<void> {
  await page.route('**/api/v1/config', (route) =>
    route.fulfill({ status: 200, contentType: 'application/json', body: CONFIG_JSON }),
  );
}

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

export async function bootProfessores(app: AppPage, page: Page): Promise<void> {
  await guardRest(page);
  await mockConfig(page);
  await app.coldStart();
}

/** chooser (English) → Login (no onboard for professores). */
export async function reachLogin(app: AppPage, page: Page): Promise<void> {
  await mockConfig(page);
  await app.coldStart();
  await page.getByRole('button', { name: 'English' }).click();
  await app
    .semanticText(LOGIN_TITLE)
    .first()
    .waitFor({ state: 'visible', timeout: 20_000 });
}

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

export async function openEmailForm(page: Page): Promise<void> {
  const buttons = page.getByRole('button');
  const count = await buttons.count();
  await buttons.nth(count - 2).click();
  await page
    .getByRole('textbox', { name: 'Email' })
    .waitFor({ state: 'visible', timeout: 10_000 });
}

export async function submitEmailLogin(
  page: Page,
  creds: { email: string; password: string },
): Promise<void> {
  await typeInto(page, 'Email', creds.email);
  await typeInto(page, 'Password', creds.password);
  await page.getByRole('button', { name: 'Login' }).click();
}

// ─── Server-driven auth (SDA) helpers — mirror of parentsFlow.ts SDA block ──
//
// Visual UI for the SDA screens is flavor-agnostic — the new LoginScreen,
// SelfRegisterScreen, EmailOtpScreen, etc. don't fork on `context.isProfessors`.
// Only the boot path differs: professores has NO onboard carousel
// (chooser → LoginScreen directly), and the `role` field on every auth
// request body is `'teacher'` instead of `'parent'`. The mock endpoints don't
// care about the role value, so the same `sdaActionEnvelope` works for both.
//
// References (same as the parents file):
//  • lib/features/server_driven_auth/presentation/login_screen.dart
//  • lib/features/server_driven_auth/presentation/self_register_screen.dart
//  • lib/features/server_driven_auth/presentation/email_otp_screen.dart
//  • Localization keys in assets/langs/en.json (sda_*)

export const SDA_CREATE_ACCOUNT_LINK = 'Create new account';
export const SDA_REGISTER_TITLE = 'Create account';
export const SDA_EMAIL_OTP_TITLE = 'Verify your email';
export const SDA_PENDING_APPROVAL_TITLE = /under\s+review/i;
export const SDA_VALID_OTP = '123456';
export const SDA_TEST_PHONE_VERIFY_OTP = '11111110003';

/** Variant of `mockConfig` that injects `server_driven_auth_enabled: true`
 *  into the canned config payload. Harness builds with
 *  `--dart-define=SDA_DEV_TEST=false`, so LoginScreen routing depends solely
 *  on `Config.serverDrivenAuthEnabled` — i.e. the value in the `config/*`
 *  JSON. Flipping that one field activates SDA per-spec. */
export async function mockConfigWithSdaOn(page: Page): Promise<void> {
  const base = JSON.parse(CONFIG_JSON) as Record<string, unknown>;
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

/** Walk to the SDA LoginScreen. Differs from `reachLogin` in two ways:
 *  (a) the config mock flips `server_driven_auth_enabled = true`, and
 *  (b) the assertion waits for the SDA-specific "Create new account" link
 *  instead of the legacy "Login Professors" heading. No onboard step —
 *  professores chooser → LoginScreen directly. */
export async function reachSdaLoginViaConfigFlag(
  app: AppPage,
  page: Page,
): Promise<void> {
  await mockConfigWithSdaOn(page);
  await app.coldStart();
  await page.getByRole('button', { name: 'English' }).click();
  await page
    .getByRole('button', { name: SDA_CREATE_ACCOUNT_LINK })
    .first()
    .waitFor({ state: 'visible', timeout: 20_000 });
}

/** Open SelfRegisterScreen via the bottom "Create new account" link. */
export async function openSdaRegister(page: Page): Promise<void> {
  await page.getByRole('button', { name: SDA_CREATE_ACCOUNT_LINK }).first().click();
  await page
    .getByText(SDA_REGISTER_TITLE, { exact: false })
    .first()
    .waitFor({ state: 'visible', timeout: 10_000 });
}

/** Fill all five SelfRegisterScreen fields. */
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

export async function submitSdaRegister(page: Page): Promise<void> {
  await page.getByRole('button', { name: SDA_REGISTER_TITLE }).click();
}

/** Same OTP-typer as the parents flavor — see that file for the rationale
 *  on `waitFor` + focus + backspace clear. Identical behavior here since
 *  the SDA OTP screens don't fork on flavor. */
export async function typeSdaOtp(page: Page, code: string): Promise<void> {
  const pinBox = page.getByRole('textbox').first();
  await pinBox.waitFor({ state: 'visible', timeout: 10_000 });
  await pinBox.focus();
  for (let i = 0; i < 6; i++) {
    await page.keyboard.press('Backspace');
  }
  await page.keyboard.type(code, { delay: 30 });
}

/** Enter the SDA LoginScreen phone field. */
export async function enterSdaPhone(page: Page, phone: string): Promise<void> {
  await typeInto(page, 'Phone', phone);
}

/** Tap the SDA LoginScreen primary CTA (the "Next" button on the initial
 *  state). */
export async function tapSdaNext(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Next' }).click();
}

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

export function sdaErrorEnvelope(code: string, message = code) {
  return { error: { code, message } };
}

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
