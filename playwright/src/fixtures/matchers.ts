import { expect as baseExpect, type Locator } from '@playwright/test';

/**
 * Flutter-Web specific custom matchers. Built with the canonical Playwright
 * pattern: `baseExpect.extend(...)` returns an extended `expect` that
 * `fixtures/index.ts` re-exports. Consumers `import { test, expect } from
 * '../../src/fixtures/index.js'` and get the extra matchers automatically.
 * The `declare module` block augments the `Matchers<R>` interface so
 * TypeScript sees the new assertions on the chain.
 *
 *  - `toHaveSemanticLabel(expected)`: assert the locator's `aria-label`
 *    attribute matches. The semantics tree is the only way to identify
 *    canvas-rendered widgets — encoding "label" lookups in a matcher keeps
 *    test code readable.
 *
 * Message format follows the docs example
 * (`docs/src/test-assertions-js.md#expect-extend`): `matcherHint` produces
 * the `expect(received).toX(expected)` banner, then `printExpected` /
 * `printReceived` render values consistently with built-in matchers. `this`
 * is typed by Playwright's `extend` signature (ExpectMatcherState) — no
 * manual annotation needed.
 */

declare module '@playwright/test' {
  interface Matchers<R> {
    toHaveSemanticLabel(expected: string | RegExp): Promise<R>;
  }
}

export const expect = baseExpect.extend({
  async toHaveSemanticLabel(received: Locator, expected: string | RegExp) {
    const assertionName = 'toHaveSemanticLabel';
    // Flutter Web's semantics tree emits accessible names in one of three
    // forms depending on the widget:
    //   1. `<flt-semantics role="button" aria-label="Get started">` —
    //      common when a Semantics(label: ...) widget wraps the target.
    //   2. `<flt-semantics aria-labelledby="...">` — when the engine
    //      reuses a sibling node as the labelling source.
    //   3. `<flt-semantics role="button">Get started</flt-semantics>` —
    //      what `FilledButton(child: Text('Get started'))` produces, with
    //      the label as text content under the semantics node.
    // We compute the accessible name with the same priority order the
    // browser uses for `aria-label > aria-labelledby > text content`, so
    // the matcher matches whichever shape Flutter chose for a given
    // widget without the spec needing to know.
    const actual = await received.evaluate((el) => {
      const ariaLabel = el.getAttribute('aria-label');
      if (ariaLabel) return ariaLabel;
      const labelledBy = el.getAttribute('aria-labelledby');
      if (labelledBy) {
        const refs = labelledBy
          .split(/\s+/)
          .map((id) => document.getElementById(id)?.textContent ?? '')
          .filter((s) => s.length > 0);
        if (refs.length > 0) return refs.join(' ').trim();
      }
      const text = (el.textContent ?? '').trim();
      return text.length > 0 ? text : null;
    });
    const pass =
      typeof expected === 'string'
        ? actual === expected
        : actual !== null && expected.test(actual);

    const message = () =>
      this.utils.matcherHint(assertionName, undefined, undefined, { isNot: this.isNot }) +
      '\n\n' +
      `Expected: ${this.isNot ? 'not ' : ''}${this.utils.printExpected(expected)}\n` +
      `Received: ${actual === null ? '<no accessible name>' : this.utils.printReceived(actual)}`;

    return {
      pass,
      message,
      name: assertionName,
      expected,
      actual,
    };
  },
});
