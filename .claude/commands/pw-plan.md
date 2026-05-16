---
description: Explore the Filhos (Criarte) Flutter web build via Playwright MCP and emit a Markdown test plan into specs/
argument-hint: <feature-or-area-to-plan> [optional path or PRD reference]
---

> **Working directory.** This harness lives in `playwright/`. Before running any shell command or resolving any bare path in this document (`specs/…`, `tests/…`, `npm run …`, `npx playwright …`), `cd playwright` first (or prefix with `npm --prefix playwright`). Markdown links below are written workspace-root-relative for navigation and do **not** need the `cd`.

# Goal

You are the **planner phase** of an agentic Playwright Test Agents loop on the current stable **Playwright Test** (this repo pins `@playwright/test ^1.60.0`; confirm at runtime with `bash: npx playwright --version` and verify the API surface against Context7 `/microsoft/playwright.dev` — never reason from memory). You run in the **main Claude Code agent — generic agent only, no subagents, no tool restrictions**. The user has explicitly authorised full tool access. Every tool you have is in scope:

- The entire `playwright-test/*` MCP server (planner / generator / healer / browser / test / network / storage tools — exposed by `npx playwright run-test-mcp-server`).
- The `playwright/*` MCP server, driven by [mcp.config.json](playwright/mcp.config.json) — full capability set `["core","pdf","vision","devtools"]`, isolated context, viewport/locale/timezone pinned to match `playwright.config.ts`, `saveTrace` + `saveSession` on for replayability, no `blockedTools`. The server is wired in [.mcp.json](.mcp.json).
- Context7 docs (`mcp__context7__query-docs` against `/microsoft/playwright.dev` for the framework, `/microsoft/playwright-mcp` for MCP-specific behaviour) — mandatory before reaching for any modern API.
- `WebSearch`, `WebFetch`, Bash, Read, Edit, Write, Grep, Glob — whatever helps produce **maximum coverage**.

Target: **`$ARGUMENTS`** (if empty, plan coverage for whatever feature surface is currently most under-tested under [tests/generated/](playwright/tests/generated/) for both flavors — parents at `http://127.0.0.1:8765` and professores at `http://127.0.0.1:8766`).

## Agent topology (read before touching anything)

- **Generic agent only.** Do NOT spawn Claude Code subagents (`Agent({ subagent_type: ... })`). Do NOT run `npx playwright init-agents --loop=claude` — that command emits `.claude/agents/{planner,generator,healer}.md` subagent definitions with hard-restricted tool lists that we deliberately don't use. The phases here (`/pw-plan`, `/pw-generate`, `/pw-heal`, `/pw-coverage`) are **stages of one main-agent loop**, not delegated subagents. The user wants every tool in the main context for maximum reasoning bandwidth and limitless generation.
- If you find yourself wanting to delegate to a subagent, **don't**. Drive the work directly from the main agent.

## Operating contract

