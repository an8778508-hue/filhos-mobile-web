// Persistent static server for a release Flutter web build of Filhos.
//
// Mirrors `src/lifecycle/flutter.ts#startStaticServer` so a long-lived dev
// session (Playwright MCP visual driving + `PW_BASE_URL_<FLAVOR>` attach-mode
// runs) hits exactly the same serving semantics the harness uses:
//   - bind 127.0.0.1 only
//   - SPA fallback: extension-less paths fall back to index.html
//   - Cache-Control: no-store (a rebuild is always picked up)
//   - NO COOP/COEP headers — `credentialless` COEP makes the browser block
//     cross-origin Firebase Auth emulator responses for lack of a CORP
//     header, which silently hangs OTP calls.
//
// Usage:
//   node serve-build.mjs parents       # serves build/web-parents on 8765
//   node serve-build.mjs professores   # serves build/web-professores on 8766
//   node serve-build.mjs <flavor> 9000 # override port
import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, extname, join, resolve, sep as pathSep } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(here, '..', '..');

const flavor = process.argv[2];
if (!flavor || !['parents', 'professores'].includes(flavor)) {
  console.error('Usage: node serve-build.mjs <parents|professores> [port]');
  process.exit(2);
}

const defaultPort = flavor === 'parents' ? 8765 : 8766;
const PORT = Number(process.argv[3] ?? defaultPort);
const ROOT = resolve(projectRoot, 'build', flavor === 'parents' ? 'web-parents' : 'web-professores');
const INDEX = join(ROOT, 'index.html');

const MIME = {
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
const mimeFor = (p) => MIME[extname(p).toLowerCase()] ?? 'application/octet-stream';

if (!existsSync(INDEX)) {
  const entry = flavor === 'parents' ? 'lib/main.dart' : 'lib/main_professores.dart';
  console.error(
    `[serve-build] No build at ${ROOT} — run:\n` +
    `  flutter build web --release -t ${entry} --output=build/${flavor === 'parents' ? 'web-parents' : 'web-professores'}`,
  );
  process.exit(1);
}

const server = createServer((req, res) => {
  const rawPath = (req.url ?? '/').split('?')[0] ?? '/';
  let pathname;
  try { pathname = decodeURIComponent(rawPath); } catch { pathname = rawPath; }
  if (pathname === '/' || pathname === '') pathname = '/index.html';

  const candidate = resolve(ROOT, '.' + pathname);
  const rootWithSep = ROOT.endsWith(pathSep) ? ROOT : ROOT + pathSep;
  if (candidate !== ROOT && !candidate.startsWith(rootWithSep)) {
    res.statusCode = 403; res.end('forbidden'); return;
  }

  let toServe = candidate;
  if (!existsSync(toServe) || !statSync(toServe).isFile()) {
    if (extname(pathname) === '') toServe = INDEX;
    else { res.statusCode = 404; res.end('not found'); return; }
  }

  res.statusCode = 200;
  res.setHeader('Content-Type', mimeFor(toServe));
  res.setHeader('Cache-Control', 'no-store, must-revalidate');
  createReadStream(toServe).pipe(res);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[serve-build:${flavor}] listening on http://127.0.0.1:${PORT} (root ${ROOT})`);
});
