// spec: smoke — parents cold start
// conventions: see playwright/README.md "Conventions every generated spec must follow"
import { test, expect } from '../../../src/fixtures/index.js';

test.describe('Smoke', () => {
  test('parents app cold-starts past splash into an interactive screen', async ({ app, page }) => {
    // Defensive REST guard. A fresh browser context has no persisted user, so
    // SplashBloc emits SplashSuccess immediately without an API call — this
    // only fires if something unexpected reaches the network, keeping the
    // smoke run off the prod backend (ApiConst.baseUrl is a hard-coded const).
    await page.route('**/api/v1/**', (route) =>
      route.fulfill({ status: 503, contentType: 'application/json', body: '{}' }),
    );

    // AppPage.coldStart() navigates to '/', clicks the hidden
    // <flt-semantics-placeholder> to mount the semantics tree, and waits for
    // the engine plus a non-plumbing interactive role to appear.
    await app.coldStart();

    // The splash screen (logo only, ~2s) auto-navigates to the language
    // chooser or the login screen for the parents flavor — every landing
    // screen exposes an interactive widget in the semantics tree.
    const interactive = page.getByRole('button').or(page.getByRole('textbox'));
    await expect(interactive.first()).toBeVisible({ timeout: 20_000 });
  });
});
