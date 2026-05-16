// spec: specs/parents-core-flows.plan.md §10.4
// conventions: see playwright/README.md "Conventions every generated spec must follow"
//
// BLOCKED — same root cause as the parents OTP spec (memory
// pw-otp-not-emulated). The release build never wires the Firebase Auth
// emulator, so verifyPhoneNumber hits prod Firebase and fails
// `billing-not-enabled`. Un-fixme when the build gains emulator wiring.
import { test, expect } from '../../../../src/fixtures/index.js';
import { reachLogin, guardRest, enterPhone } from '../../../../src/helpers/professoresFlow.js';

test.describe('Professores OTP Flow', () => {
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
  });
});
