# Filhos (Criarte) Playwright harness

Playwright end-to-end harness for the Filhos (Criarte) Flutter web build, running on **Playwright Test** ≥ 1.60 (`package.json` pins `^1.60.0`; confirm at runtime with `npx playwright --version` and verify any API behaviour against Context7 `/microsoft/playwright.dev` — the live docs are the source of truth, not training data).

The harness drives the **same release-mode `dart2js` bundle** the project ships, against the **Firebase Auth emulator** for deterministic phone-OTP. It runs both Flutter flavors (`parents` and `professores`) side by side: each flavor is built into its own `build/web-<flavor>/` directory and served on its own static-server port. There is no canned seed test — the scaffold ships empty so generated specs are the only source of truth for what's covered. Scenarios are generated on demand by the agent loop (`/pw-plan`, `/pw-generate`, `/pw-heal`, `/pw-coverage`) running in the main Claude Code agent with full tool access.

## How it works (semantics, not pixels)

Flutter Web renders the entire UI to one canvas — there is no native HTML for buttons or inputs. The engine ships a parallel **semantics tree** as `<flt-semantics aria-label="…">` elements, gated behind an "Enable accessibility" placeholder. The harness:

1. Forces accessibility on at first navigation
   ([`AppPage.enableSemantics`](src/fixtures/appPage.ts) clicks the hidden `<flt-semantics-placeholder>`; [`playwright.config.ts`](playwright.config.ts) passes `--force-renderer-accessibility` to Chromium as belt-and-suspenders).
2. Locates widgets via `getByRole` / `getByLabel` / `getByText` against the semantics-tree DOM — never CSS classes or pixel positions.
3. Types into TextFields by clicking the semantic label (which mounts a real `<input>` inside `<flt-text-editing-host>`) then `page.keyboard.type`.
4. For phone-OTP scenarios that exercise the live Firebase path, reads SMS codes directly from the Auth emulator's `/emulator/v1/projects/{pid}/verificationCodes` endpoint — the exact code Firebase would receive over real SMS in prod. (Filhos also has a `kDebugMode` bypass that accepts `123456` without Firebase at all — see [lib/features/login/data_sources/login_impl.dart](../lib/features/login/data_sources/login_impl.dart) — but that bypass is compile-time disabled in release builds, which is what the harness ships.)

## Two flavors, one harness

The Filhos codebase ships two apps from one source tree (`parents` and `professores`). The harness builds both:

- `flutter build web --release -t lib/main.dart --output=build/web-parents`
- `flutter build web --release -t lib/main_professores.dart --output=build/web-professores`

Each build is served on its own port (`8765` for parents, `8766` for professores) by an in-process Node static server. Playwright projects are named `<flavor>-<kind>`:

| Project | What it runs | Where the specs live |
|---|---|---|
| `parents-generated` / `professores-generated` | Generator-written specs | `tests/generated/<flavor>/<feature>/*.spec.ts` |
| `parents-snapshot` / `professores-snapshot` | Aria-snapshot goldens | `tests/snapshots/<flavor>/*.spec.ts` |

A spec selects its flavor by its directory (under `tests/generated/<flavor>/` or `tests/snapshots/<flavor>/`).

## The agentic loop

Driven by **four slash commands** at [`.claude/commands/`](.claude/commands/). They are **not subagents** — they run in the main Claude Code agent with every tool inherited (Playwright MCP, Playwright-Test MCP, Context7 MCP, Bash, Read/Edit/Write, Grep/Glob, WebSearch/WebFetch).

