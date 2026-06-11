// spec: specs/parents-core-flows.plan.md §4.3
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm, typeInto } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  // The default login form is now username + password — the username field has
  // no email-format validation (that moved to the sign-up form and the
  // flag-gated email-OTP tab). This login-screen scenario no longer applies.
  test.fixme('invalid email format shows the email validation error', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);

    await typeInto(page, 'Email', 'not-an-email');
    await typeInto(page, 'Password', 'secret1');
    await page.getByRole('button', { name: 'Login' }).click();

    // errorText folds into the Email textbox accessible name.
    await expect(
      page.getByRole('textbox', { name: /not a valid email/i }).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});
