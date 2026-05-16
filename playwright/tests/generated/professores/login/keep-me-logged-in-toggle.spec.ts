// spec: specs/parents-core-flows.plan.md §10.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login', () => {
  test('Keep me logged in checkbox toggles', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    const checkbox = page.getByRole('checkbox');
    await expect(checkbox).not.toBeChecked();
    await page.getByRole('group', { name: 'Keep me logged in' }).click();
    await expect(checkbox).toBeChecked();
  });
});
