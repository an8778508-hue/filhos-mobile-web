// spec: specs/parents-core-flows.plan.md §8.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
  userPayload,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Post-login Home', () => {
  test('approved email login reaches an interactive app shell', async ({ app, page }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', userPayload({ approved: true }));
    await mockJson(page, '**/api/v1/parent/home', { data: {} });

    await reachLogin(app, page);
    await openEmailForm(page);
    await submitEmailLogin(page, { email: 'ana@test.com', password: 'secret1' });

    await expect(app.semanticText('Login Parents')).toBeHidden({ timeout: 20_000 });

    // The MainScreen bottom nav is config-driven (labels come from remote
    // config; the harness has no Firestore so it uses bundled fallback).
    // Attach the AI snapshot so coverage expansion can pin exact nav labels.
    const shell = await page.ariaSnapshot({ mode: 'ai' });
    await test.info().attach('post-login-shell.aria.txt', {
      body: shell,
      contentType: 'text/plain',
    });

    // The shell must be interactive (multiple tappable destinations) and
    // crash-free.
    expect(await page.getByRole('button').count()).toBeGreaterThan(1);
  });
});
