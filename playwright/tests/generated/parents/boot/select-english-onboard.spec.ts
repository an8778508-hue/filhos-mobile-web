// spec: specs/parents-core-flows.plan.md §1.3
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/parentsFlow.js';

test.describe('Boot & Language Chooser', () => {
  test('selecting English advances to the onboarding carousel', async ({ app, page }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await page.getByRole('button', { name: 'English' }).click();

    // Real config has 3 onboarding slides → OnBoardScreen (Skip + Next).
    await expect(page.getByRole('button', { name: 'Skip' })).toBeVisible({ timeout: 20_000 });
    await expect(page.getByRole('button', { name: 'Next' })).toBeVisible();
  });
});