| Slash command | What it does |
|---|---|
| [`/pw-plan <feature>`](.claude/commands/pw-plan.md) | Explores the live app via the `playwright-test` MCP server, then writes a Markdown test plan under `specs/`. |
| [`/pw-generate <plan.md>`](.claude/commands/pw-generate.md) | Reads a plan and produces executable Playwright specs under `tests/generated/<flavor>/`. One test per file. |
| [`/pw-heal [filter]`](.claude/commands/pw-heal.md) | Runs failing tests, uses CLI trace analysis (`npx playwright trace`) and the CLI debugger (`--debug=cli`) plus `browser_snapshot` and emulator log slices to diagnose, then patches locators / assertions / timing. `test.fixme()` is the only escape hatch for real app bugs. |
| [`/pw-coverage <target>`](.claude/commands/pw-coverage.md) | The full autonomous loop. Plan → generate → heal → expand, iterating until the cross-axis matrix is filled or an external blocker requires user input. |

**Conventions every generated spec must follow** (since there is no seed file to copy from):

- Import `test`, `expect` from `../../../src/fixtures/index.js` (relative depth from `tests/generated/<flavor>/<feature>/`), **never** from `@playwright/test` directly — the fixtures barrel auto-applies `wipeAuthUsers`, `flutterDiagnostics`, and (when `PW_HAR=1`) HAR tracing.
- Drive Flutter via `app.coldStart()` / `app.goto(path)` from the `app` fixture, never `page.goto()` directly — `AppPage` handles the `<flt-semantics-placeholder>` click that mounts the semantics tree and waits for the cold-boot budget.
- Locate elements via the semantics tree: `page.getByRole`, `page.getByLabel`, `page.getByText`. No CSS selectors, no `getByTestId` (Flutter Web has neither). Pass `description:` so the trace timeline reads as narrative.
- Custom matchers from `expect`: `toHaveSemanticLabel(string|RegExp)` reads accessible names from the semantics tree. Filhos uses imperative `Navigator.push` (no GoRouter / no path strategy), so the URL stays at `/` for the entire session — assert on visible semantics, not URLs.
- `workers: 1`, `retries: 0` are correctness requirements (shared Auth-emulator user table races under concurrency). Don't propose `fullyParallel: true` as a fix.

## Per-test isolation

The fixture barrel (`src/fixtures/index.ts`) auto-applies:

1. `wipeAuthUsers()` — drops every Firebase Auth account so the OTP flow doesn't trip into "phone already in use" on re-run.
2. Playwright auto-isolates the browser context, so IndexedDB (Hive) starts empty in every test — the app sees a fresh user.

> Filhos uses Firestore for chat and diary reactions/comments (per [../CLAUDE.md](../CLAUDE.md)). If a test scenario adds Firestore to the emulator config (`playwright/firebase.json`), add a per-test Firestore reset alongside `wipeAuthUsers()` — there is no shared collection-reset helper today; collection lists are scenario-specific (chat conversations vs `diary_reactions/*` vs `diary_comments/*`), so wire it next to the spec that needs it.

## Per-test diagnostics (always on)

The `flutterDiagnostics` fixture is auto-applied to every test:

- **Per-test slice — always attached.** `flutter-run.<flavor>.window.log` and `firebase-emulators.window.log` carry only the log lines that flew while *this one spec* ran (timestamp-windowed via [`src/lifecycle/logSlicer.ts`](src/lifecycle/logSlicer.ts)). Browse them straight from the HTML report row.
- **Tail on failure — defence-in-depth.** When a test fails, the last 200 lines of both logs plus any `flutter-exceptions.txt` lines are additionally attached.
- **`browser-log.json`** (console / pageerror / requestfailed / backend 4xx-5xx) is attached every run. The `/pw-heal` slash command reads this file directly when diagnosing a failure.

> Note: `pageerror` and HTTP 5xx in the browser surface as a Playwright annotation (`browser-findings`) without flipping the spec to red — the spec's own assertions decide pass/fail.

## Process model

`global-setup.ts` orchestrates a full boot before the first spec:

```
start (or attach to) Firebase emulators  → for each flavor: build Flutter web (release/dart2js, cached against pubspec.lock + lib/ mtimes) → serve build/web-<flavor>/ from an in-process Node static server with SPA fallback → wait for port
```

