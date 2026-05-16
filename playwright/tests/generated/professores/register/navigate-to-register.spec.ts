// spec: specs/parents-core-flows.plan.md §10.6
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, LOGIN_TITLE } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Register', () => {
  test('Create account navigates to the Register screen', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await page.getByRole('button', { name: 'Create account' }).click();

    await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 15_000 });
    await expect(page.getByRole('textbox').first()).toBeVisible();
  });
});
