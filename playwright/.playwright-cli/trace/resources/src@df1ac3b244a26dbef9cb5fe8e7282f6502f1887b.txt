import type { Locator, Page } from '@playwright/test';
import { expect } from '@playwright/test';

import { timeouts } from '../config.js';

/**
 * `AppPage` wraps a Playwright `Page` with the Flutter-Web-specific concerns
 * that every test in this harness needs:
 *
 *  1. **Semantics tree.** Flutter Web renders the entire UI to a single
 *     `<canvas>` element. Playwright can't click pixels, so we have to make
 *     Flutter materialize its semantics tree as real DOM. Flutter does that
 *     on demand the first time accessibility is requested. We trigger it by
 *     dispatching a `click` on the hidden `<flt-semantics-placeholder>` that
 *     Flutter inserts at startup. After the click, semantics nodes appear
 *     under `<flt-semantics-host>` as `<flt-semantics role="..." aria-label="...">`
 *     elements that `getByRole`/`getByText` can target.
 *
 *  2. **Live app, no debug bypass.** Tests drive the same release-build
 *     binary the static server is serving — there is no `?testMode=1` query
 *     param or behind-the-scenes shortcut in the router. Reaching surfaces
 *     that aren't organically navigable (post-login screens before the
 *     Filhos backend is reachable from the harness) is the job of
 *     generator-produced specs under `tests/generated/`, which can drive
 *     the Auth-emulator OTP helper in `src/helpers/auth.ts` to seed a
 *     signed-in Firebase user.
 */

// `<flt-semantics-placeholder>` is bootstrap plumbing — its `aria-label` is
// "Enable accessibility", which we never want to mistake for app content.
const PLUMBING_LABEL_RE = /^(enable accessibility|placeholder|application)$/i;

// Roles that count as "real" semantic content the page has reached a steady
// interactive state. Matches lines like `- button "Continue"` in the YAML.
const INTERACTIVE_ROLE_LINE_RE =
  /^\s*-\s+(button|textbox|checkbox|radio|link|combobox|switch|tab|menuitem|option|listitem|heading)\b\s+"([^"]+)"/m;

export class AppPage {
  constructor(public readonly page: Page) {}

  /**
   * Navigate to the app and wait for Flutter + the semantics tree.
   *
   * Filhos has no URL-driven routing — `main.dart` uses imperative
   * `Navigator.push` (no GoRouter, no `usePathUrlStrategy()`), so the URL
   * stays at `/` for the entire session. The `path` parameter is therefore
   * effectively decorative: `goto('/anything')` and `goto('/')` both land
   * on the same boot screen, and reaching post-login surfaces is the job of
   * driving the UI (or the Auth-emulator helpers in `src/helpers/auth.ts`).
   */
  async goto(path = '/'): Promise<void> {
    await this.page.goto(path, { waitUntil: 'domcontentloaded' });
    await this.waitForFlutterReady();
    await this.enableSemantics();
    await this.waitForSemanticsContent();
  }

  /**
   * Cold-start the app at `/`. Alias for `goto('/')` — kept so generated
   * specs can express boot intent (`await app.coldStart()`) separately
   * from mid-test re-navigation.
   */
  async coldStart(): Promise<void> {
    await this.goto('/');
  }

  /** Wait for Flutter to mount the engine — the canvas appears via
   *  `<flt-glass-pane>` once `runApp` has run. */
  async waitForFlutterReady(): Promise<void> {
    await this.page.waitForFunction(
      () =>
        document.querySelector('flt-glass-pane') !== null ||
        document.querySelector('flutter-view') !== null,
      undefined,
      { timeout: timeouts.flutterBoot },
    );
  }

  /**
   * Force-enable Flutter's accessibility/semantics tree so DOM-based
   * locators work. Idempotent: clicking the placeholder again is a no-op
   * once semantics are enabled, and we early-exit if they already are.
   */
  async enableSemantics(): Promise<void> {
    const alreadyOn = await this.semanticsEnabled();
    if (alreadyOn) return;

    // Flutter 3.41's `DesktopSemanticsEnabler` only activates on a real
    // `PointerEvent` pointerdown — it type-checks the event and ignores a
    // plain `new Event('pointerdown')` or a bare `el.click()` MouseEvent.
    // It also attaches that pointerdown listener to `<flt-semantics-placeholder>`
    // a few frames AFTER the element is mounted, so a single early dispatch
    // races the listener and is silently lost (the placeholder is never
    // consumed and `flt-semantics-host` stays empty forever). So we re-dispatch
    // the pointerdown→pointerup→click sequence on every poll tick until the
    // engine consumes it (placeholder removed) or starts emitting nodes.
    await expect
      .poll(
        async () => {
          // Flutter 3.41 mounts `<flt-semantics-placeholder>` as a direct
          // child of <body> (not inside <flt-glass-pane>), so a plain global
          // locator is correct and reliable; the old chained selector
          // resolved nothing and its dispatch was a silent no-op.
          await this.page
            .locator('flt-semantics-placeholder')
            .first()
            .evaluate((el) => {
              const node = el as HTMLElement;
              const o = {
                bubbles: true,
                cancelable: true,
                composed: true,
                pointerType: 'mouse',
                button: 0,
              };
              node.dispatchEvent(new PointerEvent('pointerdown', o));
              node.dispatchEvent(new PointerEvent('pointerup', o));
              node.dispatchEvent(
                new MouseEvent('click', { bubbles: true, cancelable: true, composed: true }),
              );
            })
            // Once the placeholder is consumed the locator stops resolving;
            // that's the success path, not an error. Any failure here just
            // means "retry next tick" — the poll predicate is the real gate.
            .catch(() => {});
          return this.page.evaluate(
            () =>
              document.querySelector('flt-semantics-placeholder') === null ||
              (document.querySelector('flt-semantics-host')?.childElementCount ?? 0) > 0,
          );
        },
        {
          timeout: timeouts.semanticsEnable,
          message: 'Flutter never consumed the semantics-enable placeholder',
        },
      )
      .toBe(true);
  }

