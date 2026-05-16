---
description: Generate executable Playwright spec(s) from a plan in specs/, following the harness conventions
argument-hint: <path-to-plan.md> [optional: case-id like 1.2, default = all cases]
---

> **Working directory.** This harness lives in `playwright/`. Before running any shell command or resolving any bare path in this document (`specs/…`, `tests/…`, `npm run …`, `npx playwright …`), `cd playwright` first (or prefix with `npm --prefix playwright`). Markdown links below are written workspace-root-relative for navigation and do **not** need the `cd`.

# Goal

You are the **generator phase** of the agentic Playwright Test Agents loop on the current stable **Playwright Test** (`package.json` pins `^1.60.0`; confirm at runtime with `bash: npx playwright --version` and verify every API against Context7 `/microsoft/playwright.dev` before emitting it — the live docs are the source of truth, not your training data). You run in the **main Claude Code agent — generic agent only**, with full tool access — every `playwright-test/*` MCP tool, every `playwright/*` MCP tool (driven by [mcp.config.json](playwright/mcp.config.json), full caps + `saveTrace`/`saveSession`, no `blockedTools`), Read/Edit/Write/Bash/Grep, Context7, WebFetch, WebSearch. **No restrictions, no subagents.**

Input: `$ARGUMENTS` — a plan file under `specs/` and optionally a specific case-id. If empty, locate the most recently written plan under `specs/` and generate every case in it that does not yet have a corresponding spec under `tests/generated/`.

## Agent topology

- **Generic agent only.** Do NOT spawn Claude Code subagents (no `Agent({ subagent_type })`). Do NOT run `npx playwright init-agents --loop=claude` — we don't use the canonical subagent split. This phase is one step in the main-agent loop; keep all reasoning and tool calls in the main context for maximum bandwidth.

## Operating contract

1. **Read the conventions first.** The "Conventions every generated spec must follow" list in [playwright/README.md](playwright/README.md) and the convention block here at §1.a below are the contract — there is no seed file. Generated specs that violate either are broken even if they pass.

   **§1.a Convention block (every generated spec MUST follow):**
   - Import `test`, `expect` from `../../../src/fixtures/index.js` (depth from `tests/generated/<flavor>/<feature>/`). Never from `@playwright/test` directly — the fixtures barrel auto-applies `wipeAuthUsers`, `flutterDiagnostics`, and HAR tracing (under `PW_HAR=1`).
   - Use the `app` fixture for boot: `await app.coldStart()` (lands at `/`, waits for the engine and the semantics tree to mount). Never `page.goto()` directly. Filhos has no URL-driven routing (imperative `Navigator.push`, URL stays at `/`), so `app.goto('/some/path')` is decorative — drive in-app navigation by tapping the relevant semantic widget.
   - Locate via the semantics tree: `page.getByRole`, `page.getByLabel`, `page.getByText`. Pass `description:` so the trace timeline reads as narrative. Never CSS, never `getByTestId`, never pixel positions.
   - Custom matchers: `expect(loc).toHaveSemanticLabel(string|RegExp)`. Don't assert on URL — the URL stays at `/` for the entire session; assert on visible semantics instead.
   - OTP login MUST drive the Auth-emulator path via [playwright/src/helpers/auth.ts](playwright/src/helpers/auth.ts) — `signInWithPhoneNumber('+5511…')` or `pollSmsCode(phone)`. The `kDebugMode` `123456` bypass in the app is compile-time dead in release builds.
   - Any spec that reaches login or beyond MUST mock the Filhos REST API via `await using r = await page.route('**/api/v1/<endpoint>', …)` — `ApiConst.baseUrl` is hard-coded to prod and `--dart-define` cannot override a `const`.
