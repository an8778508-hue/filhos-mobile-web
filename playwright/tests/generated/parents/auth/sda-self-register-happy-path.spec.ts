// spec: specs/server_driven_auth/spec.md §User Story 2 (Path A)
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// Drives the real `ServerDrivenAuthImpl` against mocked REST endpoints. The
// SDA flow is activated at runtime by `mockConfigWithSdaOn` flipping
// `server_driven_auth_enabled = true` in the `/api/v1/config` response —
// `DebugFlags.kSdaDevTest` is forced `false` at harness build time via
// `--dart-define=SDA_DEV_TEST=false`.
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
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Server-Driven Auth — Self-Registration', () => {
  test('parents self-register through the form reaches the OTP screen and then PendingApproval', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    // `self-register` returns the uniform envelope with VERIFY_EMAIL_OTP +
    // a temp_token; `verify-email-otp` then resolves to
    // GO_TO_PENDING_APPROVAL.
    await mockSdaEndpoint(
      page,
      'self-register',
      sdaActionEnvelope('VERIFY_EMAIL_OTP', {
        tempToken: 'temp-register-token',
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
      name: 'Maria Test',
      phone: '11987654321',
      email: 'maria@example.com',
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
