// spec: specs/server_driven_auth/spec.md §User Story 2 (Path B) — professores
// conventions: see playwright/README.md "Conventions every generated spec must follow"
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
} from '../../../../src/helpers/professoresFlow.js';

test.describe('Server-Driven Auth — Self-Registration (Professores)', () => {
  test('phone-shortcut on LoginScreen lands on EmailOtpScreen and clears via OTP', async ({
    app,
    page,
  }) => {
    await guardRest(page);
    await mockSdaEndpoint(
      page,
      'check-identifier',
      sdaActionEnvelope('VERIFY_EMAIL_OTP', {
        tempToken: 'temp-checkid-token-prof',
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
