#!/usr/bin/env node
// Quick environment doctor — verifies the prerequisites Playwright needs
// before globalSetup spends minutes booting the Auth emulator and building
// two Flutter web bundles only to fail at the first port wait.
//
// Run: `npm --prefix playwright run doctor`

import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { connect } from 'node:net';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
// `here` resolves to playwright/src; the project root is two levels up.
const projectRoot = join(here, '..', '..');

let failures = 0;

function probe(host, port) {
  return new Promise((resolve) => {
    const socket = connect({ host, port });
    let settled = false;
    const done = (ok) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(ok);
    };
    socket.setTimeout(400, () => done(false));
    socket.once('connect', () => done(true));
    socket.once('error', () => done(false));
  });
}

function checkBin(bin, args = ['--version']) {
  const res = spawnSync(bin, args, { stdio: 'pipe', shell: process.platform === 'win32' });
  if (res.status === 0) {
    const v = (res.stdout?.toString() ?? '').trim().split('\n')[0] ?? '';
    console.log(`  ok  ${bin}  ${v}`);
  } else {
    console.log(`  X   ${bin}  (exit ${res.status})`);
    failures++;
  }
}

console.log('Required commands:');
checkBin('node');
checkBin('npm');
checkBin('firebase');
checkBin('flutter');

console.log('\nRepo layout:');
for (const path of [
  'firebase.json',
  'pubspec.yaml',
  'lib/main.dart',
  'lib/main_professores.dart',
  'playwright/firebase.json',
  'playwright/package.json',
]) {
  const abs = join(projectRoot, path);
  if (existsSync(abs)) console.log(`  ok  ${path}`);
  else {
    console.log(`  X   ${path}  (missing)`);
    failures++;
  }
}

console.log('\nPorts (should be FREE before first run; busy means attach mode):');
for (const port of [4000, 9099, 8765, 8766]) {
  const busy = await probe('127.0.0.1', port);
  console.log(`  ${busy ? 'busy' : 'free'}  ${port}`);
}

if (failures > 0) {
  console.error(`\n${failures} doctor check(s) failed.`);
  process.exit(1);
}
console.log('\nDoctor: OK');
