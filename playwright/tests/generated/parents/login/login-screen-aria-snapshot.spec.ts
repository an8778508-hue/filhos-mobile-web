// spec: specs/parents-core-flows.plan.md §2.3
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin } from '../../../../src/helpers/parentsFlow.js';

test.describe('OnBoard to Login', () => {
  test('Login screen exposes the expected interactive surface', async ({ app, page }) => {
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    await reachLogin(app, page);

    // AI-mode snapshot dump for addressable diagnosis.
    const snap = await page.ariaSnapshot({ mode: 'ai' });
    expect(snap).toMatch(/Login Parents/);
    expect(snap).toMatch(/button "Create account"/);
    expect(snap).toMatch(/button "Terms and conditions"/);
    expect(snap).toMatch(/button "Privacy policy"/);

    // Structural assertion via toMatchAriaSnapshot on stable single nodes.
    await expect(page.getByRole('button', { name: 'Create account' })).toMatchAriaSnapshot(
      '- button "Create account"',
    );
  });
});
