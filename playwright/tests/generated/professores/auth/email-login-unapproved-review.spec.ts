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
} from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores Login — Email Form', () => {
  test('valid email login for an unapproved teacher lands on Account Under Review', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', teacherPayload({ approved: false }));

    await reachLogin(app, page);
    await openEmailForm(page);
    await submitEmailLogin(page, { email: 'prof@test.com', password: 'secret1' });

    await expect(app.semanticText('Your account is under review').first()).toBeVisible({
      timeout: 20_000,
    });
    await expect(app.semanticText('Login with another account').first()).toBeVisible();
  });
});
