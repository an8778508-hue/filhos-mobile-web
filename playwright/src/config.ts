import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// `here` is playwright/src/. The Flutter project root sits one directory above
// playwright/, i.e. two levels up from here.
const here = dirname(fileURLToPath(import.meta.url));

const playwrightRoot = resolve(here, '..');                // playwright/
export const projectRoot = resolve(here, '..', '..');      // repo root (Flutter project root)
export const artifactsRoot = resolve(playwrightRoot, 'artifacts');

// Where the playwright-local emulator config lives. Kept separate from the
// project's top-level firebase.json (which configures hosting + flutter
// platforms for prod) so test infra never bleeds into release config.
export const emulatorFirebaseJson = resolve(playwrightRoot, 'firebase.json');

// Per-test HAR (HTTP Archive) output. Lands one HAR per test under
// `artifactsRoot/<runId>/test-results/<spec>/network.har` when `PW_HAR=1`
// (off by default — `tracing.startHar()` doubles the per-test artifact
// footprint, and the existing trace already records network).
export const harEnabled = process.env.PW_HAR === '1';

// Filhos Firebase project ID (from `firebase.json` at repo root). The Auth
// emulator buffers verification codes per project ID, so this must match what
// the running Flutter app uses or the OTP helper finds no codes.
export const projectId = process.env.FIREBASE_PROJECT_ID ?? 'disney-d2bd5';

// Flutter flavors. Both must build separately because they have different
// entry points (lib/main.dart vs lib/main_professores.dart) and the app
// branches on `context.isParents` / `context.isProfessors` extensions at
// runtime.
export type Flavor = 'parents' | 'professores';
export const FLAVORS: readonly Flavor[] = ['parents', 'professores'] as const;

export const flavorEntry: Record<Flavor, string> = {
  parents: 'lib/main.dart',
  professores: 'lib/main_professores.dart',
};

// Per-flavor build output dir. Two `flutter build web` invocations with
// `--output=<dir>` so the static server can serve them on different ports.
export const flavorBuildDir: Record<Flavor, string> = {
  parents: resolve(projectRoot, 'build', 'web-parents'),
  professores: resolve(projectRoot, 'build', 'web-professores'),
};

// `PW_BASE_URL_<FLAVOR>` lets a developer point the harness at a Flutter web
// server they already have running (e.g. `flutter run -d chrome` in another
// shell). When set, globalSetup skips spawning its own static server for that
// flavor and Playwright's `baseURL` resolves to this value. Trailing slash is
// stripped so `${hosts.flutter[flavor]}/foo` doesn't double up. Treat an
// empty string the same as unset.
function attachBaseUrl(flavor: Flavor): string | undefined {
  const envVar = flavor === 'parents' ? 'PW_BASE_URL_PARENTS' : 'PW_BASE_URL_PROFESSORES';
  return process.env[envVar]?.replace(/\/$/, '') || undefined;
}

export const ports = {
  auth: Number(process.env.FIREBASE_AUTH_PORT ?? 9099),
  emulatorUi: Number(process.env.FIREBASE_UI_PORT ?? 4000),
  flutterParents: Number(process.env.FLUTTER_WEB_PORT_PARENTS ?? 8765),
  flutterProfessores: Number(process.env.FLUTTER_WEB_PORT_PROFESSORES ?? 8766),
} as const;

export const hosts = {
  auth: `127.0.0.1:${ports.auth}`,
  flutter: {
    parents: attachBaseUrl('parents') ?? `http://127.0.0.1:${ports.flutterParents}`,
    professores: attachBaseUrl('professores') ?? `http://127.0.0.1:${ports.flutterProfessores}`,
  },
} as const;

export const flutterAttachMode: Record<Flavor, boolean> = {
  parents: attachBaseUrl('parents') !== undefined,
  professores: attachBaseUrl('professores') !== undefined,
};

export const timeouts = {
  emulatorBoot: 120_000,
  flutterBoot: 240_000,
  navigation: 30_000,
  semanticsEnable: 15_000,
} as const;

// Run identifier used to scope artifact directories so reruns don't collide.
export const runId =
  process.env.E2E_RUN_ID ??
  new Date().toISOString().replace(/[:.]/g, '-');
