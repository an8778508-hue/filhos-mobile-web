// spec: specs/parents-core-flows.plan.md §10.3
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

test.describe('Professores Login — Email Form', () => {
  test('valid email login for an approved teacher leaves the login screen', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', teacherPayload({ approved: true }));
    await mockJson(page, '**/api/v1/teacher/home', { data: {} });

    await reachLogin(app, page);
    await openEmailForm(page);

    await test.step('email login → app shell', async () => {
      const harPath = test.info().outputPath('email-login.har');
      await using _har = await page.context().tracing.startHar(harPath, { content: 'embed' });
      await submitEmailLogin(page, { email: 'prof@test.com', password: 'secret1' });
      await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 20_000 });
    });

    await expect(page.getByRole('button').or(page.getByRole('textbox')).first()).toBeVisible();
    expect(await page.getByRole('button').count()).toBeGreaterThan(1);
  });
});
