// spec: specs/parents-core-flows.plan.md §1.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { guardRest, mockConfig } from '../../../../src/helpers/parentsFlow.js';

test.describe('Boot & Language Chooser', () => {
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

    // Real config drives the language list: English + العربية.
    await expect(page.getByRole('button', { name: 'English' })).toBeVisible({ timeout: 20_000 });
    await expect(page.getByRole('button', { name: 'العربية' })).toBeVisible();

    // The only Filhos REST call before login is the config bootstrap.
    const nonConfig = apiHits.filter((u) => !/\/api\/v1\/config(\?|$)/.test(u));
    expect(nonConfig, `unexpected non-config API calls: ${nonConfig.join(', ')}`).toHaveLength(0);
  });
});
