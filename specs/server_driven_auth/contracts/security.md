# Security — Server-Driven Authentication

**Audience: backend team (Laravel 10 + Botble, separate repo).** This file is the single source for the auth-security invariants. Mobile defends in depth (rate-limit awareness in UX, redaction in Crashlytics, single-source token storage), but every rule here is **server-enforced**. None of the mobile-side defenses are sufficient on their own.

---

## 1. Rate limiting

Pre-login endpoints attract enumeration, brute force, and OTP-spam. Required limits:

| Endpoint | Limit | Bucket key | On breach |
|---|---|---|---|
| `auth/check-identifier` | **5 req / min** | `IP + phone` | `429 RATE_LIMITED` + `Retry-After` |
| `auth/self-register` | **5 req / min** | `IP + (phone or email)` | `429 RATE_LIMITED` + `Retry-After` |
| `auth/forgot-password` | **5 req / min** | `IP + email` | `429 RATE_LIMITED` + `Retry-After` |
| `auth/login` | **5 failed / min, 20 failed / hour** | `IP + phone` | `429 RATE_LIMITED` (don't reveal which limit) |
| `auth/verify-email-otp` | **10 req / min** | `temp_token` | `429 RATE_LIMITED` (separate from OTP attempt counter) |
| `auth/verify-reset-otp` | **10 req / min** | `temp_token` | `429 RATE_LIMITED` |
| `auth/set-initial-password`, `auth/reset-password` | **10 req / min** | `temp_token` | `429 RATE_LIMITED` |

Implement via Laravel's `RateLimiter::for(...)` in a service provider; keys hashed (don't put raw phone/email in the limiter cache key — use `hash('xxh3', $key)`).

---

## 2. `temp_token`s — scoped, single-use, short-lived

`temp_token`s are the only auth state that lives between two consecutive REST calls in a sub-flow. They are NOT JWTs, NOT bearer tokens, NOT persisted by mobile.

| Property | Rule |
|---|---|
| Format | 256-bit cryptographically random URL-safe base64 (`random_bytes(32)`) |
| Storage | Server stores `HMAC-SHA256(token, server_secret)` — never plaintext |
| TTL | **10 minutes** (`expires_at`) |
| Single-use | `consumed_at` is set on first successful consumption; second presentation returns `TOKEN_INVALID` |
| Scope | One of: `set-password`, `reset-password`, `verify-email-otp` (registration), `verify-reset-otp` (reset flow) |
| Scope enforcement | Each endpoint accepts **only** its scope. Wrong scope → `403 TOKEN_SCOPE_MISMATCH`. A `set-password` token presented to `reset-password` is a hard error. |
| Issuance | Returned in the uniform envelope on entry/step responses |
| Secret | `TEMP_TOKEN_HMAC_SECRET` in `.env`, ≥ 32 bytes |

> **Cross-scope misuse is the single most important rule in this file.** A registration-flow OTP-verify token MUST NOT let the holder reset another user's password, and vice versa.

---

## 3. OTP rules

| Property | Rule |
|---|---|
| Length | **6 digits, numeric** |
| Generation | `random_int(0, 999999)` zero-padded — **not** `mt_rand`, **not** `Math.random`-equivalent |
| TTL | **10 minutes** |
| Storage | `HMAC-SHA256(code, server_secret)` in `password_reset_otps.otp_hash` / `email_verification_otps.otp_hash` |
| Max attempts | **5** wrong attempts per OTP row → record is invalidated (`consumed_at = now()`) and `OTP_TOO_MANY_ATTEMPTS` returned |
| Re-issuance | A new `forgot-password` / `self-register` resend replaces any prior unconsumed OTP row for the same user (one active code per user per flow) |
| Secret | `OTP_HMAC_SECRET` in `.env`, ≥ 32 bytes, **different** from `TEMP_TOKEN_HMAC_SECRET` |
| Delivery | Queued Gmail-SMTP job (`ShouldQueue`) — see [email-otp.md](email-otp.md) |

---

## 4. Session invalidation on password reset

On successful `auth/reset-password`:

