import { test as base } from '@playwright/test';

import { AppPage } from './appPage.js';
import { attachBrowserLogs, type CapturedLog } from './logCapture.js';
import { setApi } from '../helpers/_apiContext.js';
import { wipeAuthUsers } from '../helpers/authAdmin.js';
import { harEnabled, type Flavor } from '../config.js';
import {
  captureOffset,
  grepTail,
  readSlice,
  tailLines,
} from '../lifecycle/logSlicer.js';

// Same patterns as exception lines we want to surface from the Flutter log
// on failure. Kept here so the fixture doesn't reach into a lifecycle
// module owned by the runner-side process.
const FLUTTER_EXCEPTION_RE =
  /(EXCEPTION CAUGHT BY|FlutterError|Unhandled Exception|Bad state|Null check operator used on a null value)/i;

interface Fixtures {
  app: AppPage;
  /**
   * Live array of captured browser logs (console / pageerror / requestfailed /
   * 4xx-5xx backend responses). Tests can grep mid-flight; the JSON dump is
   * always attached at end-of-test by the `flutterDiagnostics` auto-fixture.
   */
  browserLog: CapturedLog[];
  /**
   * Auto-applied per-test reset of Auth users so OTP / signed-in state
   * starts empty for every spec. The browser context is fresh per test by
   * default — IndexedDB (Hive) is therefore empty automatically.
   */
  resetEmulatorState: void;
  /**
   * Auto-applied per-test HAR (HTTP Archive) recording when `PW_HAR=1`. Lands
   * one HAR per test under `<test-results>/network.har`. Default off — the
   * existing Playwright trace already records network, and HAR is a secondary,
   * portable view for tools that ingest HAR natively (Chrome devtools,
   * har-viewer). `content: 'embed'` records full response bodies for
   * diagnosis.
   */
  harTracing: void;
  /**
   * Auto-applied per-test log slicing + crash-guard.
   *  - ALWAYS attaches the flavor's `flutter-run.<flavor>.window.log` and
   *    `firebase-emulators.window.log` sliced from `globalSetup`-time byte
   *    offsets to end-of-test.
   *  - On failure, additionally attaches the last 200 lines of each log and
   *    any Flutter framework exception lines.
   *
   * The flavor is read from the active Playwright project name
   * (`testInfo.project.name`), which always starts with `parents-` or
   * `professores-`. Log file paths come from
   * `process.env.E2E_FLUTTER_LOG_PARENTS` / `..._PROFESSORES` and
   * `process.env.E2E_EMULATORS_LOG`, which `globalSetup` sets so worker
   * processes can find them — `globalThis` set in the runner process is
   * NOT visible here.
   */
  flutterDiagnostics: void;
}

function flavorOf(projectName: string): Flavor | undefined {
  if (projectName.startsWith('parents')) return 'parents';
  if (projectName.startsWith('professores')) return 'professores';
  return undefined;
}

