// spec: specs/server_driven_auth/spec.md §User Story 2 (Path A — negative path)
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// Negative-path coverage: an invalid OTP must surface the localized
// `sda_error_invalid_credentials` message and keep the user on
// EmailOtpScreen. The cubit's `OTP_INVALID → SdaFailure →
// AuthErrorCodes.localizedKey → SnackBar` pipeline is what's under test.
//
// (Re-typing a fresh code in pin_code_fields after a failure is a separate
// widget-recovery concern and is tracked in
// `specs/server_driven_auth/tasks.md` Wave 9.)
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
} from '../../../../src/helpers/parentsFlow.js';

const SDA_INVALID_CREDENTIALS_EN = /incorrect phone or password/i;

test.describe('Server-Driven Auth — Self-Registration', () => {
  test('wrong OTP surfaces sda_error_invalid_credentials and keeps EmailOtpScreen visible', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockSdaEndpoint(
      page,
      'self-register',
      sdaActionEnvelope('VERIFY_EMAIL_OTP', {
        tempToken: 'temp-register-token',
        expiresIn: 600,
      }),
    );
    // 400 OTP_INVALID — the uniform error envelope. NetworkClient maps it to
    // `Failure.message = 'OTP_INVALID'`; the cubit then maps that code to
    // the `sda_error_invalid_credentials` key via `AuthErrorCodes`.
    await mockSdaEndpoint(
      page,
      'verify-email-otp',
      sdaErrorEnvelope('OTP_INVALID'),
      400,
    );

    await reachSdaLoginViaConfigFlag(app, page);
    await openSdaRegister(page);
    await fillSdaRegisterForm(page, {
      name: 'Maria Retry',
      phone: '11900000002',
      email: 'maria.retry@example.com',
      password: 'Senha123',
    });
    await submitSdaRegister(page);
    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });

    await typeSdaOtp(page, '000000');

    // Assertion 1: localized error surfaces.
    await expect(page.getByText(SDA_INVALID_CREDENTIALS_EN).first()).toBeVisible({
      timeout: 10_000,
    });
    // Assertion 2: no navigation — still on EmailOtpScreen.
    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible();
  });
});
