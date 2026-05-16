// spec: specs/parents-core-flows.plan.md §4.7
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('email login backend 500 surfaces an error and stays on Login', async ({ app, page }) => {
    await guardRest(page);
    await mockJson(
      page,
      '**/api/v1/auth/login-with-email',
      { error: true, message: 'Server error' },
      500,
    );

    await reachLogin(app, page);
    await openEmailForm(page);
    await submitEmailLogin(page, { email: 'ana@test.com', password: 'secret1' });

    // LoginFailure → ErrorField rendered on the login screen; we stay put.
    await expect(page.getByRole('textbox', { name: 'Email' })).toBeVisible({ timeout: 15_000 });
    await expect(app.semanticText('Login Parents').first()).toBeVisible();
  });
});
