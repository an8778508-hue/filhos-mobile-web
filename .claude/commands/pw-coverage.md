---
description: End-to-end agentic loop — plan → generate → heal — to drive Filhos (Criarte) Playwright coverage as wide as the AI can take it
argument-hint: <feature-or-area> [optional: PRD reference, route, or "everything"]
---

> **Working directory.** This harness lives in `playwright/`. Before running any shell command or resolving any bare path in this document (`specs/…`, `tests/…`, `npm run …`, `npx playwright …`), `cd playwright` first (or prefix with `npm --prefix playwright`). Markdown links below are written workspace-root-relative for navigation and do **not** need the `cd`.

# Goal

You are the **orchestrator** of the agentic Playwright Test Agents loop on the current stable **Playwright Test** (this repo pins `^1.60.0`; confirm at runtime with `bash: npx playwright --version` and verify every API surface against Context7 `/microsoft/playwright.dev` before reaching for it — the live docs are the source of truth, not your training data). You run in the **main Claude Code agent — generic agent only**, with every tool available — **no subagents, no tool restrictions**.

Target: `$ARGUMENTS`. If empty: pick the largest uncovered surface by diffing `specs/` against `lib/features/**`.

## Agent topology (non-negotiable)

- **Generic agent only.** Do NOT spawn Claude Code subagents (`Agent({ subagent_type: ... })`). Do NOT run `npx playwright init-agents --loop=claude` — that command emits `.claude/agents/{planner,generator,healer}.md` subagent definitions which we deliberately don't use. The phases below are **stages of one main-agent loop**, not delegated subagents. The user wants every tool in the main reasoning window for maximum bandwidth and limitless generation.
- If you're tempted to delegate "for context", don't. The loop is designed to keep the whole exploration → plan → spec → trace pipeline visible to one agent.

## Loop contract

This is an **autonomous, unbounded loop**. Iterate until either:
- the user interrupts, OR
- the agent has demonstrably exhausted plausible scenarios for the target (every route hit, every form variant tested, every gate branch exercised, every cross-axis dimension covered), AND every generated spec is green or explicitly `test.fixme()`/`test.abort()`'d with a real underlying cause attached.

Do **not** stop at a self-imposed "I think that's enough" — the explicit user directive is **limitless generation and full coverage**. Stop only when the surface is exhausted or you've hit an external blocker that requires user input.

## Phases (repeat the cycle, expanding scope each iteration)

