// spec: specs/parents-core-flows.plan.md §10.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/professoresFlow.js';

test.use({ locale: 'ar-SA' });

test.describe('Professores Boot & Language Chooser', () => {
  test('selecting العربية keeps the app interactive (RTL locale)', async ({ app, page }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await page.getByRole('button', { name: 'العربية' }).click();

    const interactive = page.getByRole('button').or(page.getByRole('textbox'));
    await expect(interactive.first()).toBeVisible({ timeout: 20_000 });
  });
});