  async semanticsEnabled(): Promise<boolean> {
    // `flt-semantics-host` is NOT a reliable signal: Flutter 3.41 mounts it
    // (empty) on the very first frame, so checking only for its presence made
    // enableSemantics() early-return before it ever clicked the placeholder.
    // Flutter removes `flt-semantics-placeholder` the moment semantics is
    // genuinely activated, so "host present AND placeholder gone" is the
    // accurate idempotency check.
    return this.page.evaluate(
      () =>
        document.querySelector('flt-semantics-host') !== null &&
        document.querySelector('flt-semantics-placeholder') === null,
    );
  }

  /**
   * Text locator scoped to Flutter's semantics host — the subtree that
   * holds the widgets a sighted user actually sees.
   *
   * Why this exists: Flutter Web mirrors `SemanticsService.announce()`
   * (which `FormBuilderTextField` fires for every validation error) into
   * an EPHEMERAL `<flt-announcement-assertive>` / `<flt-announcement-polite>`
   * element under `<flt-announcement-host>` — a body-level sibling of
   * `<flt-semantics-host>`, NOT a child of it. For a brief window after a
   * failed submit the same string therefore exists twice in the DOM: once
   * as the rendered InputDecorator errorText `<span>` inside the semantics
   * host, and once as the screen-reader announcement outside it. A bare
   * `page.getByText(msg).filter({ visible: true })` matches BOTH during
   * that window and trips Playwright strict mode. Both behaviours are
   * correct (the announcement is good a11y); the test just has to address
   * the rendered widget unambiguously. Scoping to `flt-semantics-host`
   * does exactly that and never sees the announcement plumbing — the same
   * spirit as the `<flt-semantics-placeholder>` special-casing above.
   */
  semanticText(text: string | RegExp): Locator {
    return this.page.locator('flt-semantics-host').getByText(text);
  }

  /**
   * Capture (or compare) an aria-snapshot of the Flutter semantics tree at
   * the current route. The snapshot is a text dump of roles, labels, and
   * structure — the same surface assistive tech reads — so it serves as
   * regression coverage of "what does this page expose semantically?".
   *
   * The snapshot file lands beside the calling spec under
   * `<spec>.spec.ts-snapshots/<name>.aria.yml`. Generate baselines once with
   * `npm run snapshot:update`, then `npm run snapshot` will fail on any
   * structural drift. PII guardrail: review generated YAML before committing
   * — server-driven copy (terms, consent excerpts) is fine; any rendered
   * user-data should be redacted or routed off-snapshot.
   *
   * `enableSemantics()` mounts the semantics host element, but Flutter
   * dispatches the actual nodes frame-by-frame after the placeholder click —
   * so we poll `page.ariaSnapshot()` until at least one non-plumbing
   * interactive role surfaces. Without that wait, the snapshot can capture
   * the empty skeleton.
   */
  async snapshotRoute(name: string): Promise<void> {
    await this.waitForFlutterReady();
    await this.enableSemantics();
    await this.waitForSemanticsContent();
    await expect(this.page).toMatchAriaSnapshot({ name: `${name}.aria.yml` });
  }

  /**
   * Poll `page.ariaSnapshot()` until at least one app-level interactive
   * (anything other than the "Enable accessibility" placeholder) appears in
   * the YAML tree. Used by `snapshotRoute()` to avoid capturing the empty
   * skeleton during the first few frames after the placeholder click.
   */
  async waitForSemanticsContent(opts: { timeout?: number } = {}): Promise<void> {
    const timeout = opts.timeout ?? timeouts.semanticsEnable;
    await expect
      .poll(
        async () => {
          const yaml = await this.page.ariaSnapshot().catch(() => '');
          const match = INTERACTIVE_ROLE_LINE_RE.exec(yaml);
          if (!match) return false;
          return !PLUMBING_LABEL_RE.test(match[2]);
        },
        { timeout, message: 'Flutter semantics tree never produced a non-plumbing interactive' },
      )
      .toBe(true);
  }
}
