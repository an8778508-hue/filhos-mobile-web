// spec: specs/parents-core-flows.plan.md §10.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig, LOGIN_TITLE } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Boot & Language Chooser', () => {
  test('selecting English goes straight to Login (no onboarding for professores)', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await page.getByRole('button', { name: 'English' }).click();

    // Professores skips the onboarding carousel entirely.
    await expect(app.semanticText(LOGIN_TITLE).first()).toBeVisible({ timeout: 20_000 });
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible();
  });
});
