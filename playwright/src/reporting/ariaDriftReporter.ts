import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

import type {
  Reporter,
  TestCase,
  TestResult,
  FullResult,
} from '@playwright/test/reporter';

import { artifactsRoot, runId } from '../config.js';

/**
 * Emit `artifacts/<runId>/snapshot/aria-drift.md` whenever a Flutter
 * semantics-tree aria-snapshot drifts from its committed golden under
 * `tests/snapshots/*.spec.ts-snapshots/*.aria.yml`.
 *
 * Wiring (playwright.config.ts):
 *   reporter: [..., ['./src/reporting/ariaDriftReporter.ts']]
 *
 * Why a reporter and not a test hook:
 *   `toMatchAriaSnapshot()` writes its `<name>-expected.aria.yml` /
 *   `<name>-actual.aria.yml` / `<name>-diff.aria.yml` triplet onto the
 *   TestResult as attachments. Only after `onTestEnd` are all three guaranteed
 *   to exist. A `test.afterEach` would race the matcher.
 *
 * Output is one section per drifted snapshot. Diffs are inline (already a
 * unified text diff — Playwright writes the YAML diff verbatim under
 * `<name>-diff.aria.yml`). The `/pw-heal` slash command reads this file
 * directly when diagnosing snapshot drift.
 */

interface DriftEntry {
  testTitle: string;
  testFile: string;
  snapshotName: string;
  expected?: string;
  actual?: string;
  diff?: string;
}

class AriaDriftReporter implements Reporter {
  private readonly drifts: DriftEntry[] = [];

  onTestEnd(test: TestCase, result: TestResult): void {
    if (result.status !== 'failed' && result.status !== 'timedOut') return;

    // Group snapshot attachments by base name. Playwright produces the
    // attachment name via `addSuffixToFilePath(base, '-expected'|'-actual'|'-diff')`
    // ([node_modules/playwright/lib/util.js#L215](util.js)) — the suffix is
    // inserted *before* the last extension, so `welcome.aria.yml` becomes
    // `welcome.aria-expected.yml`. The reporter pairs them back with the same
    // regex Playwright's own runner uses to pair attachments in its HTML
    // report ([node_modules/playwright/lib/runner/index.js#L1509](index.js)):
    //   /^(.*)-(expected|actual|diff|previous)(\.[^.]+)?$/
    // Aligning here means we behave identically to the report when the team
    // upgrades Playwright (the regex hasn't changed since 1.10 but the canon
    // is one place — track it).
    const ATT_RE = /^(.*)-(expected|actual|diff|previous)(\.[^.]+)?$/;
    const groups = new Map<string, { expected?: string; actual?: string; diff?: string }>();

    for (const att of result.attachments) {
      if (!att.path) continue;
      const match = att.name.match(ATT_RE);
      if (!match) continue;
      const [, base, kind] = match;
      // `previous` only appears when --update-snapshots reran and produced a
      // new golden; it's not a drift signal, so we ignore it.
      if (kind === 'previous') continue;
      const group = groups.get(base) ?? {};
      try {
        if (existsSync(att.path)) {
          (group as Record<string, string>)[kind] = readFileSync(att.path, 'utf8');
        }
      } catch {
        // Unreadable attachment: skip — emitting an empty section is worse
        // than silently dropping it. The Playwright HTML report still has it.
      }
      groups.set(base, group);
    }

    for (const [name, parts] of groups) {
      // Require at least an actual file. A pure "expected" with no actual is
      // not snapshot drift; the test would have passed.
      if (!parts.actual && !parts.diff) continue;
      this.drifts.push({
        testTitle: test.title,
        testFile: test.location.file,
        snapshotName: name,
        expected: parts.expected,
        actual: parts.actual,
        diff: parts.diff,
      });
    }
  }

  async onEnd(_full: FullResult): Promise<void> {
    if (this.drifts.length === 0) return;

    const outPath = resolve(artifactsRoot, runId, 'snapshot', 'aria-drift.md');
    mkdirSync(dirname(outPath), { recursive: true });

    const lines: string[] = [];
    lines.push(`# Aria-snapshot drift — run ${runId}`);
    lines.push('');
    lines.push(
      'One or more Flutter semantics-tree aria-snapshots no longer match their committed golden. The drift is almost always a `Semantics(label:)` change on a Dart widget under `lib/features/**/presentation/**/*.dart`. Use this diff to locate the exact label that moved; the `/pw-heal` slash command reads this file directly when diagnosing snapshot drift.',
    );
    lines.push('');
    lines.push(`## TL;DR`);
    lines.push(`- Drifted snapshots: ${this.drifts.length}`);
    lines.push(`- Goldens live under: \`tests/snapshots/*.spec.ts-snapshots/<name>.aria.yml\``);
    lines.push(`- Update workflow (after fixing Dart side): \`npm run snapshot:update\``);
    lines.push('');

    this.drifts.forEach((d, i) => {
      lines.push(`## Drift ${i + 1}: ${d.snapshotName}`);
      lines.push(`- Test: ${d.testTitle}`);
      lines.push(`- Spec: ${d.testFile}`);
      lines.push('');
      if (d.diff) {
        lines.push('**Diff (expected vs actual):**');
        lines.push('```diff');
        lines.push(d.diff.trimEnd());
        lines.push('```');
        lines.push('');
      } else {
        if (d.expected) {
          lines.push('**Expected (committed golden):**');
          lines.push('```yaml');
          lines.push(d.expected.trimEnd());
          lines.push('```');
          lines.push('');
        }
        if (d.actual) {
          lines.push('**Actual (current run):**');
          lines.push('```yaml');
          lines.push(d.actual.trimEnd());
          lines.push('```');
          lines.push('');
        }
      }
    });

    lines.push('## Healer guidance');
    lines.push(
      [
        '1. Read each diff. Lines beginning with `- button "X"` -> `+ button "Y"` are a `Semantics(label: "X" -> "Y")` change. Grep for the old label in `lib/features/` to locate the widget.',
        '2. Decide whether the rename was intentional (label genuinely changed) or a regression (someone hard-coded a literal where a localisation key should have been). If intentional, update the golden via `npm run snapshot:update`; if a regression, propose a Dart-side patch as a unified diff.',
        '3. Never edit the golden YAML by hand — let `--update-snapshots` rewrite it so the file format stays canonical.',
      ].join('\n'),
    );
    lines.push('');

    writeFileSync(outPath, lines.join('\n') + '\n', 'utf8');
  }
}

export default AriaDriftReporter;
