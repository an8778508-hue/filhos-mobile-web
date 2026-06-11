// spec: specs/parents-core-flows.plan.md §10.3
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
  LOGIN_TITLE,
} from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login — Email Form', () => {
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
    await submitEmailLogin(page, { email: 'prof@test.com', password: 'secret1' });

    await expect(page.getByRole('textbox', { name: 'Username' })).toBeVisible({ timeout: 15_000 });
    await expect(app.semanticText(LOGIN_TITLE).first()).toBeVisible();
  });
});
