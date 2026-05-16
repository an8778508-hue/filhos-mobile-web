import { spawn, type ChildProcess } from 'node:child_process';
import { join } from 'node:path';

import { emulatorFirebaseJson, hosts, projectId, projectRoot, ports, timeouts } from '../config.js';
import { killProcessTree } from './procTree.js';
import { tcpProbe, waitForPort, waitForUrl } from './ports.js';
import { teeStreamsToFile, type LogTee } from './logTee.js';

const isWindows = process.platform === 'win32';

export interface EmulatorHandle {
  attached: boolean;
  proc: ChildProcess | null;
  log: LogTee | null;
  stop(): Promise<void>;
}

async function allPortsBound(): Promise<boolean> {
  const probes = await Promise.all([
    tcpProbe('127.0.0.1', ports.emulatorUi),
    tcpProbe('127.0.0.1', ports.auth),
  ]);
  return probes.every(Boolean);
}

async function emulatorUiResponding(): Promise<boolean> {
  try {
    const res = await fetch(`http://127.0.0.1:${ports.emulatorUi}/`);
    const body = await res.text();
    return res.ok && /Firebase/i.test(body);
  } catch {
    return false;
  }
}

/**
 * Start the Firebase emulator suite (Auth-only by default per
 * `playwright/firebase.json`), or attach to one that is already running on
 * the harness ports. The harness only needs Auth — the Filhos backend is a
 * REST API at `criarte.filhos.app`, not Cloud Functions — and Auth is what
 * the phone-OTP flow round-trips against. Add `firestore` / `storage` /
 * `functions` blocks to `playwright/firebase.json` if a test needs them.
 */
export async function startOrAttachEmulators(logsDir: string): Promise<EmulatorHandle> {
  if (await allPortsBound()) {
    if (await emulatorUiResponding()) {
      console.log(`[emulators] Attach mode: existing suite on ${ports.emulatorUi}/${ports.auth}.`);
      return {
        attached: true,
        proc: null,
        log: null,
        stop: async () => {
          // We didn't spawn this — leave it alone.
        },
      };
    }
    throw new Error(
      `Emulator ports are bound but the Emulator UI did not respond as Firebase. ` +
        `Stop whatever holds ${ports.emulatorUi}/${ports.auth} before re-running.`,
    );
  }

  const binary = isWindows ? 'firebase.cmd' : 'firebase';
  console.log(`[emulators] Spawning firebase emulators:start --config ${emulatorFirebaseJson}`);
  // Node 20+/Windows refuses to spawn `.cmd`/`.bat` files without `shell: true`
  // (CVE-2024-27980 hardening — `spawn EINVAL` otherwise). taskkill /T in
  // killProcessTree still walks the cmd.exe → firebase → java tree.
  const proc = spawn(
    binary,
    ['emulators:start', '--config', emulatorFirebaseJson, '--project', projectId],
    {
      cwd: projectRoot,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: {
        ...process.env,
        GCLOUD_PROJECT: projectId,
      },
      windowsHide: false,
      detached: !isWindows,
      shell: isWindows,
    },
  );

  const log = teeStreamsToFile({
    stdout: proc.stdout,
    stderr: proc.stderr,
    filePath: join(logsDir, 'firebase-emulators.log'),
    echo: process.env.E2E_VERBOSE === '1',
    prefix: '[emu]',
  });

  proc.once('exit', (code, signal) => {
    log.close();
    console.log(`[emulators] exited code=${code} signal=${signal}`);
  });

  await waitForPort('127.0.0.1', ports.auth, timeouts.emulatorBoot, 'auth emulator');
  await waitForPort('127.0.0.1', ports.emulatorUi, timeouts.emulatorBoot, 'emulator UI');
  await waitForUrl(
    `http://${hosts.auth}/`,
    timeouts.emulatorBoot,
    'auth emulator host page',
  );
  await waitForUrl(
    `http://127.0.0.1:${ports.emulatorUi}/`,
    timeouts.emulatorBoot,
    'emulator UI host page',
  );

  return {
    attached: false,
    proc,
    log,
    stop: async () => {
      console.log('[emulators] Stopping emulator process tree');
      await killProcessTree(proc.pid);
      log.close();
    },
  };
}
