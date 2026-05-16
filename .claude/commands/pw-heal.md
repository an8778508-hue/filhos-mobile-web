---
description: Run the Playwright suite and heal failing specs in tests/generated/ until they pass or are explicitly fixme'd
argument-hint: [optional spec path or grep filter; default = run everything]
---

> **Working directory.** This harness lives in `playwright/`. Before running any shell command or resolving any bare path in this document (`specs/…`, `tests/…`, `npm run …`, `npx playwright …`), `cd playwright` first (or prefix with `npm --prefix playwright`). Markdown links below are written workspace-root-relative for navigation and do **not** need the `cd`.

# Goal

You are the **healer phase** of the agentic Playwright Test Agents loop on the current stable **Playwright Test** (`package.json` pins `^1.60.0`; confirm at runtime with `bash: npx playwright --version` and verify any API you reach for against Context7 `/microsoft/playwright.dev` — never patch with an API you "remember"). You run in the **main Claude Code agent — generic agent only**, with full tools — every `playwright-test/*` MCP tool, the `playwright/*` MCP tool (driven by [mcp.config.json](playwright/mcp.config.json), full caps + `saveTrace`/`saveSession`, no `blockedTools` — `saveSession` means a prior MCP browser session is on disk under `playwright/artifacts/mcp/` and can be re-loaded to reproduce a failure interactively), Bash, Read/Edit/Write/Grep, Context7, WebFetch, WebSearch. **No restrictions, no subagents.**

Filter (optional): `$ARGUMENTS`. If empty, heal every failing test in the suite.

## Agent topology

- **Generic agent only.** Do NOT spawn Claude Code subagents. Do NOT run `npx playwright init-agents --loop=claude` — we don't use the canonical subagent split. Drive every diagnostic and patch directly from the main agent so the full failure context stays in one reasoning window.

## Operating contract

1. **Run the suite** with `mcp__playwright-test__test_run` (or `bash: npm run generated`). Collect every failing test.
2. **For each failure**, in isolation, in order:
   - Re-run with `mcp__playwright-test__test_debug` to pause at the failure point.
   - Inspect with `mcp__playwright-test__browser_snapshot` for the semantics tree (primary signal). `browser_take_screenshot` is available — use it when a failure is visual (rendering glitch, off-screen element) rather than semantic. Call `page.ariaSnapshot({ mode: 'ai', boxes: true })` via `browser_evaluate` to read the tree with both stable `[ref=eN]` element references **and** bounding boxes — that's the fastest path from "this locator didn't match" to "here is what the page actually contained at the moment of failure". Pair with `getByRole(role, { description })` when you can see the right element in the snapshot but its accessible name is duplicated.
   - Read `mcp__playwright-test__browser_console_messages` and `mcp__playwright-test__browser_network_requests` for error breadcrumbs. From inside the test, `page.consoleMessages()`, `page.pageErrors()`, and `page.requests()` return the most recent buffers without listening upfront.
   - **CLI trace analysis** (fastest path to root cause for an agent — reads traces from the shell, no GUI):
     - `bash: npx playwright trace open test-results/<test-id>/trace.zip`
     - `bash: npx playwright trace actions --grep="expect"` — list every action and its result
     - `bash: npx playwright trace action <n>` — drill into one action, surface the error and the before/after snapshot names
     - `bash: npx playwright trace snapshot <n> --name after` — read the page state at the moment of failure
     - `bash: npx playwright trace close` when done
   - **CLI debugger** (1.59): `bash: npx playwright test --debug=cli <spec>` opens an attachable session — `playwright-cli attach <token>`, then `step-over`, `step-into`, `continue`. Use when trace analysis alone isn't enough.
   - Cross-reference with the per-test `flutter-run.window.log` and `firebase-emulators.window.log` slices auto-attached to the HTML report, plus `browser-log.json` and (if a snapshot project failed) `artifacts/<runId>/snapshot/aria-drift.md`.
3. **Diagnose the category** before patching:
   - **Locator drift** — the semantics-tree label changed. Fix by updating to the current `getByRole`/`getByLabel`/`getByText` value. Use `mcp__playwright-test__browser_generate_locator` if uncertain. For inherently dynamic labels, use a regex.
   - **Timing** — never reach for `page.waitForTimeout`. Use `expect(locator).toBeVisible({ timeout })`, `toHaveText()`, or the harness's `waitForFlutterReady()`. Never wait for `networkidle` — it's deprecated and the Flutter Web canvas constantly chats with the engine.
   - **Assertion drift** — the expected value changed because the feature changed. Update the assertion only after confirming the new behaviour matches the **plan** under `specs/`. If the spec under `specs/` is now wrong, update the spec too (a `/pw-plan` regeneration may be cleaner).
   - **Unrecoverable precondition** — emulator unreachable, seed helper crashed, browser detached. From a fixture/hook, use `test.abort('reason')` (1.60) instead of letting the test fail mid-flow with a misleading message.
   - **Real bug** — the app is broken, not the test. Mark the test with `test.fixme()`, add a `// FIXME:` comment with the failure mode, and report it. Do not silently mutate assertions to "make it green".
4. **Patch and re-run.** Edit the spec, re-run, repeat until green. If you flip the same locator three times, you're guessing — back off and re-snapshot.
5. **Modern API discipline.** Never introduce deprecated APIs while healing. If unsure, query Context7 (`mcp__context7__query-docs` against `/microsoft/playwright.dev`) before editing. Prefer async-disposable route handlers: `await using route = await page.route(url, handler)`. Use `await using har = await context.tracing.startHar('flow.har')` if a failing scenario needs a recorded HAR for replay.
6. **Do not ask the user questions.** You're a non-interactive healer; do the most reasonable thing. The only escape hatches are `test.fixme()` with a clear comment when functionality is genuinely broken, or `test.abort()` when the harness itself is non-functional.

## Limits

- Single-worker is a correctness requirement (see `playwright.config.ts` and the README) — don't try to parallelise as a "fix".
- There is no `seed` project — conventions live in the README and pw-generate.md. If you find yourself repeatedly fixing the same locator or setup across multiple generated specs, the convention itself is probably wrong; fix it in the docs (and in any already-promoted reference spec under `tests/<flavor>/`) before patching specs one by one.
- Snapshot drift (`tests/snapshots/**`) flows through `artifacts/<runId>/snapshot/aria-drift.md`. Read it, decide whether the new aria-snapshot is intended (run `npm run snapshot:update`) or a regression (file it or fix the code).

## Deliverable

Report:
- Specs healed (with one-line "what was broken" each).
- Specs marked `test.fixme()` (with the failure mode and a TODO link if applicable).
- Specs aborted via `test.abort()` (with the precondition that failed).
- Specs the healer chose not to touch and why.
