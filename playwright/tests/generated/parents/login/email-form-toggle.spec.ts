// spec: specs/parents-core-flows.plan.md §4.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('toggling the social row switches to the email/password form', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);

    await expect(page.getByRole('textbox', { name: 'Email' })).toBeVisible();
    await expect(page.getByRole('textbox', { name: 'Password' })).toBeVisible();
  });
});