2. **Read the plan.** Parse the case list under `## Test Scenarios`. For each case:
   - Open the page via `mcp__playwright-test__generator_setup_page` (lands on the live app at the flavor's base URL).
   - Execute every step from the plan's **Steps:** section against the live app using the MCP browser tools (`browser_click`, `browser_type`, `browser_press_key`, `browser_select_option`, `browser_wait_for`, etc.). Use the plan step text as the **intent** annotation for each tool call — the generator log records intents and turns them into spec comments.
   - For each **Expected Result:**, call the matching verify tool: `browser_verify_element_visible`, `browser_verify_text_visible`, `browser_verify_list_visible`, `browser_verify_value`.
   - After all steps, retrieve the generator log via `mcp__playwright-test__generator_read_log` and emit the spec via `mcp__playwright-test__generator_write_test`.
3. **Spec file conventions** (the generator MCP tool enforces most of these; verify):
   - One test per file.
   - File path: `tests/generated/<flavor>/<feature-slug>/<kebab-case-scenario>.spec.ts` where `<flavor>` is `parents` or `professores` (specs are filtered into the matching Playwright project by directory).
   - Header comments: `// spec: specs/<plan-name>.md` and `// conventions: see playwright/README.md "Conventions every generated spec must follow"`.
   - `test.describe('<plan group name without ordinal>', () => { test('<scenario name without ordinal>', async ({ page }) => { ... }); });`
   - Each step in the body is preceded by a `// <step text>` comment.
   - Locators: `getByRole`, `getByLabel`, `getByText` — never CSS selectors, never `getByTestId` (Flutter Web has no testids), never pixel positions.
   - Imports: pull `test` and `expect` from the fixtures barrel (`../../../src/fixtures/index.ts` from a `tests/generated/<flavor>/<feature>/` spec), **not** from `@playwright/test` directly. The fixtures barrel auto-applies `wipeAuthUsers` and `flutterDiagnostics`.
   - For dynamic data (timestamps, generated phone numbers), use regex locators or derive values inline — never hard-code identifiers that would collide on re-run.
4. **Modern APIs only (Playwright 1.60).** Allowed:
   - `expect(locator).toBeVisible({ timeout })`, `toHaveText()`, `toHaveValue()` — web-first auto-retry assertions.
   - `expect(locator).toMatchAriaSnapshot({ children: 'contain' | 'equal' | 'deep-equal' })` for accessibility-tree assertions on a locator. The YAML form supports `/url` for link target assertions.
   - `expect(page).toMatchAriaSnapshot(...)` (1.60) for **page-level** structural assertions — no more `locator(':root')` shim. Prefer this at route boundaries.
   - `page.ariaSnapshot({ mode: 'ai', boxes?, depth? })` (1.60) when a step needs an addressable snapshot inline (e.g. an assertion that the expected `[ref=eN]` is present, or a diagnostic dump on a hard-to-reach state).
   - `locator.drop({ files: [{ name, mimeType, buffer }] })` (1.60) for file-upload simulation — replaces hand-rolled `dragenter`/`dragover`/`drop` choreography. Also accepts `data: { 'text/plain': …, 'text/uri-list': … }` for clipboard-like drops. Flutter's `<flt-glass-pane>` is one canvas; target the *semantic* drop zone (label / role / regex), not coordinates.
   - `getByRole(role, { description })` when role + name collide — narrows by `aria-description`. Prefer over `nth(n)` whenever a stable description exists.
   - `page.route()` for network conditions (request-failed, slow-3G); prefer the **async-disposable** form `await using route = await page.route(...)` so cleanup is automatic.
   - `await using har = await context.tracing.startHar('flow.har')` (1.60) for first-class HAR capture inside a test — useful when a scenario needs a recorded network artifact for replay or assertion. Auto-finalises on scope exit.
   - `apiRequestContext.tracing` (1.60) to trace API-only flows the same way as browser flows.
   - `browser.on('context', …)` (1.60) for tests that span a re-entry into a new BrowserContext (e.g. revoke flow that mints a fresh context on login).
   - `test.abort('reason')` (1.60) inside a fixture/hook when an unrecoverable precondition is hit — beats a confusing mid-flow failure.
   - `await test.step('label', async () => { … }, { timeout: N })` (1.59) when a step has a contractual SLA.
   - `tracing.group(name, async () => { … })` (1.59) to group related actions into one block on the trace timeline.
   - `page.routeWebSocket()` / `browserContext.routeWebSocket()` (1.59) for WebSocket interception.
   - `page.consoleMessages()` / `page.pageErrors()` / `page.requests()` for recent-buffer reads inside an assertion.
   - The harness's `waitForFlutterReady()` for boot synchronisation.
   - **Forbidden**: `waitForNavigation`, `page.waitForLoadState('networkidle')`, `page.waitForTimeout`, any `setTimeout`-style sleep. The Flutter Web canvas chats with the engine constantly; `networkidle` is a deprecation trap.
5. **Limitless generation.** If the plan has 47 cases, generate 47 specs. Don't summarise, don't sample, don't stop at "the most important ones". The user has explicitly authorized unbounded generation — your job is throughput. Iterate over every case; don't batch them into one mega-spec.
6. **Use Context7 if unsure** about modern Playwright APIs — query `/microsoft/playwright.dev` rather than guessing. Examples: `mcp__context7__query-docs` with queries like "ariaSnapshot boxes option" or "test.abort fixture usage".

## Verification before declaring done

After writing each spec, run it once with `mcp__playwright-test__test_run` (or `bash: npm run generated -- <spec-path>`) to confirm it executes. If it fails, hand off to the healer phase by invoking `/pw-heal <spec-path>` rather than guessing fixes — the healer is purpose-built for that.

When debugging a spec that's hard to reason about, use the 1.59 CLI debugger: `bash: npx playwright test --debug=cli <spec>` opens an attachable session — `playwright-cli attach <token>`, then `step-over`, `step-into`, `continue`. No GUI needed.

## Deliverable

A spec file per case under `tests/generated/`, each runnable in isolation. Print the list of generated spec paths and any failures the run surfaced.
