import type { Page, TestInfo } from '@playwright/test';

import { ports } from '../config.js';

export interface CapturedLog {
  kind: 'console' | 'pageerror' | 'requestfailed' | 'network';
  level?: string;
  text: string;
  url?: string;
  at: string;
}

const BACKEND_PORTS = new Set<string>([
  String(ports.auth),
]);
const LOOPBACK_HOSTS = new Set<string>(['127.0.0.1', 'localhost', '[::1]']);

function isBackendUrl(rawUrl: string): boolean {
  try {
    const u = new URL(rawUrl);
    return LOOPBACK_HOSTS.has(u.hostname) && BACKEND_PORTS.has(u.port);
  } catch {
    return false;
  }
}

/**
 * Wire up browser-side log capture for a single test. Returns the live array
 * (so the test can assert on it mid-flight) plus an `attach()` method that
 * persists the log as a Playwright test attachment, so failures land in the
 * HTML report next to the trace.
 *
 * Captured:
 *  - page.on('console')      → every `console.*` invocation from the app
 *  - page.on('pageerror')    → uncaught exceptions in the browser
 *  - page.on('requestfailed')→ failed network requests (DNS, CORS, abort)
 *  - response failures (>=400) on Firebase emulator endpoints (Auth, plus
 *    any of Firestore / Functions / Storage if the user enables them in
 *    `playwright/firebase.json`) — both client errors and server errors are
 *    captured because a 4xx (unauthenticated, failed-precondition) is just
 *    as diagnostic as a 5xx. The fixture in `fixtures/index.ts` further
 *    narrows to HTTP 5xx + pageerror when deciding what counts as a noisy
 *    "finding" surfaced to the bundle.
 */
export function attachBrowserLogs(page: Page) {
  const log: CapturedLog[] = [];
  const at = () => new Date().toISOString();

  page.on('console', (msg) => {
    // Filter out the noise CanvasKit prints on cold start. We keep error/
    // warning unconditionally because the app's own debugPrints surface
    // through `console.log` and we want to see crashes.
    const level = msg.type();
    const text = msg.text();
    if (level === 'debug') return;
    log.push({ kind: 'console', level, text, at: at() });
  });

  page.on('pageerror', (err) => {
    log.push({
      kind: 'pageerror',
      text: `${err.name}: ${err.message}\n${err.stack ?? ''}`,
      at: at(),
    });
  });

  page.on('requestfailed', (req) => {
    log.push({
      kind: 'requestfailed',
      text: `${req.method()} ${req.url()} — ${req.failure()?.errorText ?? 'unknown'}`,
      url: req.url(),
      at: at(),
    });
  });

  page.on('response', (res) => {
    const url = res.url();
    if (!isBackendUrl(url)) return;
    if (res.status() >= 400) {
      log.push({
        kind: 'network',
        text: `HTTP ${res.status()} ${res.request().method()} ${url}`,
        url,
        at: at(),
      });
    }
  });

  async function attach(info: TestInfo, name = 'browser-log.json'): Promise<void> {
    // Live-listener log is the primary signal. Enrich with Playwright 1.56
    // page-history APIs as a sanity cross-check, not a replacement —
    // per the docs, `page.requests()` caps at 100 last and collects entries
    // proactively to prevent unbounded memory ("once collected, retrieving
    // most information about the request is impossible"). So the history
    // snapshot is a *tail*, not an exhaustive list. The naming below
    // (`recentBackendRequests`, counts only for console/pageerror) reflects
    // that. Wrapped in try/catch because a hard page crash closes the
    // page; calling history APIs on a closed page throws, and we want the
    // listener-captured `log` to land even when history can't.
    let recentBackendRequests: Array<{
      method: string;
      url: string;
      resourceType: string;
    }> = [];
    let historyConsoleCount = 0;
    let historyPageErrorCount = 0;
    let historyError: string | null = null;
    try {
      const requests = await page.requests();
      recentBackendRequests = requests
        .filter((req) => isBackendUrl(req.url()))
        .map((req) => ({
          method: req.method(),
          url: req.url(),
          resourceType: req.resourceType(),
        }));
      historyConsoleCount = (await page.consoleMessages()).length;
      historyPageErrorCount = (await page.pageErrors()).length;
    } catch (err) {
      historyError = err instanceof Error ? err.message : String(err);
    }

    const payload = {
      // Listener-captured events. The healer slash command reads this file
      // directly when a spec fails.
      log,
      history: {
        // Tail of recent backend requests from `page.requests()` — at most
        // 100 entries, possibly fewer if older ones were collected. NOT an
        // authoritative "what did this test call?" list; the live-listener
        // `log` above is. Useful as a quick sample without re-correlating
        // against the HAR.
        recentBackendRequests,
        // Cross-check counts vs `log.filter(kind=='console')` length and
        // pageerror count — a meaningful delta hints at a listener gap.
        consoleMessagesCount: historyConsoleCount,
        pageErrorsCount: historyPageErrorCount,
        ...(historyError ? { error: historyError } : {}),
      },
    };

    await info.attach(name, {
      body: JSON.stringify(payload, null, 2),
      contentType: 'application/json',
    });
  }

  return { log, attach };
}
