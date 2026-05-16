import { spawnSync } from 'node:child_process';

const isWindows = process.platform === 'win32';

// On Windows the Firebase CLI and the Flutter tool both spawn child processes
// (java for the emulator JARs, dart for the dev server). A naive `proc.kill()`
// only ends the top-level shim and leaves ports 5001/8080/9099/8765 bound, so
// the next run dies in port-wait. Mirror what scripts/dev-up.ps1 does and
// terminate the entire tree via taskkill /T /F.
export async function killProcessTree(pid: number | undefined): Promise<void> {
  if (pid == null) return;
  try {
    if (isWindows) {
      spawnSync('taskkill', ['/PID', String(pid), '/T', '/F'], {
        stdio: 'ignore',
        windowsHide: true,
      });
      return;
    }
    // Send SIGTERM to the process group, then wait briefly and SIGKILL the
    // stragglers. The earlier `setTimeout(...).unref()` form was lost if the
    // parent exited fast (Playwright teardown calls this and returns
    // immediately) — the unref'd timer dies with the process and the child
    // survives. Awaiting an in-line poll loop ties the kill to teardown
    // completion so callers can guarantee port release before the next run.
    try {
      process.kill(-pid, 'SIGTERM');
    } catch {
      // ignore
    }
    const deadline = Date.now() + 2_000;
    while (Date.now() < deadline) {
      try {
        // Signal 0 doesn't deliver — just probes existence. Throws ESRCH
        // once the process group is gone, which is our success signal.
        process.kill(-pid, 0);
      } catch {
        return;
      }
      await new Promise((r) => setTimeout(r, 100));
    }
    try {
      process.kill(-pid, 'SIGKILL');
    } catch {
      // ignore — gone between the poll and the kill
    }
  } catch {
    // best-effort; nothing else to do if the OS refuses
  }
}
