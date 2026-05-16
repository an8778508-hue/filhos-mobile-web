// spec: specs/parents-core-flows.plan.md §9.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, enterPhone } from '../../../../src/helpers/parentsFlow.js';

test.use({ viewport: { width: 390, height: 844 } });

test.describe('Resilience', () => {
  test('Login screen is usable at mobile viewport width', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    await expect(page.getByRole('textbox').first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();
    // Hit-testable: typing a valid number still enables submit at 390px.
    await enterPhone(page, '1099887766');
    await expect(page.getByRole('button', { name: 'Login' })).toBeEnabled({ timeout: 15_000 });
  });
});
