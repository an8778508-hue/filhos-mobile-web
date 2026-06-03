// spec: specs/server_driven_auth/spec.md §User Story 2 (Path A) — professores
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// Professores-flavor mirror of the parents happy-path spec. SDA UI is
// flavor-agnostic; the only differences are boot (no onboard for professores)
// and the `role: 'teacher'` field on the request body — `SdaMockImpl` /
// `page.route` don't differentiate, so the assertions are identical.
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  guardRest,
  reachSdaLoginViaConfigFlag,
  openSdaRegister,
  fillSdaRegisterForm,
  submitSdaRegister,
  typeSdaOtp,
  mockSdaEndpoint,
  sdaActionEnvelope,
  SDA_EMAIL_OTP_TITLE,
  SDA_PENDING_APPROVAL_TITLE,
  SDA_VALID_OTP,
} from '../../../../src/helpers/professoresFlow.js';

test.describe('Server-Driven Auth — Self-Registration (Professores)', () => {
  test('professores self-register through the form reaches the OTP screen and then PendingApproval', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockSdaEndpoint(
      page,
      'self-register',
      sdaActionEnvelope('VERIFY_EMAIL_OTP', {
        tempToken: 'temp-register-token-prof',
        expiresIn: 600,
      }),
    );
    await mockSdaEndpoint(
      page,
      'verify-email-otp',
      sdaActionEnvelope('GO_TO_PENDING_APPROVAL'),
    );

    await reachSdaLoginViaConfigFlag(app, page);
    await openSdaRegister(page);
    await fillSdaRegisterForm(page, {
      name: 'Prof Maria',
      phone: '11987650001',
      email: 'maria.teacher@example.com',
      password: 'Senha123',
    });
    await submitSdaRegister(page);

    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });

    await typeSdaOtp(page, SDA_VALID_OTP);
    await expect(app.semanticText(SDA_PENDING_APPROVAL_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });
  });
});
