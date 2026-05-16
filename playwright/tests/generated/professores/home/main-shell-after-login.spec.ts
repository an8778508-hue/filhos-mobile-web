// spec: specs/parents-core-flows.plan.md §10.7
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
  teacherPayload,
  LOGIN_TITLE,
} from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Post-login Home', () => {
  test('approved teacher email login reaches an interactive app shell', async ({ app, page }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', teacherPayload({ approved: true }));
    await mockJson(page, '**/api/v1/teacher/home', { data: {} });

    await reachLogin(app, page);
    await openEmailForm(page);
    await submitEmailLogin(page, { email: 'prof@test.com', password: 'secret1' });

    await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 20_000 });

    const shell = await page.ariaSnapshot({ mode: 'ai' });
    await test.info().attach('professores-shell.aria.txt', {
      body: shell,
      contentType: 'text/plain',
    });
    expect(await page.getByRole('button').count()).toBeGreaterThan(1);
  });
});
