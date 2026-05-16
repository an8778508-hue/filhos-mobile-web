// spec: specs/parents-core-flows.plan.md §1.4
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/parentsFlow.js';

test.use({ locale: 'ar-SA' });

test.describe('Boot & Language Chooser', () => {
  test('selecting العربية keeps the app interactive (RTL locale)', async ({ app, page }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await page.getByRole('button', { name: 'العربية' }).click();

    // After language selection the parents flavor advances to onboard/login;
    // either way an interactive widget must surface (no dead-end).
    const interactive = page.getByRole('button').or(page.getByRole('textbox'));
    await expect(interactive.first()).toBeVisible({ timeout: 20_000 });
  });
});
