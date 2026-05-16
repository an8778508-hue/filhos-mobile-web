// File-based log slicer for callers in Playwright worker processes —
// `globalThis` state set in the runner's `globalSetup` is NOT visible to
// worker-side fixtures and specs, so any closure-based ring-buffer accessor
// would return empty from those contexts (silent-degrade bug).
//
// All operations are byte-offset based against the on-disk tee'd log file
// (which `LogTee` writes from the spawning runner process). Workers can
// trivially share offsets across the process boundary because they're
// just numbers.

import { closeSync, existsSync, openSync, readSync, statSync } from 'node:fs';

/** Returns the file's current size in bytes, or 0 if it doesn't exist yet. */
export function captureOffset(path: string | undefined): number {
  if (!path || !existsSync(path)) return 0;
  try {
    return statSync(path).size;
  } catch {
    return 0;
  }
}

/**
 * Returns the contents of `path` from `fromOffset` to the current size.
 * Empty string if the file shrank, doesn't exist, or no bytes are new.
 *
 * Uses positional `readSync` so a long-running session with a multi-MB
 * `flutter-run.log` doesn't pay O(filesize) per per-test slice — cost is
 * O(window) regardless of file size, matching `tailLines` below.
 */
export function readSlice(path: string | undefined, fromOffset: number): string {
  if (!path || !existsSync(path)) return '';
  try {
    const size = statSync(path).size;
    if (size <= fromOffset) return '';
    const window = size - fromOffset;
    const buf = Buffer.alloc(window);
    const fd = openSync(path, 'r');
    try {
      readSync(fd, buf, 0, window, fromOffset);
    } finally {
      closeSync(fd);
    }
    return buf.toString('utf8');
  } catch {
    return '';
  }
}

/**
 * Last `n` lines of the file. Reads only the trailing 256KB via positional
 * `readSync` — O(window) regardless of file size, so a multi-MB
 * `flutter-run.log` doesn't pay a full re-read on every `tail-on-failure`.
 */
export function tailLines(path: string | undefined, n = 200): string[] {
  if (!path || !existsSync(path)) return [];
  try {
    const size = statSync(path).size;
    const window = Math.min(size, 256 * 1024);
    if (window === 0) return [];
    const sliceFrom = size - window;
    const buf = Buffer.alloc(window);
    const fd = openSync(path, 'r');
    try {
      readSync(fd, buf, 0, window, sliceFrom);
    } finally {
      closeSync(fd);
    }
    const text = buf.toString('utf8');
    const lines = text.split(/\r?\n/);
    if (lines[lines.length - 1] === '') lines.pop();
    return lines.slice(-n);
  } catch {
    return [];
  }
}

/** Lines from `tailLines(path, n)` that match `pattern`. */
export function grepTail(path: string | undefined, pattern: RegExp, n = 1000): string[] {
  return tailLines(path, n).filter((l) => pattern.test(l));
}
