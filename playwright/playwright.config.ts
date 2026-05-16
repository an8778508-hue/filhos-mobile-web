import { defineConfig, devices } from '@playwright/test';
import { FLAVORS, artifactsRoot, hosts, runId, timeouts, type Flavor } from './src/config.js';

/**
 * Playwright config for the Filhos (Criarte) Flutter Web build.
 *
 * The codebase ships two flavors — parents and professores — from one
 * source tree. Both are built and served by `globalSetup` on their own
 * static-server ports, and each flavor gets its own set of Playwright
 * projects (seed / generated / snapshot). A test selects its flavor by
 * the project name; the `baseURL` is set per-project so `page.goto('/')`
 * lands on the right app.
 *
 * We DO NOT use Playwright's `webServer` option:
 *  - It only knows how to start one process and watch one URL.
 *  - We need to orchestrate the Firebase emulator suite AND two Flutter
 *    web servers (release-build dart2js bundles served by an in-process
 *    Node static server — see `src/lifecycle/flutter.ts` for why
 *    `flutter run` doesn't work headless in Flutter 3.41+), in the right
 *    order.
 *
 * Lifecycle therefore lives in `globalSetup` / `globalTeardown`, which run
 * once per worker pool and have full control over spawning, attach-mode
 * detection, and process-tree cleanup on Windows.
 */
export default defineConfig({
  testDir: './tests',
  outputDir: `${artifactsRoot}/${runId}/test-results`,
  // Stateful harness: every spec shares one emulator suite + the per-flavor
  // Flutter web servers. `wipeAuthUsers()` runs between tests (in the
  // resetEmulatorState auto-fixture). Single-worker keeps the Auth-emulator
  // user table free of cross-test races; revisit if Firestore is added with
  // its own per-test reset.
  fullyParallel: false,
  workers: 1,
  // Retries are disabled even on CI. Every artifact (trace, browser-log,
  // log slice, HAR) is named under one `runId`-scoped directory that is
  // fixed at globalSetup time, so a retry would reuse the same paths and
  // silently overwrite the first attempt's data. If a spec is flaky, fix
  // it; don't mask it with a retry.
  retries: 0,
  // A flaky test (passes on retry but failed before) fails the run. We
  // already have retries: 0, but this is the explicit declaration that
  // any flake is a real bug — both locally and on CI.
  failOnFlakyTests: true,
  forbidOnly: !!process.env.CI,
  timeout: 5 * 60 * 1000,
  expect: { timeout: 15_000 },

  // Reporters: `list` for local terminal output, `html`/`json` for human +
  // tooling consumption, and the `github` reporter only when running on CI.
  reporter: [
    ['list'],
    ['html', { outputFolder: `${artifactsRoot}/${runId}/playwright-report`, open: 'never' }],
    ['json', { outputFile: `${artifactsRoot}/${runId}/results.json` }],
    // Emits `artifacts/<runId>/snapshot/aria-drift.md` whenever a snapshot
    // project test (`tests/snapshots/**`) fails `toMatchAriaSnapshot()`.
    ['./src/reporting/ariaDriftReporter.ts'],
    ...(process.env.CI ? [['github'] as ['github']] : []),
  ],

  globalSetup: './global-setup.ts',
  globalTeardown: './global-teardown.ts',

  use: {
    // baseURL is overridden per-project below — this is a fallback for any
    // top-level helper that doesn't run inside a project context.
    baseURL: hosts.flutter.parents,
    // Pin locale + timezone so behaviour doesn't drift between developer
    // machines and CI runners. Filhos is Brazilian — Portuguese is the
    // primary UI language and `America/Sao_Paulo` is the canonical zone.
    // Override per-test via `test.use({ locale, timezoneId })` when a
    // scenario needs Arabic or English.
    locale: 'pt-BR',
    timezoneId: 'America/Sao_Paulo',
    // Block Flutter Web's auto-registered `flutter_service_worker.js`. With
    // per-test browser contexts there's no caching win, and the SW can
    // intercept fetches against the live Auth emulator within a test and
    // serve stale cached responses.
    serviceWorkers: 'block',
    actionTimeout: 15_000,
    navigationTimeout: timeouts.navigation,
    trace: {
      mode: 'retain-on-first-failure',
      attachments: false,
      screenshots: true,
      snapshots: true,
      sources: true,
    },
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    launchOptions: {
      args: [
        // Force the engine to ship the semantics tree from the first frame,
        // belt-and-suspenders alongside AppPage.enableSemantics().
        '--force-renderer-accessibility',
        // Flutter 3.41 web only ships the CanvasKit/skwasm renderer (the HTML
        // renderer was removed in 3.29), so the engine MUST have a working
        // WebGL context. Headless Chromium has no GPU and Chrome M119+
        // disabled the SwiftShader WebGL fallback by default — without these
        // the context is lost on first frame (`CONTEXT_LOST_WEBGL`), the app
        // renders a black screen, and the semantics tree never populates.
        // ANGLE-over-SwiftShader gives a stable software WebGL implementation;
        // --enable-unsafe-swiftshader re-enables it for WebGL post-M119.
        '--use-gl=angle',
        '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader',
      ],
    },
  },

  // Chromium-only by necessity. The harness drives Flutter Web through its
  // semantics tree, which surfaces as `<flt-semantics>` DOM only after
  // Chromium's accessibility layer is enabled (via the
  // `--force-renderer-accessibility` launch arg above and the placeholder
  // click in `src/fixtures/appPage.ts#enableSemantics`). Firefox / WebKit
  // have their own a11y stacks that Flutter Web's CanvasKit renderer does
  // not target.
  //
  // Project naming convention: `<flavor>-<kind>`.
  //  - `<flavor>-generated`: where the generator writes scenarios under
  //    `tests/generated/<flavor>/<feature>/`. Promote stable ones by moving
  //    the spec file into `tests/<flavor>/<feature>/`.
  //  - `<flavor>-snapshot`: aria-snapshot goldens at route boundaries under
  //    `tests/snapshots/<flavor>/`.
  projects: (() => {
    const chromiumUse = {
      ...devices['Desktop Chrome'],
      viewport: { width: 1280, height: 900 },
    };
    const projectsFor = (flavor: Flavor) => {
      const use = { ...chromiumUse, baseURL: hosts.flutter[flavor] };
      return [
        {
          name: `${flavor}-generated`,
          testMatch: new RegExp(`tests[\\\\/]generated[\\\\/]${flavor}[\\\\/].*\\.spec\\.ts$`),
          use,
        },
        {
          name: `${flavor}-snapshot`,
          testMatch: new RegExp(`tests[\\\\/]snapshots[\\\\/]${flavor}[\\\\/].*\\.spec\\.ts$`),
          use,
        },
      ];
    };
    return FLAVORS.flatMap(projectsFor);
  })(),
});
