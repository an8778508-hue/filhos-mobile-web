import { connect } from 'node:net';

export function tcpProbe(host: string, port: number, timeoutMs = 500): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = connect({ host, port });
    let settled = false;
    const done = (ok: boolean) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(timeoutMs, () => done(false));
    socket.once('connect', () => done(true));
    socket.once('error', () => done(false));
  });
}

export async function waitForPort(
  host: string,
  port: number,
  timeoutMs: number,
  label: string,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await tcpProbe(host, port)) return;
    await sleep(500);
  }
  throw new Error(`Timed out waiting for ${label} on ${host}:${port} (${timeoutMs}ms)`);
}

export async function waitForUrl(url: string, timeoutMs: number, label: string): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  let lastError: unknown;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url, { method: 'GET' });
      // Accept any response — Flutter's web-server returns 200 with the host
      // page once it's ready; the Emulator UI returns 200 on /.
      if (res.status < 500) return;
      lastError = new Error(`HTTP ${res.status}`);
    } catch (err) {
      lastError = err;
    }
    await sleep(500);
  }
  throw new Error(`Timed out waiting for ${label} at ${url} (${timeoutMs}ms): ${String(lastError)}`);
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
