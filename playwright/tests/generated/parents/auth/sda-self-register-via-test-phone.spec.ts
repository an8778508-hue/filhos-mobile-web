// spec: specs/server_driven_auth/spec.md §User Story 2 (Path B — phone shortcut)
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// Drives `ServerDrivenAuthImpl` against mocked endpoints. Enters a phone on
// LoginScreen → `check-identifier` returns VERIFY_EMAIL_OTP → app navigates
// straight to EmailOtpScreen without going through the registration form.
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  guardRest,
  reachSdaLoginViaConfigFlag,
  enterSdaPhone,
  tapSdaNext,
  typeSdaOtp,
  mockSdaEndpoint,
  sdaActionEnvelope,
  SDA_EMAIL_OTP_TITLE,
  SDA_PENDING_APPROVAL_TITLE,
  SDA_VALID_OTP,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Server-Driven Auth — Self-Registration', () => {
  test('phone-shortcut on LoginScreen lands on EmailOtpScreen and clears via OTP', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockSdaEndpoint(
      page,
      'check-identifier',
      sdaActionEnvelope('VERIFY_EMAIL_OTP', {
        tempToken: 'temp-checkid-token',
        expiresIn: 600,
      }),
    );
    await mockSdaEndpoint(
      page,
      'verify-email-otp',
      sdaActionEnvelope('GO_TO_PENDING_APPROVAL'),
    );

    await reachSdaLoginViaConfigFlag(app, page);
    await enterSdaPhone(page, '11900000003');
    await tapSdaNext(page);

    await expect(app.semanticText(SDA_EMAIL_OTP_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });

    await typeSdaOtp(page, SDA_VALID_OTP);
    await expect(app.semanticText(SDA_PENDING_APPROVAL_TITLE).first()).toBeVisible({
      timeout: 15_000,
    });
  });
});
