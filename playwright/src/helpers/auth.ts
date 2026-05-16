import { expect } from '@playwright/test';

import { hosts, projectId } from '../config.js';
import { getApi } from './_apiContext.js';

export interface EmulatorUser {
  uid: string;
  idToken: string;
  phoneNumber: string;
}

/**
 * Sign in with a phone number via the Firebase Auth emulator's REST endpoints.
 * Uses the emulator's "skip reCAPTCHA" shortcut (the emulator accepts any
 * non-empty `recaptchaToken`).
 *
 * Returns an ID token whose `phone_number` claim is set. Useful for seeding
 * an authenticated Firebase user when a test needs to bypass the Filhos
 * login screen (e.g. when chat / diary scenarios need a user already
 * authenticated against the Auth emulator).
 */
export async function signInWithPhoneNumber(phoneE164: string): Promise<EmulatorUser> {
  const apiKey = 'integration-test';
  const session = await postJson(
    `http://${hosts.auth}/identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=${apiKey}`,
    { phoneNumber: phoneE164, recaptchaToken: 'emulator-test-recaptcha' },
  );
  const sessionInfo = required(session.sessionInfo, 'sessionInfo');

  const code = await pollSmsCode(phoneE164);

  const signIn = await postJson(
    `http://${hosts.auth}/identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=${apiKey}`,
    { sessionInfo, code },
  );

  return {
    uid: required(signIn.localId, 'localId'),
    idToken: required(signIn.idToken, 'idToken'),
    phoneNumber: phoneE164,
  };
}

/**
 * Read back the SMS code the Auth emulator minted for `phoneE164`. The
 * emulator buffers verification codes per project; we walk the list newest
 * first and pick the most recent code for our phone.
 *
 * Note: Filhos has a `kDebugMode` OTP bypass in
 * `lib/features/login/data_sources/login_impl.dart` that accepts `123456`
 * without Firebase at all. That bypass is compile-time disabled in release
 * builds (which is what this harness ships), so this helper is the path
 * for getting a real Auth emulator code in a release-build test.
 *
 * Uses `expect.poll` so the wait surfaces as a step in the trace viewer
 * and the failure mode is a normal assertion in the HTML report.
 */
export async function pollSmsCode(phoneE164: string, timeoutMs = 20_000): Promise<string> {
  let code: string | undefined;
  // Diagnostic state captured on every probe so the timeout error can pinpoint
  // *why* the code was not found: bad HTTP status, empty list, or the phones
  // present-but-not-matching our filter.
  let lastStatus: number | undefined;
  let lastCount = 0;
  let lastPhones: string[] = [];
  try {
    await expect
      .poll(
        async () => {
          const res = await getApi().fetch(
            `http://${hosts.auth}/emulator/v1/projects/${projectId}/verificationCodes`,
          );
          lastStatus = res.status();
          if (!res.ok()) return undefined;
          const body = (await res.json()) as {
            verificationCodes?: Array<{ phoneNumber?: string; code?: string }>;
          };
          const all = body.verificationCodes ?? [];
          lastCount = all.length;
          lastPhones = Array.from(
            new Set(all.map((c) => c.phoneNumber).filter((p): p is string => !!p)),
          );
          const latest = all
            .filter((c) => c.phoneNumber === phoneE164 && typeof c.code === 'string')
            .at(-1);
          code = latest?.code;
          return code;
        },
        {
          message: `Auth emulator SMS code for ${phoneE164}`,
          timeout: timeoutMs,
          intervals: [100, 250, 500, 1_000],
        },
      )
      .toBeDefined();
  } catch (e) {
    const detail =
      `(HTTP ${lastStatus ?? 'n/a'}, ${lastCount} code(s)` +
      (lastPhones.length > 0 ? `, phones=[${lastPhones.join(', ')}]` : '') +
      ')';
    if (e instanceof Error) {
      e.message = `${e.message} ${detail}`;
    }
    throw e;
  }
  return code as string;
}

async function postJson(url: string, body: unknown): Promise<Record<string, string>> {
  const res = await getApi().fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    data: body,
  });
  if (!res.ok()) {
    throw new Error(`POST ${url} failed: HTTP ${res.status()} ${await res.text()}`);
  }
  return (await res.json()) as Record<string, string>;
}

function required<T>(v: T | undefined | null, name: string): T {
  if (v == null) throw new Error(`Auth emulator response missing field: ${name}`);
  return v;
}
