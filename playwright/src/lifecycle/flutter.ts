import { spawn } from 'node:child_process';
import { appendFileSync, createReadStream, existsSync, statSync, readdirSync } from 'node:fs';
import { createServer, type Server } from 'node:http';
import { extname, join, resolve, sep as pathSep } from 'node:path';

import {
  FLAVORS,
  flavorBuildDir,
  flavorEntry,
  hosts,
  ports,
  projectRoot,
  timeouts,
  type Flavor,
} from '../config.js';
import { waitForUrl } from './ports.js';
import { teeStreamsToFile, type LogTee } from './logTee.js';

// ---------------------------------------------------------------------------
// In Flutter 3.41 `flutter run -d web-server` switched to DDC (dev-compiler
// with hot reload), which only works if a debugger (dwds) is actively
// attached. A headless Playwright browser is not that debugger — so the
// page receives a `main.dart.js` shim that waits forever for a debug
// connection and `<flt-glass-pane>` is never inserted. The fix is to use
// a release-mode dart2js build (one main.dart.js, no debugger required)
// served by a tiny in-process static server. The build is cached against
// `pubspec.lock` + the mtime of `lib/`, so steady-state test runs only pay
// the static-serve cost (~milliseconds).
//
// Filhos ships two flavors from one codebase (parents + professores). Each
// gets its own build dir and static server port so a single Playwright run
// can drive both apps in series.
// ---------------------------------------------------------------------------

const isWindows = process.platform === 'win32';

export interface FlutterHandle {
  flavor: Flavor;
  url: string;
  log: LogTee;
  stop(): Promise<void>;
}

export type FlutterHandles = Partial<Record<Flavor, FlutterHandle>>;

const flavorPort: Record<Flavor, number> = {
  parents: ports.flutterParents,
  professores: ports.flutterProfessores,
};

export async function startFlutterWebServer(
  flavor: Flavor,
  logsDir: string,
): Promise<FlutterHandle> {
  const log = teeStreamsToFile({
    stdout: null,
    stderr: null,
    filePath: join(logsDir, `flutter-run.${flavor}.log`),
    echo: process.env.E2E_VERBOSE === '1',
    prefix: `[flutter:${flavor}]`,
  });

  const buildDir = flavorBuildDir[flavor];
  await ensureWebBuild(flavor, log);
  const server = await startStaticServer(buildDir, flavorPort[flavor]);
  await waitForUrl(hosts.flutter[flavor], timeouts.flutterBoot, `flutter ${flavor} static server`);

  return {
    flavor,
    url: hosts.flutter[flavor],
    log,
    stop: async () => {
      console.log(`[flutter:${flavor}] Stopping static server`);
      await new Promise<void>((res) => server.close(() => res()));
      log.close();
    },
  };
}

// ---------------------------------------------------------------------------
// Build cache
// ---------------------------------------------------------------------------

async function ensureWebBuild(flavor: Flavor, log: LogTee): Promise<void> {
  const buildDir = flavorBuildDir[flavor];
  const buildMarker = join(buildDir, 'main.dart.js');
  if (process.env.PW_REBUILD !== '1' && isBuildFresh(buildMarker)) {
    console.log(`[flutter:${flavor}] Reusing cached web build at ${buildDir}`);
    appendToLog(log, `[cache] Reusing build at ${buildDir}\n`);
    return;
  }
  console.log(
    `[flutter:${flavor}] Building Flutter web (release/dart2js, ${flavorEntry[flavor]}) — first run may take a few minutes`,
  );
  await runFlutterBuild(flavor, log);
  if (!existsSync(buildMarker)) {
    throw new Error(`Flutter build did not produce ${buildMarker}. See log for details.`);
  }
}

function isBuildFresh(buildMarker: string): boolean {
  if (!existsSync(buildMarker)) return false;
  const buildMtime = statSync(buildMarker).mtimeMs;
  const lockFile = join(projectRoot, 'pubspec.lock');
  if (!existsSync(lockFile)) return false;
  if (statSync(lockFile).mtimeMs > buildMtime) return false;
  // Recursively scan lib/ — Windows only bumps the *immediate* parent
  // directory's mtime when a file changes, so a shallow walk misses edits
  // to deeply nested files like `lib/features/.../page.dart`.
  const libDir = join(projectRoot, 'lib');
  if (existsSync(libDir) && anyFileNewerThan(libDir, buildMtime)) return false;
  return true;
}

function anyFileNewerThan(dir: string, threshold: number): boolean {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (anyFileNewerThan(p, threshold)) return true;
    } else if (entry.isFile()) {
      if (statSync(p).mtimeMs > threshold) return true;
    }
  }
  return false;
}

