// spec: specs/server_driven_auth/spec.md §User Story 2 (Path A, negative) — professores
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// Negative-path coverage for the professores flavor. The `OTP_INVALID →
// SdaFailure → AuthErrorCodes.localizedKey → SnackBar` pipeline is the same
// across flavors — the cubit / dispatcher / error mapping have no flavor
// branch — so this is a parallel assertion for the teachers app.
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
  sdaErrorEnvelope,
  SDA_EMAIL_OTP_TITLE,
} from '../../../../src/helpers/professoresFlow.js';

const SDA_INVALID_CREDENTIALS_EN = /incorrect phone or password/i;

test.describe('Server-Driven Auth — Self-Registration (Professores)', () => {
  test('wrong OTP surfaces sda_error_invalid_credentials and keeps EmailOtpScreen visible', async ({
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
      sdaErrorEnvelope('OTP_INVALID'),
      400,
    );

    await reachSdaLoginViaConfigFlag(app, page);
    await openSdaRegister(page);
    await fillSdaRegisterForm(page, {
      name: 'Prof Retry',
      phone: '11900000022',
      email: 'prof.retry@example.com',
      password: 'Senha123',
    });
    await submitSdaRegister(page);
    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });

    await typeSdaOtp(page, '000000');

    await expect(page.getByText(SDA_INVALID_CREDENTIALS_EN).first()).toBeVisible({
      timeout: 10_000,
    });
    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible();
  });
});
