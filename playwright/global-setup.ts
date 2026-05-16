import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

import {
  FLAVORS,
  artifactsRoot,
  flutterAttachMode,
  hosts,
  runId,
  type Flavor,
} from './src/config.js';
import { startOrAttachEmulators, type EmulatorHandle } from './src/lifecycle/emulators.js';
import {
  startFlutterWebServer,
  type FlutterHandle,
  type FlutterHandles,
} from './src/lifecycle/flutter.js';

// Shape we persist so global-teardown.ts can find the spawned PIDs across the
// process-pool boundary. Both globalSetup and globalTeardown run in the
// Playwright runner process, so live handles (`ChildProcess`, `http.Server`)
// can travel via `globalThis`. Worker processes (specs/fixtures) only see
// `process.env` and explicit fixture values — anything they consume has to
// be serializable and exported there.
declare global {
  var __e2e__: {
    emulators: EmulatorHandle;
    flutter: FlutterHandles;
    runDir: string;
  } | undefined;
}

async function setup(): Promise<void> {
  const runDir = join(artifactsRoot, runId);
  const logsDir = join(runDir, 'logs');
  mkdirSync(logsDir, { recursive: true });
  console.log(`[setup] Run artifact dir: ${runDir}`);

  // Persist run dir so fixtures can drop per-test logs alongside.
  process.env.E2E_RUN_DIR = runDir;
  process.env.E2E_LOGS_DIR = logsDir;

  const emulators = await startOrAttachEmulators(logsDir);

  // Flutter web servers come up AFTER the emulators so the first Firestore /
  // Auth call from the app lands on a live target. Each flavor gets its own
  // static server on its own port — tests pick which one via the Playwright
  // project name.
  const flutter: FlutterHandles = {};
  for (const flavor of FLAVORS) {
    if (flutterAttachMode[flavor]) {
      console.log(
        `[flutter:${flavor}] Attach mode (${envName(flavor)}=${hosts.flutter[flavor]}) — skipping static server boot`,
      );
      continue;
    }
    flutter[flavor] = await startFlutterWebServer(flavor, logsDir);
  }

  globalThis.__e2e__ = { emulators, flutter, runDir };

  // Worker-process visibility. `globalThis` is per-process and globalSetup
  // runs in the Playwright RUNNER process, not the worker process that
  // executes specs/fixtures — so worker-side consumers can't read the
  // handles above. Export the log file PATHS via `process.env`, which IS
  // inherited by spawned workers, and worker-side helpers slice the logs
  // by byte offset (`src/lifecycle/logSlicer.ts`).
  for (const flavor of FLAVORS) {
    const handle = flutter[flavor];
    if (handle?.log?.path) {
      process.env[`E2E_FLUTTER_LOG_${flavor.toUpperCase()}`] = handle.log.path;
    }
  }
  if (emulators.log?.path) process.env.E2E_EMULATORS_LOG = emulators.log.path;

  // Attach mode (the emulator suite was already running and started
  // OUTSIDE the harness) returns a handle with `log: null` — there is no
  // harness-owned `firebase-emulators.log` to byte-slice. Signal that
  // explicitly so the worker-side `flutterDiagnostics` fixture can tell
  // "attached, nothing to slice" apart from "globalSetup crashed before
  // spawning emulators".
  if (emulators.attached) process.env.E2E_EMULATORS_ATTACHED = '1';

  // Drop a small manifest for humans and CI artifact extractors.
  writeFileSync(
    join(runDir, 'run.json'),
    JSON.stringify(
      {
        runId,
        startedAt: new Date().toISOString(),
        flutter: Object.fromEntries(
          FLAVORS.map((f) => {
            const h = flutter[f];
            return [
              f,
              h
                ? { url: h.url, logPath: h.log.path, attached: false }
                : { url: hosts.flutter[f], logPath: null, attached: true },
            ];
          }),
        ),
        emulators: {
          attached: emulators.attached,
          logPath: emulators.log?.path ?? null,
        },
      },
      null,
      2,
    ),
  );
}

function envName(flavor: Flavor): string {
  return flavor === 'parents' ? 'PW_BASE_URL_PARENTS' : 'PW_BASE_URL_PROFESSORES';
}

// Re-export so global-teardown.ts can read the same FlutterHandle shape it
// receives off `globalThis.__e2e__`.
export type { FlutterHandle };

export default setup;
