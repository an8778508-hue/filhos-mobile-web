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
