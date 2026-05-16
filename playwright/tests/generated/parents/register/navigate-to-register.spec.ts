// spec: specs/parents-core-flows.plan.md §6.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin } from '../../../../src/helpers/parentsFlow.js';

test.describe('Register', () => {
  test('Create account navigates to the Register screen', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await page.getByRole('button', { name: 'Create account' }).click();

    // Register screen has its own form; the login-only "Login Parents" title
    // is gone and editable fields are present.
    await expect(app.semanticText('Login Parents')).toBeHidden({ timeout: 15_000 });
    await expect(page.getByRole('textbox').first()).toBeVisible();
  });
});
