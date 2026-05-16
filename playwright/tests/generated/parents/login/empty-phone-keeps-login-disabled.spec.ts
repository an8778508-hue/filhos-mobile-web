// spec: specs/parents-core-flows.plan.md §3.1 (revised from live finding:
// the Login button is [disabled] until a valid phone is entered).
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, enterPhone } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Phone Form Validation', () => {
  test('Login button is disabled with no phone and enables once a valid number is typed', async ({
    app,
    page,
  }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    const loginBtn = page.getByRole('button', { name: 'Login' });
    await expect(loginBtn).toBeDisabled();

    // Egypt (+20) is the picker default; a 10-digit local number is valid.
    await enterPhone(page, '1099887766');
    await expect(loginBtn).toBeEnabled({ timeout: 15_000 });
  });
});
