// spec: specs/parents-core-flows.plan.md §10.5
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, LOGIN_TITLE } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Legal Screens', () => {
  test('Terms and conditions link opens the terms screen', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await page.getByRole('button', { name: 'Terms and conditions' }).click();

    await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 15_000 });
    await expect(page.getByRole('button', { name: 'Login' })).toBeHidden();
  });
});
