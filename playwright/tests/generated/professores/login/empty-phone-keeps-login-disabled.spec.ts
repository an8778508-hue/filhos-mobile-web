// spec: specs/parents-core-flows.plan.md §10.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, enterPhone } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login', () => {
  test('Login button is disabled until a valid number is typed', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    const loginBtn = page.getByRole('button', { name: 'Login' });
    await expect(loginBtn).toBeDisabled();

    await enterPhone(page, '1099887766');
    await expect(loginBtn).toBeEnabled({ timeout: 15_000 });
  });
});
