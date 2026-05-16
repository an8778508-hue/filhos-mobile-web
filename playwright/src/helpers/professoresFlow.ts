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