export const test = base.extend<Fixtures>({
  resetEmulatorState: [async ({ request }, use) => {
    // Publish Playwright's built-in `request: APIRequestContext` fixture
    // (per-test isolated, auto-disposed) into `helpers/_apiContext.ts` so
    // every helper that talks to an emulator routes through Playwright's
    // `request` API instead of raw `fetch`. The Trace Viewer's API
    // requests pane then shows every round-trip as a step under the test
    // that triggered it.
    setApi(request);
    try {
      await wipeAuthUsers();
      await use();
    } finally {
      setApi(undefined);
    }
  }, { auto: true }],

  app: async ({ page }, use) => {
    const app = new AppPage(page);
    await use(app);
  },

  harTracing: [async ({ page }, use, testInfo) => {
    if (!harEnabled) {
      await use();
      return;
    }
    // `testInfo.outputPath()` resolves into the per-test subdirectory that
    // Playwright auto-creates under `outputDir`. Using it instead of building
    // paths manually means we inherit collision-free naming, start-of-run
    // cleanup, and co-location with the trace zip.
    //
    // `tracing.startHar()` is independent of `tracing.start()` (which the
    // framework auto-fires per the `trace: { mode: ... }` use config). The
    // docs constrain only to "one HAR per BrowserContext at a time"; trace +
    // HAR coexist by design.
    //
    // `content: 'embed'` records full response bodies for diagnosis.
    const harPath = testInfo.outputPath('network.har');
    const context = page.context();
    await context.tracing.startHar(harPath, { content: 'embed' });
    try {
      await use();
    } finally {
      await context.tracing.stopHar();
      await testInfo.attach('network.har', { path: harPath, contentType: 'application/json' }).catch(() => undefined);
    }
  }, { auto: true }],

  browserLog: async ({ page }, use, testInfo) => {
    const { log, attach } = attachBrowserLogs(page);
    try {
      await use(log);
    } finally {
      // Always attach so a hard failure mid-test still produces the JSON for
      // review. `attach()` itself is internally wrapped against a closed
      // page (Playwright history APIs throw on a torn-down context).
      await attach(testInfo).catch(() => undefined);
    }
  },

  flutterDiagnostics: [async ({ browserLog }, use, testInfo) => {
    const flavor = flavorOf(testInfo.project.name);
    const flutterLogPath = flavor
      ? process.env[`E2E_FLUTTER_LOG_${flavor.toUpperCase()}`]
      : undefined;
    const emulatorsLogPath = process.env.E2E_EMULATORS_LOG;
    const attachKey = flavor
      ? (flavor === 'parents' ? 'PW_BASE_URL_PARENTS' : 'PW_BASE_URL_PROFESSORES')
      : undefined;

    // globalSetup sets E2E_EMULATORS_LOG unconditionally and the per-flavor
    // E2E_FLUTTER_LOG_* whenever it spawns the in-process static server. The
    // PW_BASE_URL_<FLAVOR> envs flip a flavor into attach mode, where the
    // developer owns the Flutter process and we have no log file to slice.
    // Any other unset path means globalSetup crashed before exporting the env
    // var — surface that loudly so we don't silently attach nothing.
    if (
      emulatorsLogPath === undefined &&
      process.env.E2E_EMULATORS_ATTACHED === undefined
    ) {
      throw new Error(
        'E2E_EMULATORS_LOG is not set — globalSetup likely failed before spawning emulators.',
      );
    }
    if (
      flavor &&
      flutterLogPath === undefined &&
      (attachKey === undefined || process.env[attachKey] === undefined)
    ) {
      throw new Error(
        `E2E_FLUTTER_LOG_${flavor.toUpperCase()} is not set and ${attachKey} is unset — globalSetup likely failed before spawning the Flutter static server.`,
      );
    }
    const flutterOffset = captureOffset(flutterLogPath);
    const emulatorsOffset = captureOffset(emulatorsLogPath);

    await use();

    // ALWAYS attach the per-test slice so reviewers can correlate without
    // chasing the full per-run log file.
    const flutterWindow = readSlice(flutterLogPath, flutterOffset);
    if (flutterWindow.length > 0) {
      await testInfo.attach(`flutter-run.${flavor ?? 'unknown'}.window.log`, {
        body: flutterWindow,
        contentType: 'text/plain',
      });
    }
    const emulatorsWindow = readSlice(emulatorsLogPath, emulatorsOffset);
    if (emulatorsWindow.length > 0) {
      await testInfo.attach('firebase-emulators.window.log', {
        body: emulatorsWindow,
        contentType: 'text/plain',
      });
    }

    // Browser-hygiene observation. Pageerrors / backend 5xx surface as a
    // Playwright annotation so the HTML report flags a noisy session without
    // polluting stdout.
    //
    // The Firebase Auth emulator deliberately returns HTTP 501 from
    // `/identitytoolkit.googleapis.com/v2/recaptchaConfig` — the JS SDK
    // probes that endpoint on cold start to decide whether reCAPTCHA
    // Enterprise is configured; a 501 is the negotiation signal that the
    // SDK should fall back to the legacy reCAPTCHA flow.
    const fatal = browserLog.filter((l) => {
      if (l.kind === 'pageerror') return true;
      if (l.kind !== 'network' || !/HTTP 5\d\d/.test(l.text)) return false;
      if (/\/v2\/recaptchaConfig/.test(l.text)) return false;
      return true;
    });
    if (fatal.length > 0) {
      testInfo.annotations.push({
        type: 'browser-findings',
        description: `${fatal.length} pageerror/HTTP 5xx (see browser-log.json)`,
      });
    }

    // Defence-in-depth: on failure, also attach the tails. If the test failed
    // before any log lines flew in its window, the tail still tells the story.
    if (testInfo.status !== testInfo.expectedStatus) {
      const flutterTail = tailLines(flutterLogPath, 200);
      if (flutterTail.length > 0) {
        await testInfo.attach(`flutter-run.${flavor ?? 'unknown'}.tail.log`, {
          body: flutterTail.join('\n'),
          contentType: 'text/plain',
        });
      }
      const exceptions = grepTail(flutterLogPath, FLUTTER_EXCEPTION_RE, 1000);
      if (exceptions.length > 0) {
        await testInfo.attach('flutter-exceptions.txt', {
          body: exceptions.join('\n'),
          contentType: 'text/plain',
        });
      }
      const emulatorsTail = tailLines(emulatorsLogPath, 200);
      if (emulatorsTail.length > 0) {
        await testInfo.attach('firebase-emulators.tail.log', {
          body: emulatorsTail.join('\n'),
          contentType: 'text/plain',
        });
      }
    }
  }, { auto: true }],
});

// Re-export the extended `expect` from `matchers.ts` so `import { test,
// expect } from 'fixtures/index.js'` gives consumers the custom matchers
// (`toHaveSemanticLabel`) alongside every built-in assertion.
export { expect } from './matchers.js';
