// spec: specs/parents-core-flows.plan.md §4.6
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  openEmailForm,
  submitEmailLogin,
  guardRest,
  mockJson,
  userPayload,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Login — Email Form', () => {
  test('valid email login for an unapproved user lands on Account Under Review', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockJson(page, '**/api/v1/auth/login-with-email', userPayload({ approved: false }));

    await reachLogin(app, page);
    await openEmailForm(page);
    await submitEmailLogin(page, { email: 'ana@test.com', password: 'secret1' });

    // is_approval:false routes to YourAccountUnderReviewScreen.
    await expect(app.semanticText('Your account is under review').first()).toBeVisible({
      timeout: 20_000,
    });
    await expect(app.semanticText('Login with another account').first()).toBeVisible();
  });
});