**Why a static server, not `flutter run -d web-server`.** Flutter 3.41 flipped `flutter run` to DDC (dev-compiler), which only emits a working `main.dart.js` if a debugger (dwds) is attached. A headless Playwright browser is not that debugger, so `<flt-glass-pane>` never mounts and the semantics tree never appears. The static-server path serves a release `dart2js` build instead — one self-contained `main.dart.js`, no debugger handshake, identical to what we'd ship to prod. See [`src/lifecycle/flutter.ts`](src/lifecycle/flutter.ts) for the build cache + the SPA-fallback server.

`global-teardown.ts` `taskkill /T`'s the emulator process tree and closes the static servers. If you started the emulator yourself, the harness detects the open ports and runs in **attach mode** — leaves your emulator standing.

### Cross-process state sharing

`globalSetup` runs in the Playwright **runner** process; specs and fixtures run in **worker** processes. `globalThis` is per-process and doesn't cross that boundary. The harness therefore splits state by shape:

- **Live process handles** (emulator `ChildProcess`, static-server `http.Server`, log-tee ring buffers) stay on `globalThis.__e2e__` — only `globalTeardown`, also in the runner, reads them to call `stop()`.
- **Serializable paths** (log file locations) are exported via `process.env.E2E_FLUTTER_LOG_PARENTS` / `E2E_FLUTTER_LOG_PROFESSORES` / `E2E_EMULATORS_LOG`, which workers inherit. The `flutterDiagnostics` fixture slices those files by byte offset.

`workers: 1` is a hard rule because the shared Auth emulator user table races under concurrency, and `wipeAuthUsers()` between specs would clobber a parallel test's signed-in state. A future parallel mode would need to namespace Auth state per worker.

## First-time setup

```powershell
pwsh playwright\scripts\install.ps1   # npm install + chromium binary + doctor
npm --prefix playwright run doctor    # verify Node 22+, ports, Firebase CLI, Flutter
```

Requires Node 22+, Flutter 3.29.x (per `.fvmrc`), Firebase CLI, and `firebase emulators:start` to be runnable from the repo root.

## Running

> Until the first spec lands under `tests/generated/<flavor>/` or `tests/snapshots/<flavor>/`, `playwright test` exits **1 with "No tests found"** — that is the empty-scaffold state, not a failure. CI should gate on a spec count, not on a literal first-run exit code.

```powershell
# Default: both flavors, all kinds (generated + snapshot)
pwsh playwright\scripts\run.ps1

# One flavor / one kind
pwsh playwright\scripts\run.ps1 -Flavor parents -Kind generated
pwsh playwright\scripts\run.ps1 -Flavor professores -Kind snapshot

# Generator-produced specs (both flavors)
npm --prefix playwright run generated

# Just one flavor
npm --prefix playwright run generated:parents
npm --prefix playwright run generated:professores

# Aria-snapshot project (golden YAML diffs)
npm --prefix playwright run snapshot

# Open the last HTML report
npm --prefix playwright run report
```

### Driving the agent loop from Claude Code

```
/pw-plan <feature>          # explores app, writes plan to specs/<feature>.plan.md
/pw-generate specs/<plan>   # reads plan, writes specs under tests/generated/<flavor>/
/pw-heal [filter]           # runs tests, heals failures, fixme's real bugs
/pw-coverage <target>       # autonomous plan → generate → heal loop until coverage exhausted
```

These slash commands live at [`.claude/commands/`](.claude/commands/) and run in the **main Claude Code agent** with every available tool. The conventions every generated spec must follow are documented above and inside the slash-command prose — there is no seed file to copy from.

Or directly:

```powershell
cd playwright
npx playwright test --project=parents-generated
npx playwright show-report
```

## Known limitations & required patterns

The harness scaffold is wired, but every generated spec needs to follow these two patterns to be both correct and safe. Both are non-optional — pick them up the first time you write a spec.

