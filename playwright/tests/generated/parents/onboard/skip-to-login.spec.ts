// spec: specs/parents-core-flows.plan.md §2.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin } from '../../../../src/helpers/parentsFlow.js';

test.describe('OnBoard to Login', () => {
  test('Skip on onboarding reaches the parents Login screen', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    await expect(app.semanticText('Login Parents').first()).toBeVisible();
    await expect(page.getByRole('textbox').first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Terms and conditions' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Privacy policy' })).toBeVisible();
  });
});
