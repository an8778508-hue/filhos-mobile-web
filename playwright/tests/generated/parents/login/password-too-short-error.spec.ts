// spec: specs/parents-core-flows.plan.md §4.4
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, openEmailForm, typeInto } from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('password shorter than 6 chars shows the length error', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);
    await openEmailForm(page);

    await typeInto(page, 'Email', 'ana@test.com');
    await typeInto(page, 'Password', '123');
    await page.getByRole('button', { name: 'Login' }).click();

    // The password field is wrapped in a group whose accessible name carries
    // the length error: "This field can't be empty or less than 6 Character".
    await expect(
      page.getByRole('group', { name: /less than\s*6\s*Character/i }).first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});