### Phase 1 — Plan
Follow [/pw-plan](.claude/commands/pw-plan.md). Emit `specs/<target>.plan.md`. On second+ iteration, **extend** the existing plan with newly-discovered cases (don't rewrite from scratch and lose prior coverage).

### Phase 2 — Generate
Follow [/pw-generate](.claude/commands/pw-generate.md) for every case in the plan that does not yet have a corresponding `tests/generated/<flavor>/<feature>/<case>.spec.ts`. Generation is per-case; do not batch into one giant spec.

### Phase 3 — Heal
Follow [/pw-heal](.claude/commands/pw-heal.md). Run all new specs. For each failure, diagnose (locator drift / timing / assertion drift / unrecoverable precondition / real bug) and patch. Promote stable specs out of `tests/generated/<flavor>/` into `tests/<flavor>/<feature>/` when they're durable.

### Phase 4 — Expand
Re-explore. Re-run `planner_setup_page` / `browser_navigate` against any feature surface the current plan doesn't yet cover, snapshot the semantics tree (`page.ariaSnapshot({ mode: 'ai', boxes: true })`), inspect `browser-log.json` and the per-test log slices from the most recent run for unaddressed `pageerror` / HTTP-5xx breadcrumbs, and read `artifacts/<runId>/snapshot/aria-drift.md` if a snapshot project failed. Add new cases to the plan, loop back to Phase 2.

## Cross-axis matrix (must be covered before the loop terminates)

| Axis | Values to hit |
|---|---|
| Flavor | parents, professores |
| Locales | `pt-BR` (default), `en-US`, `ar-SA` (RTL, Arabic semantics labels) |
| Auth state | anonymous, OTP-pending, signed-in-pending-approval (`isApproval == false` → your_account_under_review), signed-in-approved |
| Network | online, offline, slow-3G, request-failed (via `page.route()`, prefer `await using` async-disposable form) |
| Time | expired tokens, midnight rollover America/Sao_Paulo vs UTC |
| Viewport | 1280×900 default, plus mobile + tablet if the UI adapts |
| Input edges | empty / whitespace / max-length / unicode / RTL / SQL-shaped / emoji |
| File / clipboard drop | empty drop / wrong-mime-type / oversized buffer / multi-file / clipboard-only (text/plain + text/uri-list) — via `locator.drop()` |

## Tool discipline

- Use **every** tool you have. The user has explicitly authorised full tool access for this command:
  - `playwright-test/*` MCP for live in-browser work (`browser_snapshot`, `browser_click`, `browser_type`, `browser_verify_*`, `test_run`, `test_debug`, `generator_*`, `planner_*`).
  - `playwright/*` MCP for standalone browser sessions — driven by [mcp.config.json](playwright/mcp.config.json) (full caps `["core","pdf","vision","devtools"]`, isolated context, viewport/locale/timezone pinned to match `playwright.config.ts`, `saveTrace` + `saveSession` on so prior sessions are replayable, no `blockedTools`). Wired in [.mcp.json](.mcp.json). Use `browser_run_code_unsafe` when a sequence is too tangled for individual tool calls — it accepts a full Playwright script with `page` in scope.
  - **Bash for the modern CLI agent toolbox**:
    - `npx playwright trace open|actions|action <n>|snapshot <n>|close` (1.59) — shell-only trace analysis, fastest root-cause path for an agent.
    - `npx playwright test --debug=cli` (1.59) — attachable CLI debugger (`playwright-cli attach <token>`, `step-over`, `step-into`, `continue`).
    - `npm run generated`, `npm run snapshot`.
  - Read/Edit/Write for spec authoring; Grep/Glob for surveying coverage.
  - Context7 (`mcp__context7__query-docs`) for modern-API reference. Use one of the live libraries:
    - `/microsoft/playwright.dev` — primary framework docs (14k+ snippets, tracks the current stable release).
    - `/microsoft/playwright-mcp` — MCP server config, capabilities, and tool catalog.
  - WebSearch/WebFetch for app-domain reference (Brazilian school terminology, CPF/CEP, Filhos's REST API at `criarte.filhos.app`) when the README and slash-command conventions aren't enough.
- **Visual diagnostics are authorised.** `browser_take_screenshot` is enabled alongside the `vision` capability — use it when a failure is visual (canvas rendering, off-screen widget) rather than semantic. `browser_snapshot` (semantics tree) remains the primary locator-source for a Flutter Web app; screenshots are diagnostic, not the locator strategy.
- Pin locale + timezone per `playwright.config.ts` defaults (`pt-BR`, `America/Sao_Paulo`); override per-test for the en-US / ar-SA pass.

## Modern API repertoire (use these — they're why we upgraded)

| Capability | API | When to reach for it |
|---|---|---|
| **AI-mode aria snapshot** | `page.ariaSnapshot({ mode: 'ai' })` (1.60) | Address widgets unambiguously via `[ref=eN]` references; round-trips plan → generate → heal without name collisions. Default exploration snapshot. |
| Aria snapshot with bounding boxes | `page.ariaSnapshot({ boxes: true })` (1.60) | Spatial/drag scenarios, viewport-sensitive cases. Combine with `mode: 'ai'` for spatial + addressable. |
| Depth-limited aria snapshot | `page.ariaSnapshot({ depth: N })` (1.60) | Cap snapshot tree depth on huge routes so the agent stays under context budget instead of stopping exploration short. |
| Page-level aria snapshot match | `expect(page).toMatchAriaSnapshot(...)` (1.60) | Route-boundary structural assertions — no `locator(':root')` shim needed. |
| Match aria snapshot (locator) | `expect(locator).toMatchAriaSnapshot({ children: 'contain' \| 'equal' \| 'deep-equal' })` | Structural assertions against a scoped semantics subtree. YAML supports `/children` for strict matching and `/url` for link targets. |
| **File / clipboard drop** | `locator.drop({ files: [{ name, mimeType, buffer }], data: { 'text/plain': … } })` (1.60) | First-class upload-zone and paste-target simulation. Replaces hand-rolled `dragenter`/`dragover`/`drop` choreography. |
| **`getByRole` with `description`** | `getByRole(role, { description })` | Narrow by `aria-description` when role + name collide. Prefer over `nth(n)` whenever a stable description exists. |
| **HAR on tracing** | `await using har = await context.tracing.startHar('flow.har')` (1.60) | First-class HAR capture as a tracing artifact. Plan at least one HAR-recorded scenario per major flow. The async-disposable form auto-finalises on scope exit. |
| **`apiRequestContext.tracing`** (1.60) | `(await playwright.APIRequest.newContext()).tracing` | Trace API-only flows (callable testing) the same way as browser flows. |
| **`browser.on('context')`** | `browser.on('context', ctx => …)` (1.60) | Multi-context scenarios (revoke flow re-entry) — listen for new contexts at the browser level instead of polling. |
| **WebSocket route interception** | `page.routeWebSocket()` / `browserContext.routeWebSocket()` (1.59) | Intercept, modify, mock WebSocket connections — covers chat / live-update flows. |
| **`tracing.group()`** (1.59) | Group actions in the trace timeline | Wrap sub-flows (OTP → consent → activation) so they read as one block in the trace. |
| **`test.step` with timeout** | `test.step('label', async () => {…}, { timeout: N })` (1.59) | Per-step SLA enforcement; a timed-out step fails the test cleanly. |
| Abort a test cleanly | `test.abort('reason')` (1.60) | Unrecoverable precondition in a fixture/hook (emulator dead, seed crashed). |
| Async-disposable routes | `await using route = await page.route(url, handler)` | Scoped network failure injection that auto-cleans. |
| Recent-buffer inspection | `page.consoleMessages()` / `page.pageErrors()` / `page.requests()` | Read the last N events without pre-registering listeners — great inside an assertion to surface why a step failed. |
| `testConfig.failOnFlakyTests` | Project-level (1.59) | Already on in CI; the loop assumes no retries. |
| CLI trace analysis | `npx playwright trace …` (1.59) | Healer root-cause from the shell, no GUI. |
| CLI debugger | `npx playwright test --debug=cli` (1.59) | Step through a failing spec from the terminal. |

## Reporting

After each full cycle, emit a brief report:
- Cases added to the plan this cycle.
- Specs generated and where they live.
- Specs that healed clean / specs marked `test.fixme()` / specs aborted via `test.abort()` with the underlying cause.
- Surfaces still uncovered (axis × feature matrix gaps).
- New 1.60-era APIs exercised this cycle (so we know the toolbox is being used, not just available).
- Suggested next target.

Then start the next cycle without waiting for a "continue" — that's the point of an autonomous loop.

## Exit conditions

Stop and report when:
- Every feature folder under `lib/features/` has at least one passing positive and one passing negative spec for each flavor it surfaces in.
- The cross-axis matrix above is filled for every covered feature.
- At least one spec per major flow exercises each modern API in the repertoire table — specifically: `page.ariaSnapshot({ mode: 'ai' })`, `expect(page).toMatchAriaSnapshot()`, `locator.drop()` (on any feature with an upload/paste target), `getByRole({ description })` (anywhere a role + name collision exists), `tracing.startHar()` (at least one HAR-recorded scenario per major flow), `tracing.group()`, `test.abort()`, and at least one async-disposable route handler. This proves the harness is using the 1.60 toolbox rather than coasting on 1.50-era patterns.
- OR an external blocker (missing seed helper, broken emulator, ambiguous spec) needs user input.
