// spec: specs/parents-core-flows.plan.md §4.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('submitting an empty email form shows the required-field error', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);
    await page.getByRole('button', { name: 'Login' }).click();

    // Flutter folds the InputDecorator errorText into the field's accessible
    // name, so the required error surfaces as the Email textbox name.
    await expect(
      page.getByRole('textbox', { name: /This field can't be empty/ }).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});
