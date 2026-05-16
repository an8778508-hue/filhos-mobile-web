// spec: specs/parents-core-flows.plan.md §5.1
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// BLOCKED — see memory `pw-otp-not-emulated`. The harness builds
// `flutter build web --release` with no Firebase Auth emulator wiring
// (no `useAuthEmulator` anywhere in lib/, no --dart-define in
// playwright/src/lifecycle/flutter.ts), so `verifyPhoneNumber` hits
// PRODUCTION Firebase and fails with `billing-not-enabled` (phone auth
// needs billing on the prod project). Verified live: the Login screen
// renders the error "billing-not-enabledError" instead of advancing to
// the OTP screen. This is a real app/harness integration gap, not a
// flaky locator — the email-login REST path (see auth/*.spec.ts) is the
// automatable authenticated entry. Un-fixme when the build gains
// emulator wiring (e.g. --dart-define=USE_FIREBASE_EMULATOR=1).
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, guardRest, enterPhone } from '../../../../src/helpers/parentsFlow.js';

test.describe('OTP Flow', () => {
  test('requesting OTP shows the phone-verification screen', async ({ app, page }) => {
    test.fixme(
      true,
      'Release build never wires the Firebase Auth emulator; verifyPhoneNumber ' +
        'hits prod Firebase and fails billing-not-enabled. See memory pw-otp-not-emulated.',
    );

    await guardRest(page);
    await reachLogin(app, page);

    await enterPhone(page, '1099887766');
    await page.getByRole('button', { name: 'Login' }).click();

    await expect(app.semanticText('Phone verification').first()).toBeVisible({ timeout: 20_000 });
    await expect(app.semanticText('Enter OTP that sent to').first()).toBeVisible();
  });
});
