// spec: specs/parents-core-flows.plan.md §10.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Boot & Language Chooser', () => {
  test('language chooser exposes both language buttons in the semantics tree', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await expect(page.getByRole('button', { name: 'English' })).toBeVisible({ timeout: 20_000 });

    const snap = await page.ariaSnapshot({ mode: 'ai' });
    expect(snap).toMatch(/button "English"/);
    expect(snap).toMatch(/button "العربية"/);

    await expect(page.getByRole('button', { name: 'English' })).toMatchAriaSnapshot(
      '- button "English"',
    );
  });
});
