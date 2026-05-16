// spec: specs/parents-core-flows.plan.md §10.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login', () => {
  test('submitting an empty email form shows the required-field error', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);
    await page.getByRole('button', { name: 'Login' }).click();

    await expect(
      page.getByRole('textbox', { name: /This field can't be empty/ }).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});