### 1. OTP login — use the Auth emulator helpers

[`lib/features/login/data_sources/login_impl.dart:67-86`](../lib/features/login/data_sources/login_impl.dart#L67-L86) has a `kDebugMode` bypass that accepts the code `123456` without hitting Firebase. **It does not work here** — the harness builds release mode (Flutter 3.41 DDC doesn't run headless), so `kDebugMode == false` at runtime and the bypass is compile-time dead code.

**Pattern:** drive the real Auth-emulator path through the helpers in [`src/helpers/auth.ts`](src/helpers/auth.ts):

```ts
import { signInWithPhoneNumber, pollSmsCode } from '../../../src/helpers/auth.js';

// Inside a test:
const phone = '+5511999999999';
// Either: fully drive sign-in + return an idToken (skips the UI form):
const { idToken } = await signInWithPhoneNumber(phone);

// Or: let the UI initiate the OTP send (so Filhos's own form is exercised),
// then read the code the emulator minted and type it back in:
await app.semanticText('Login').click();
// …UI types phone, taps "Enviar"…
const code = await pollSmsCode(phone);
await page.keyboard.type(code);
```

The helpers already route through Playwright's `APIRequestContext`, so every emulator round-trip shows up in the trace viewer's API Requests pane.

### 2. REST calls — mock with `page.route()` until the base URL is build-time configurable

[`lib/core/utils/constants/api_const.dart:7`](../lib/core/utils/constants/api_const.dart#L7) sets `ApiConst.baseUrl` to a hard-coded `const String` (currently `https://disney.filhos.app/api/v1/`). `--dart-define` cannot override a `const` initializer, so any test that reaches login or beyond **will hit the prod backend** unless the spec intercepts.

**Pattern:** register a `page.route()` for every API surface the spec touches, using the async-disposable form so cleanup is automatic:

```ts
test('parents login lands on home', async ({ app, page }) => {
  await using _login = await page.route('**/api/v1/login', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ data: { /* UserModel shape — see lib/core/models/user_model.dart */ } }),
    });
  });
  // …drive the UI…
});
```

> ⚠️ **Do not run the suite against a real Criarte account you care about** until every spec mocks its calls. Login attempts spend FCM token quota; any test that posts data (add child, add medicine, send chat) lands in the prod database. If you want full e2e against staging instead, change `api_const.dart:7` to `static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: productionNewBaseUrl);` and pass `--dart-define=API_BASE_URL=https://beta.filhos.app/api/v1/` from [`src/lifecycle/flutter.ts#runFlutterBuild`](src/lifecycle/flutter.ts).

## Logs and diagnostics

Every run lands under `artifacts/<run-id>/`:

| Path | Contents |
|---|---|
| `artifacts/<run-id>/logs/firebase-emulators.log` | `firebase emulators:start` stdout + stderr, the full run |
| `artifacts/<run-id>/logs/flutter-run.parents.log` | Parents flavor static-server + build stdout/stderr |
| `artifacts/<run-id>/logs/flutter-run.professores.log` | Professores flavor static-server + build stdout/stderr |
| `artifacts/<run-id>/snapshot/aria-drift.md` | One section per drifted aria-snapshot (emitted by the aria-drift reporter when a `tests/snapshots/**` test fails). `/pw-heal` reads this directly. |
| `artifacts/<run-id>/playwright-report/index.html` | Per-spec timeline. Attaches `browser-log.json`, per-test `flutter-run.<flavor>.window.log` + `firebase-emulators.window.log` slices, plus the HAR when `PW_HAR=1`. |
| `artifacts/<run-id>/test-results/<spec>/trace.zip` | Playwright trace — retained on first failure. Read from the shell with `npx playwright trace open\|actions\|snapshot`. |

Screenshots and video are enabled (`screenshot: 'only-on-failure'`, `video: 'retain-on-failure'`, `trace.screenshots: true`). For a canvas-only renderer the semantics-tree YAML remains the primary signal, but pixel artefacts ride along on failures for visual correlation.

## Environment overrides

| Env var | Effect |
|---|---|
| `FLUTTER_WEB_PORT_PARENTS` | Port the parents static server binds (default `8765`) |
| `FLUTTER_WEB_PORT_PROFESSORES` | Port the professores static server binds (default `8766`) |
| `FIREBASE_AUTH_PORT` | Port the Auth emulator binds (default `9099`) |
| `FIREBASE_UI_PORT` | Port the Emulator UI binds (default `4000`) |
| `FIREBASE_PROJECT_ID` | Override the project ID (default `disney-d2bd5`, matches `firebase.json`) |
| `PW_REBUILD=1` | Force `flutter build web --release` even when `build/web-<flavor>/main.dart.js` looks fresh (bypass the pubspec.lock + lib/ mtime cache) |
| `PW_HAR=1` | Record one HAR per test under `artifacts/<runId>/test-results/<spec>/network.har`. Off by default — the existing Playwright trace already records network. |
| `PW_BASE_URL_PARENTS` | Point the harness at a parents Flutter web server already running elsewhere — globalSetup skips spawning its own static server for that flavor |
| `PW_BASE_URL_PROFESSORES` | Same, for professores |
| `E2E_VERBOSE=1` | Echo emulator + flutter stdout to the harness's own stdout for live debugging |
| `E2E_RUN_ID` | Override the run-id used for the `artifacts/<run-id>/` directory |

## Extending the harness

- **Add a new scenario:** run `/pw-plan <feature>` in Claude Code — give it the feature name or a PRD reference. Then `/pw-generate specs/<feature>.plan.md`; specs land in `tests/generated/<flavor>/`. Once stable, move them out of `generated/` to promote into the gating suite. For the full autonomous sweep, run `/pw-coverage <feature>`.
- **Change generated-test conventions:** update the "Conventions every generated spec must follow" list in this README and mirror the change in [`.claude/commands/pw-generate.md`](.claude/commands/pw-generate.md) — there is no seed file, so the agent reads conventions from prose. If a convention is load-bearing enough that you want it enforced by example, drop one canonical spec under `tests/<flavor>/<feature>/` and have generated specs copy it.
- **Need Firestore in a test?** Add a `firestore` block to [`playwright/firebase.json`](firebase.json), point the Flutter build at the emulator (`--dart-define=FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` or your Filhos equivalent), and add per-test reset logic alongside `wipeAuthUsers()` in `src/fixtures/index.ts`.
- **Need to hit the live Filhos REST API?** The harness boots Auth-only; the app's HTTP calls go to wherever its compiled `lib/core/utils/constants/api_const.dart` points (prod by default). For test-only routing, use `--dart-define=BASE_URL=...` at build time, or add a `page.route()` interceptor in the spec.

## Why Chromium-only

Flutter Web's CanvasKit renderer paints the entire UI into a single `<canvas>`. The only DOM the harness can target is the parallel **semantics tree**, which Flutter emits as `<flt-semantics aria-label="…">` elements — but only while the browser's accessibility layer is active. Chromium exposes that via `--force-renderer-accessibility` (see [`playwright.config.ts`](playwright.config.ts)); Firefox and WebKit each ship their own a11y stack that Flutter Web does not target, so the semantics tree never materialises there. Adding a `firefox` or `webkit` project would therefore produce zero locatable widgets, not broader coverage — the harness would deadlock on `enableSemantics()`.

## Trace, screenshots, and video

Trace viewer records `screenshots: true`, `snapshots: true`, `sources: true` under `retain-on-first-failure`. Page screenshots are captured `only-on-failure` and video is `retain-on-failure`. Pixel artefacts ride along on failures for visual correlation; the semantics-tree YAML and the trace timeline remain the primary signal against a canvas renderer.
