// spec: specs/parents-core-flows.plan.md §4.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Default Credential Form', () => {
  // The login screen now defaults to username + password. The email/phone
  // toggle only appears when the `phone_login_visible` remote flag is on
  // (OFF in the test config), so the default form is asserted directly.
  test('login defaults to the username + password form', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);

    await expect(page.getByRole('textbox', { name: 'Username' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'Password' })).toBeVisible();
  });
});
