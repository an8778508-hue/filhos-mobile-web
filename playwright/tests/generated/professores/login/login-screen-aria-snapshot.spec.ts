// spec: specs/parents-core-flows.plan.md §10.2
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login', () => {
  test('Login screen exposes the expected interactive surface', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    const snap = await page.ariaSnapshot({ mode: 'ai' });
    expect(snap).toMatch(/Login Professors/);
    expect(snap).toMatch(/Professors/);
    expect(snap).toMatch(/button "Create account"/);
    expect(snap).toMatch(/button "Terms and conditions"/);

    await expect(page.getByRole('button', { name: 'Create account' })).toMatchAriaSnapshot(
      '- button "Create account"',
    );
  });
});
