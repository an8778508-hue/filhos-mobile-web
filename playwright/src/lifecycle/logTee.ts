import { createWriteStream, mkdirSync, type WriteStream } from 'node:fs';
import { dirname } from 'node:path';
import type { Readable } from 'node:stream';

export interface LogTee {
  path: string;
  close(): void;
}

// Mirror a child process's stdout/stderr into a per-run log file. Worker-side
// fixtures slice per-test windows out of the file by byte offset (see
// `logSlicer.ts`), so an in-memory ring buffer isn't needed any more.
export function teeStreamsToFile(opts: {
  stdout: Readable | null;
  stderr: Readable | null;
  filePath: string;
  echo?: boolean;
  prefix?: string;
}): LogTee {
  const { stdout, stderr, filePath } = opts;
  const echo = opts.echo ?? false;
  const prefix = opts.prefix ?? '';

  mkdirSync(dirname(filePath), { recursive: true });
  const file: WriteStream = createWriteStream(filePath, { flags: 'a' });
  // Unhandled `'error'` events on a Writable propagate as uncaughtException
  // and crash the test runner — particularly nasty on CI hosts where a full
  // disk or revoked permission would tear down the entire suite rather than
  // skip the diagnostics layer. Log + continue: the on-disk tee becoming
  // unavailable is a degraded mode, not a fatal one.
  file.on('error', (err) => {
    console.error(`[logTee] write error on ${filePath}: ${err.message}`);
  });

  const push = (chunk: Buffer, isErr: boolean) => {
    const text = chunk.toString('utf8');
    file.write(text);
    if (echo) {
      const out = isErr ? process.stderr : process.stdout;
      out.write(prefix ? `${prefix} ${text}` : text);
    }
  };

  stdout?.on('data', (chunk: Buffer) => push(chunk, false));
  stderr?.on('data', (chunk: Buffer) => push(chunk, true));

  return {
    path: filePath,
    close() {
      file.end();
    },
  };
}
