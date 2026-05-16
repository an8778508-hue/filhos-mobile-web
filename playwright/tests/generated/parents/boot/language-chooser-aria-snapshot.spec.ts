// spec: specs/parents-core-flows.plan.md §1.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/parentsFlow.js';

test.describe('Boot & Language Chooser', () => {
  test('language chooser exposes both language buttons in the semantics tree', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();
    await expect(page.getByRole('button', { name: 'English' })).toBeVisible({ timeout: 20_000 });

    // AI-mode aria snapshot (1.60) — addressable [ref=eN] dump of the route.
    const snap = await page.ariaSnapshot({ mode: 'ai' });
    expect(snap).toMatch(/button "English"/);
    expect(snap).toMatch(/button "العربية"/);

    // Single-node toMatchAriaSnapshot (1.60) — structural assertion on the
    // English button without a golden file.
    await expect(page.getByRole('button', { name: 'English' })).toMatchAriaSnapshot(
      '- button "English"',
    );
  });
});
