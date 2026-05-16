import type { APIRequestContext } from '@playwright/test';

/**
 * Process-scoped holder for the per-test `APIRequestContext`.
 *
 * Why a module-level holder instead of threading `api` through every helper:
 *  - Single-worker harness (`workers: 1` is a correctness requirement, see
 *    playwright.config.ts) — no concurrent test contexts can race here.
 *  - Helpers already read `hosts`, `projectId` from `config.ts` at module
 *    scope; the API context is the same shape of runtime dependency:
 *    "set by the fixture, used by the helpers."
 *  - Threading `api` through every helper would be a 200-line plumbing
 *    change with no behavioural payoff.
 *
 * The `api` fixture in `src/fixtures/index.ts` calls `setApi()` before each
 * test and `setApi(undefined)` in teardown. Calling `getApi()` outside that
 * window throws — that's the safety rail in lieu of a typed parameter.
 */

let currentApi: APIRequestContext | undefined;

export function setApi(ctx: APIRequestContext | undefined): void {
  currentApi = ctx;
}

export function getApi(): APIRequestContext {
  if (!currentApi) {
    throw new Error(
      'APIRequestContext not initialized — helpers/_apiContext.getApi() called outside a test. ' +
        'The `api` auto-fixture in src/fixtures/index.ts sets this; check fixture order if you see this from inside a test.',
    );
  }
  return currentApi;
}