1. Consume the `reset-password` `temp_token`.
2. **Invalidate every existing JWT/session** for that user (master-prompt acceptance #6).
3. Return `{ success: true }`.

Two acceptable implementations (see [database-changes.md §5](database-changes.md)):
- **`users.token_version` bump** — JWT middleware rejects tokens whose `tv` claim ≠ row's `token_version`. Recommended for v1.
- **`revoked_tokens` table** — middleware checks per request.

The mobile interceptor already routes 401 → forced logout (`UserBloc.loggedOut()`), so any device holding a stale token reaches LoginScreen on its next request. **The current device** that just completed the reset MUST also be considered logged out — mobile clears the stack and goes to LoginScreen on success, asking the user to log in with the new password.

This applies **only** to `reset-password`. `set-initial-password` does NOT invalidate sessions (the user had none).

---

## 5. Enumeration prevention

Three pre-login surfaces leak existence if implemented naively. Each has an explicit rule:

| Surface | Rule |
|---|---|
| `check-identifier` (unknown phone) | Return `200 { action: "NOT_FOUND" }`. **Not** `404`. The HTTP status carries no information about existence. |
| `forgot-password` (unknown / non-active email) | Return the **same shape** as success — `{ action: "VERIFY_RESET_OTP", temp_token, expires_in }` — with a **dummy temp_token** that fails at `verify-reset-otp`. Send no email. Same response time as the success path (introduce a small synthetic delay if the real path is meaningfully slower). |
| `self-register` (existing email) | Return `409 EMAIL_ALREADY_REGISTERED`. **Exception to the rule** — this is registration; the user is explicitly trying to claim an identifier and benefits from clear feedback. (Already an accepted UX leak.) |

Backend log discipline: never log raw phone / email / code; log hashes + the rate-limiter bucket id (see §7).

---

## 6. Password rules

- Min length: **8 characters**. Mobile enforces this client-side (`sda_error_password_weak`); backend enforces it **again** in `VALIDATION_ERROR`.
- No max length below 72 chars (bcrypt limit). Document the limit if hit.
- No specific complexity rule for v1 (no "must contain a symbol"). Length + bcrypt cost ≥ 12 is sufficient.
- Hash: `bcrypt` (Laravel default). Cost factor in `config/hashing.php` ≥ **12**.
- Reject the most-common 10k passwords (optional but cheap — `zxcvbn` or the `pwned-passwords` k-anonymity API).
- Same rules for `set-initial-password`, `self-register`, and `reset-password`.

---

## 7. Logging & PII

| Field | Allowed in logs | How |
|---|---|---|
| Phone (E.164) | ❌ | log `hash('xxh3', $phone)` |
| Email | ❌ | log `hash('xxh3', strtolower($email))` |
| Password (any form) | ❌ never | n/a |
| OTP code | ❌ never | n/a |
| `temp_token` | ❌ never (even hashed; the hash is the storage key) | n/a |
| `action` string | ✅ | as-is |
| `user_id` | ✅ | as-is |
| Rate-limiter bucket | ✅ (already hashed) | as-is |

Crashlytics on the mobile side mirrors this via the `network_client` redaction allowlist — extend it to cover `auth/check-identifier`, `auth/self-register`, `auth/login`, `auth/set-initial-password`, `auth/forgot-password`, `auth/verify-email-otp`, `auth/verify-reset-otp`, `auth/reset-password`. Same pattern used for `auth/email-otp/*` per `email_otp` FR-EM-18.

---

## 8. `EMAIL_OTP_ENABLED` — security implications of the flag

Documented exhaustively in [email-otp.md §The flag](email-otp.md). Summary here for the security audit:

| Flow | Flag `true` (default, production) | Flag `false` (dev/QA only) |
|---|---|---|
| Self-register | OTP enforced. Email proven before account is `email_verified`. | **Bypassed.** Account created with `email_verified = true` without proof of email ownership. **Acceptable** in dev/QA where no real users exist. |
| Forgot password | OTP enforced. Reset only proceeds after correct OTP entry. | **Blocked.** Server returns `403 PASSWORD_RESET_UNAVAILABLE`. **Reset is never bypassed** — letting it through would mean anyone who knows an email can reset that account's password. |

Rules around the flag (also enforced in [email-otp.md]):
1. Flag value source: `config('auth.email_otp_enabled')`. NOT `env()` directly in business logic (config caching).
2. Production guard: `auth:check-config` artisan command warns if `APP_ENV=production AND email_otp_enabled = false`.
3. Audit log: `[WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}` on every affected request.
4. `verify-email-otp` / `verify-reset-otp` return `503 OTP_BYPASSED` if reached while the flag is off — defense in depth, mobile should never call them then.

Security risk acknowledged: setting `EMAIL_OTP_ENABLED=false` weakens email-proof for new registrations. This is **acceptable in dev/QA only**. In production the flag MUST be `true`.

---

## 9. Bcrypt cost & timing

- Bcrypt cost ≥ 12 makes login + set-password meaningfully expensive. Pair with the per-IP+phone rate limiter in §1 to bound brute force.
- Login should **not** short-circuit on "user not found" — always run a dummy bcrypt comparison of an arbitrary string against a known hash so the timing distribution of `INVALID_CREDENTIALS` doesn't reveal whether the phone exists. (Combined with `check-identifier`'s `NOT_FOUND` return, this closes the timing channel.)

---

## 10. HTTPS / transport

- All eight endpoints MUST be HTTPS only. HSTS already set on `criarte.filhos.app`.
- No auth field (phone, email, password, code, temp_token) is permitted in a query string. Bodies only.
- CORS: pre-login endpoints are called from the mobile app's `dio` client (no browser origin), so the existing CORS policy is unchanged.

---

## 11. Headers

The mobile interceptor attaches `Authorization` only when the user is logged in. The pre-login auth endpoints do not require it — but **MUST NOT accept it** either (ignore if present; do not trust). The `school` / `school_id` / `lang` headers are advisory and only `lang` is honored (for OTP email language).

---

## 12. Acceptance checks (auditor-facing)

- [ ] All 8 endpoints HTTPS-only, no auth field in URLs.
- [ ] Rate limits in §1 implemented and tested.
- [ ] `temp_token`s scoped, single-use, 10-min TTL, HMAC-hashed at rest.
- [ ] OTPs 6-digit, 10-min TTL, ≤ 5 attempts, HMAC-hashed at rest.
- [ ] `reset-password` invalidates all prior sessions (token_version bump verified).
- [ ] `check-identifier` returns `200 NOT_FOUND` for unknown phones; `forgot-password` returns identical shape regardless of email existence.
- [ ] Server logs spot-checked: no plaintext phone / email / code / temp_token.
- [ ] `EMAIL_OTP_ENABLED = false` is rejected by `auth:check-config` in `APP_ENV=production`.
- [ ] Login does a dummy bcrypt on unknown phone (constant-time non-existence).
- [ ] Bcrypt cost ≥ 12.