function runFlutterBuild(flavor: Flavor, log: LogTee): Promise<void> {
  return new Promise<void>((resolveBuild, rejectBuild) => {
    const binary = isWindows ? 'flutter.bat' : 'flutter';
    const args = [
      'build',
      'web',
      '--release',
      // The app builds icons dynamically from parsed strings
      // (lib/core/components/my_icon.dart), so IconData is non-constant and
      // icon font tree-shaking is impossible. Disable it, as Flutter advises.
      '--no-tree-shake-icons',
      '-t',
      flavorEntry[flavor],
      `--output=${flavorBuildDir[flavor]}`,
    ];
    appendToLog(log, `[build] Spawning ${binary} ${args.join(' ')}\n`);
    const proc = spawn(binary, args, {
      cwd: projectRoot,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: process.env,
      windowsHide: true,
      shell: isWindows,
    });
    proc.stdout?.on('data', (chunk: Buffer) => appendToLog(log, chunk.toString('utf8')));
    proc.stderr?.on('data', (chunk: Buffer) => appendToLog(log, chunk.toString('utf8')));
    proc.once('exit', (code) => {
      if (code === 0) resolveBuild();
      else rejectBuild(new Error(`flutter build web (${flavor}) exited with code ${code} — see ${log.path}`));
    });
    proc.once('error', rejectBuild);
  });
}

// Append a string into the LogTee. The tee only watches Readable streams,
// so we use a tiny helper that writes through the underlying file by
// re-routing through the public API. Build output flies before any test
// starts, so per-test slicing isn't relevant for it anyway.
function appendToLog(log: LogTee, text: string): void {
  try {
    appendFileSync(log.path, text);
  } catch {
    // best-effort: the build doesn't fail just because logging did
  }
}

export { FLAVORS };

// ---------------------------------------------------------------------------
// Static server with SPA fallback
// ---------------------------------------------------------------------------

const MIME: Record<string, string> = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
  '.map': 'application/json; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

function mimeFor(p: string): string {
  return MIME[extname(p).toLowerCase()] ?? 'application/octet-stream';
}

function startStaticServer(rootDir: string, port: number): Promise<Server> {
  const indexHtml = join(rootDir, 'index.html');
  return new Promise<Server>((resolveServer, rejectServer) => {
    const server = createServer((req, res) => {
      // Strip query string + decode.
      const rawPath = (req.url ?? '/').split('?')[0] ?? '/';
      let pathname: string;
      try {
        pathname = decodeURIComponent(rawPath);
      } catch {
        pathname = rawPath;
      }
      if (pathname === '/' || pathname === '') pathname = '/index.html';

      // Resolve, then guard against path traversal — only serve files under
      // rootDir. We require an explicit path-separator boundary (or exact
      // equality with rootDir for the index-html short-circuit above): plain
      // `startsWith(rootDir)` is unsafe because `rootDir = '/foo/build/web'`
      // would match a resolved candidate `/foo/build/web2/secret` (since
      // `'web'` is a string prefix of `'web2'`). A request for
      // `/../web2/secret` could otherwise escape the build dir even though
      // the harness binds 127.0.0.1 only.
      const candidate = resolve(rootDir, '.' + pathname);
      const rootWithSep = rootDir.endsWith(pathSep) ? rootDir : rootDir + pathSep;
      if (candidate !== rootDir && !candidate.startsWith(rootWithSep)) {
        res.statusCode = 403;
        res.end('forbidden');
        return;
      }

      let toServe = candidate;
      if (!existsSync(toServe) || !statSync(toServe).isFile()) {
        // SPA fallback: extensionless requests fall through to index.html so
        // the Flutter app boots regardless of which path the test landed on.
        // Filhos has no URL routing today (imperative Navigator.push, URL
        // stays at `/`); the fallback exists for forward-compat with any
        // future deep-link strategy. Requests with an obvious file extension
        // still 404 so a missing asset is visible.
        if (extname(pathname) === '') {
          toServe = indexHtml;
        } else {
          res.statusCode = 404;
          res.end('not found');
          return;
        }
      }

      res.statusCode = 200;
      res.setHeader('Content-Type', mimeFor(toServe));
      // Disable caching so a rebuild is always picked up.
      res.setHeader('Cache-Control', 'no-store, must-revalidate');
      // NOTE: do NOT set COOP/COEP here. With `credentialless` COEP the
      // browser blocks cross-origin responses that lack a CORP header,
      // which silently hangs Firebase Auth emulator calls on the Dart
      // side. Flutter Web does not require cross-origin isolation in the
      // renderer Playwright uses, so leaving these headers off is the
      // safe default for the e2e harness.
      createReadStream(toServe).pipe(res);
    });

    // Two phases: pre-listen failures reject the boot promise (EADDRINUSE
    // etc.); post-listen failures only log, because Node throws on an
    // unhandled `error` event and a static-asset blip shouldn't take the
    // whole run down.
    let listening = false;
    server.on('error', (err) => {
      if (!listening) {
        rejectServer(err);
        return;
      }
      console.error(`[flutter] static server runtime error:`, err);
    });
    server.listen(port, '127.0.0.1', () => {
      listening = true;
      console.log(`[flutter] Static server listening on http://127.0.0.1:${port} (root ${rootDir})`);
      resolveServer(server);
    });
  });
}