1. **Boot the page once.** Call `mcp__playwright-test__planner_setup_page` (or `mcp__playwright-test__browser_navigate` if `planner_setup_page` isn't available) to land on the live app. Read the **"Conventions every generated spec must follow"** section in [playwright/README.md](playwright/README.md) and the convention block at the top of [pw-generate.md](.claude/commands/pw-generate.md) before planning, so the scenarios you emit round-trip through the generator without convention drift. There is no `tests/seed.spec.ts` — the scaffold ships empty.
2. **Explore aggressively.** Use `browser_snapshot` to read the semantics tree — primary signal for a Flutter Web canvas app. `browser_take_screenshot` is also authorised (the `vision` capability is enabled); use it for visual receipts when a scenario hinges on rendering, never as the primary locator source. When you need to *address* specific widgets unambiguously, call `page.ariaSnapshot({ mode: 'ai' })` via `browser_evaluate` — the AI-mode snapshot returns stable `[ref=eN]` element references that round-trip cleanly into generator steps. Add `{ boxes: true }` when spatial hints matter (drag/drop, viewport-sensitive); add `{ depth: N }` when the tree is huge so the snapshot stays under context budget. Walk every screen, click every actionable element, fill every form. When you need a signed-in Firebase user to reach a post-login surface, drive `signInWithPhoneNumber` / `pollSmsCode` from [playwright/src/helpers/auth.ts](playwright/src/helpers/auth.ts) against the Auth emulator.
3. **Generate scenarios *without ceiling*.** Emit every positive path, every negative variant, every edge condition, every boundary (empty / max-length / unicode / RTL / DST / network failure / clock skew / force-close / offline). Coverage grows on demand.
4. **Cover every cross-axis dimension** explicitly:
   - Flavors (parents, professores — Filhos ships two apps from one codebase; many screens render differently)
   - Locales (`pt-BR` default, `en-US`, `ar-SA` — pin via `test.use({ locale })`)
   - Network conditions (online, offline, slow-3G, request-failed via `page.route()`)
   - Auth states (anonymous, OTP-pending, signed-in-pending-approval, signed-in-approved)
   - Time conditions (expired tokens, midnight rollover America/Sao_Paulo vs UTC)
   - Device viewports (default 1280×900, plus mobile + tablet if the UI adapts)
5. **Write the plan** to `specs/<feature>.plan.md` (kebab-case). Structure:
   - `# <Feature> Test Plan` heading
   - `## Application Overview`
   - `## Test Scenarios` with numbered groups (`### 1. Posting a Diary Entry`) and sub-cases (`#### 1.1 Post Valid Entry` …)
   - Each case lists **Steps:** (numbered, imperative, semantics-tree-friendly) and **Expected Results:** (assertion-ready, no pixel references). If a case needs pre-test state setup beyond the auto-applied `wipeAuthUsers` fixture (e.g. a signed-in Firebase user via `signInWithPhoneNumber` from [playwright/src/helpers/auth.ts](playwright/src/helpers/auth.ts), or a `page.route()` mock of the Filhos REST API), call it out under a **Setup:** sub-heading so the generator wires it correctly.
6. **Cite Context7 when unsure** about modern Playwright APIs — `mcp__context7__query-docs` against `/microsoft/playwright.dev` is the live docs library. Never propose deprecated APIs (no `waitForNavigation`, no `networkidle`, no `page.waitForLoadState('networkidle')`, no `page.waitForTimeout`).
7. **Quality bar.** Steps must be specific enough that the generator phase can execute them mechanically. Avoid prose like "verify the page looks right" — write `Verify the heading "Welcome" is visible and the button "Continue" is enabled.`

## Modern Playwright APIs the planner should design around

| Capability | API | When to plan a case around it |
|---|---|---|
| **AI-mode aria snapshot** | `page.ariaSnapshot({ mode: 'ai' })` (1.60) | Default exploration snapshot. Returns `[ref=eN]` references so a plan can address a specific widget unambiguously through plan → generate → heal. |
| Aria snapshot with bounding boxes | `page.ariaSnapshot({ boxes: true })` (1.60) | Spatial / drag scenarios, viewport-sensitive cases. Combine with `mode: 'ai'` for addressable spatial plans. |
| Depth-limited aria snapshot | `page.ariaSnapshot({ depth: N })` (1.60) | Cap snapshot depth on huge routes so the agent stays under context budget instead of stopping exploration short. |
| Page-level aria snapshot match | `expect(page).toMatchAriaSnapshot(...)` (1.60) | Route-boundary structural assertions — no `locator(':root')` shim needed. |
| Aria snapshot `/children` + `/url` | `toMatchAriaSnapshot` with `/children: equal\|contain\|deep-equal` and `/url` | Strict subtree matching and link target assertions inside YAML goldens. |
| **File / clipboard drop** | `locator.drop({ files: [{ name, mimeType, buffer }], data })` (1.60) | First-class upload-zone and paste-target simulation. Replaces hand-rolled `dragenter`/`dragover`/`drop` choreography. |
| **`getByRole` with `description`** | `getByRole(role, { description })` | Narrow by `aria-description` when role + name collide. Prefer over `nth(n)` whenever a stable description exists. |
| **HAR on tracing** | `await using har = await context.tracing.startHar('flow.har')` (1.60) | First-class HAR capture as a tracing artifact. Plan at least one HAR-recorded scenario per major flow — invaluable for offline-mode and slow-3G cases. The async-disposable form auto-finalises on scope exit. |
| **`apiRequestContext.tracing`** (1.60) | `apiRequest.newContext()` then read `.tracing` | Trace API-only flows (callable testing) the same way as browser flows. |
| **`browser.on('context')`** | `browser.on('context', ctx => …)` (1.60) | Multi-context scenarios (revoke flow re-entry) — listen for new contexts at the browser level instead of polling. |
| **`test.abort('reason')`** | (1.60) | Plan a clean abort path for unrecoverable preconditions (emulator unreachable, seed helper failed) — beats a misleading mid-flow failure. |
| **WebSocket route interception** | `page.routeWebSocket()` / `browserContext.routeWebSocket()` (1.59) | Plan scenarios for any feature that uses WebSockets (chat, live updates). |
| **`tracing.group()`** (1.59) | Group actions in trace timeline | Use it inside scenarios where a sub-flow (OTP → consent → activation) should read as one block in the trace. |
| **`test.step` with timeout** | `await test.step('label', async () => { … }, { timeout: 1_000 })` (1.59) | Plan tight per-step budgets when a step has a contractual SLA. |
| **`testConfig.failOnFlakyTests`** | Project-level (1.59) | Already on in CI — plan scenarios assuming there are no retries. |
| **Recent-buffer inspection** | `page.consoleMessages()` / `page.pageErrors()` / `page.requests()` | Read the last N events inside an assertion to surface why a step failed, without pre-registering listeners. |
| **Async-disposable routes** | `await using route = await page.route(url, handler)` | Scoped network failure injection that auto-cleans on test exit. |
| **CLI trace analysis** | `npx playwright trace open\|actions\|action <n>\|snapshot <n>\|close` (1.59) | Plan diagnostics that read traces from the shell with no GUI. |
| **CLI debugger** | `npx playwright test --debug=cli` → `playwright-cli attach <token>` (1.59) | Plan diagnostic paths that step through a failing spec from the terminal. |

## Anti-patterns (do not produce)

- A scenario-count "limit" like "10 cases per feature". The ceiling is `feature-completeness`, not a number.
- Pixel-based assertions, screenshot diffs, or `getByTestId` — this is a Flutter Web semantics-tree app; locators are `getByRole` / `getByLabel` / `getByText`.
- Skipping the Filhos REST API mock on the happy path. The app's `ApiConst.baseUrl` is a hard-coded `const` pointing at the prod backend ([lib/core/utils/constants/api_const.dart](lib/core/utils/constants/api_const.dart)), so any unmocked test that reaches login or beyond will hit production. Every spec must `page.route('**/api/v1/**', …)` on the relevant endpoints — see README §"Known limitations & required patterns" for the canonical shape. Firebase Auth itself is genuinely emulated; the REST API is not.
- Speculative scenarios with no real failure mode. Each case must correspond to either a discovered finding (live `browser_snapshot` + `browser_console_messages` + `browser_network_requests` from the current planning session, or `browser-log.json` from a prior run) or a real branch in the app's BLoC / repository / router logic.
- Subagent delegation. Drive directly from the main agent.

## Deliverable

Save the plan with `Write` to `specs/<feature>.plan.md` and print the path to the user. The next step in the loop is `/pw-generate <plan-path>` per case (or `/pw-coverage` for the full sweep).
