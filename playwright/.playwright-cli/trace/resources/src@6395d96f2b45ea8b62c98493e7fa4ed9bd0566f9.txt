// Auth-emulator admin shortcut: wipe every user account so a re-run of the
// OTP flow doesn't trip into "phone already in use" on the second pass.
// Companion to the Auth helpers in `auth.ts` (which sign individual users in).

import { hosts, projectId } from '../config.js';
import { getApi } from './_apiContext.js';

export async function wipeAuthUsers(): Promise<void> {
  // The Auth emulator's bulk-delete endpoint returns 200 on success. A 4xx/5xx
  // here means stale users will survive into the next test — throw so per-test
  // setup fails loudly instead of leaking state silently.
  const res = await getApi().fetch(
    `http://${hosts.auth}/emulator/v1/projects/${projectId}/accounts`,
    { method: 'DELETE' },
  );
  if (!res.ok()) {
    throw new Error(
      `wipeAuthUsers failed: HTTP ${res.status()} ${await res.text()}`,
    );
  }
}
