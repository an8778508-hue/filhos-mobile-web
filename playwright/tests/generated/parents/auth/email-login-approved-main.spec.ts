// spec: specs/parents-core-flows.plan.md §4.5
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
  userPayload,
  LOGIN_TITLE,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('valid email login for an approved user leaves the login screen', async ({ app, page }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', userPayload({ approved: true }));
    await mockJson(page, '**/api/v1/parent/home', { data: {} });

    await reachLogin(app, page);
    await openEmailForm(page);

    // Record the authenticated transition as one trace block + a HAR artifact
    // (harTracing fixture is off by default, so starting one here is safe).
    await test.step('email login → app shell', async () => {
      const harPath = test.info().outputPath('email-login.har');
      await using _har = await page.context().tracing.startHar(harPath, { content: 'embed' });
      await submitEmailLogin(page, { email: 'ana@test.com', password: 'secret1' });
      // Leaving the login screen is the deterministic signal that
      // LoginWithEmailSuccess + isApproval routed to MainScreen.
      await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 20_000 });
    });

    // An interactive shell must be present. (The app emits benign minified
    // "Error" pageerrors during boot — see browser-findings annotation — so
    // we assert reachability, not a zero-pageerror invariant.)
    await expect(page.getByRole('button').or(page.getByRole('textbox')).first()).toBeVisible();
    expect(await page.getByRole('button').count()).toBeGreaterThan(1);
  });
});
