// spec: specs/parents-core-flows.plan.md §6.4
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../../src/fixtures/index.js';
import {
  reachLogin,
  typeInto,
  guardRest,
  mockJson,
  userPayload,
  LOGIN_TITLE,
} from '../../../../src/helpers/parentsFlow.js';

test.describe('Register — Email OTP Sign-up', () => {
  // New self sign-up flow: fill the form → email-otp/send → OTP screen →
  // verify the code → auth/register creates the account → routed by approval.
  // Unlike phone OTP (Auth-emulator gated), the email-OTP endpoints are pure
  // REST and therefore mockable.
  test('sign up sends an email OTP, verifies, then creates the account', async ({ app, page }) => {
    await guardRest(page);
    // Step 1 — email the verification code (EmailOTPSendResponse shape).
    await mockJson(page, '**/api/v1/auth/email-otp/send', {
      masked_email: 'a***@test.com',
      retry_after: 60,
    });
    // Step 2 — verify succeeds (the register flow ignores the returned user).
    await mockJson(page, '**/api/v1/auth/email-otp/verify', {
      access_token: 'tok-test',
      ...userPayload({ approved: true }),
    });
    // Step 3 — the account is created only after a verified email.
    await mockJson(page, '**/api/v1/auth/register', userPayload({ approved: true }));
    await mockJson(page, '**/api/v1/parent/home', { data: {} });

    await reachLogin(app, page);

    // Open the Register screen via the "Create account" link.
    await page.getByText('Create account').first().click();
    await expect(page.getByRole('textbox', { name: 'Name' })).toBeVisible({ timeout: 15_000 });

    // Fill the sign-up form (Name, Email, Password, Password confirmation).
    await typeInto(page, 'Name', 'Ana Test');
    await typeInto(page, 'Email', 'ana@test.com');
    await typeInto(page, 'Password', 'secret1');
    await typeInto(page, 'Password confirmation', 'secret1');

    // Confirm → RegisterBloc.sendEmailOtp → navigates to the OTP screen.
    // "Resend again" is rendered in both SMS and email modes, so it is the
    // stable signal that we reached the verification screen.
    await page.getByRole('button', { name: 'Confirm' }).click();
    await expect(app.semanticText('Resend again').first()).toBeVisible({ timeout: 20_000 });

    // Enter the 6-digit code → auto-submits at length 6 → verify + register →
    // UserBloc.loggedIn → OTPSuccess. Approved account routes to MainScreen.
    const pin = page.getByRole('textbox').first();
    await pin.click();
    await page.keyboard.type('123456', { delay: 20 });

    // Leaving the auth flow (login title never returns) with an interactive
    // shell present is the deterministic signal the account was created.
    await expect(app.semanticText(LOGIN_TITLE)).toBeHidden({ timeout: 20_000 });
    expect(await page.getByRole('button').count()).toBeGreaterThan(1);
  });
});
