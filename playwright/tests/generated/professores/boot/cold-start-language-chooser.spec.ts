// spec: specs/parents-core-flows.plan.md §10.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Boot & Language Chooser', () => {
  test('cold start lands on the language chooser; only /config is called', async ({
    app,
    page,
  }) => {
    const apiHits: string[] = [];
    page.on('request', (r) => {
      const u = r.url();
      if (u.includes('/api/v1/')) apiHits.push(u);
    });
    await guardRest(page);
    await mockConfig(page);

    await app.coldStart();

    await expect(page.getByRole('button', { name: 'English' })).toBeVisible({ timeout: 20_000 });
    await expect(page.getByRole('button', { name: 'العربية' })).toBeVisible();

    const nonConfig = apiHits.filter((u) => !/\/api\/v1\/config(\?|$)/.test(u));
    expect(nonConfig, `unexpected non-config API calls: ${nonConfig.join(', ')}`).toHaveLength(0);
  });
});
