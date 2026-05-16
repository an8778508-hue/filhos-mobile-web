// spec: specs/parents-core-flows.plan.md §7.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, LOGIN_TITLE } from '../../../../src/helpers/parentsFlow.js';

test.describe('Legal Screens', () => {
  test('Terms and conditions link opens the terms screen', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await page.getByRole('button', { name: 'Terms and conditions' }).click();

    // Navigated off the login form: the title and the Login submit are gone.
    await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Login' })).toBeHidden();
  });
});
