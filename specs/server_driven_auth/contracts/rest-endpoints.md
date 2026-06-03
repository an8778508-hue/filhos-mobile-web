# REST Contract — Server-Driven Authentication (8 endpoints)

**Audience: backend team (Laravel 10 + Botble, separate repo).** This is the authoritative wire contract the Criarte mobile app codes against. Implement these exactly; the mobile `AuthActionDispatcher` keys on the `action` strings verbatim (case-sensitive).

Base URL: `https://criarte.filhos.app/api/v1/`. All endpoints below are under `auth/`. All requests/responses are JSON.

Mobile calls every endpoint through `NetworkClient.handleRequest` → the `NetworkInterceptor` attaches `school` / `school_id` / `lang` headers automatically (these pre-login endpoints may ignore `school`/`school_id`; `lang` SHOULD be honored for OTP email language). **None of these endpoints require an `Authorization` header** — they are all pre-login.

---

## 0. Conventions

### Uniform success envelope
Every entry/step endpoint that drives navigation returns the **same envelope**:
```json
{
  "action": "<ONE_OF_THE_8_STRINGS>",
  "temp_token": "<opaque string|null>",
  "expires_in": 600,
  "user": { /* partial or full UserModel | null */ }
}
```
Endpoints that complete login (`set-initial-password`, `login`, and `verify-email-otp` when it finalizes) additionally return the existing login shape:
```json
{ "data": { /* full UserModel JSON */ }, "access_token": "eyJ..." }
```

### Uniform error envelope (all non-2xx)
```json
{ "error": { "code": "MACHINE_CODE", "message": "human readable (never shown to user)" } }
```
Mobile maps `error.code` → a localized key. It never displays `error.message`.

### Action vocabulary (the complete set; mobile handles exactly these)
| `action` | Meaning | Mobile navigation |
|---|---|---|
| `CREATE_NEW_PASSWORD` | admin-created user, password not yet set | → SetInitialPasswordScreen |
| `REQUIRE_PASSWORD` | active user, password exists | reveal inline password field (no nav) |
| `VERIFY_EMAIL_OTP` | registration OTP pending | → EmailOtpScreen |
| `GO_TO_PENDING_APPROVAL` | account awaiting admin approval | → PendingApprovalScreen |
| `VERIFY_RESET_OTP` | reset OTP pending | → ResetOtpScreen |
| `SET_NEW_PASSWORD` | reset OTP verified, set new password | → SetNewPasswordScreen |
| `NOT_FOUND` | phone not registered | inline "create account?" prompt |
| `ACCOUNT_SUSPENDED` | `status = suspended` | inline suspended error |

### Error codes (the complete set)
| `code` | HTTP | Mobile localized key |
|---|---|---|
| `VALIDATION_ERROR` | 422 | field-specific / `sda_error_generic` |
| `INVALID_CREDENTIALS` | 401 | `sda_error_invalid_credentials` |
| `ACCOUNT_SUSPENDED` | 403 | `sda_error_account_suspended` |
| `TOKEN_INVALID` | 401 | `sda_error_token_invalid` |
| `TOKEN_SCOPE_MISMATCH` | 403 | `sda_error_token_invalid` |
| `TOKEN_EXPIRED` | 401 | `sda_error_token_invalid` |
| `OTP_INVALID` | 400 | `sda_error_invalid_credentials` (generic on pin) |
| `OTP_EXPIRED` | 410 | `sda_error_otp_expired` |
| `OTP_TOO_MANY_ATTEMPTS` | 429 | `sda_error_otp_too_many` |
| `RATE_LIMITED` | 429 | `sda_error_generic` (+ Retry-After) |
| `PASSWORD_RESET_UNAVAILABLE` | 403 | `sda_error_reset_unavailable` |
| `OTP_BYPASSED` | 503 | `sda_error_generic` (should never reach mobile) |
| `EMAIL_ALREADY_REGISTERED` | 409 | `sda_error_generic` (surface on register form) |

---

## 1. `POST auth/check-identifier`

The single unified entry point. Phone → `action`.

### Request
```json
{ "phone": "11999998888", "country_code": "+55", "role": "parent" }
```
`role` is `parent` | `teacher`, derived from the app flavor.

### Responses (200 — uniform envelope)

**Admin-created, password not set** (`password IS NULL AND status = 'create'`):
```json
{
  "action": "CREATE_NEW_PASSWORD",
  "temp_token": "<set-password scope, TTL 10m>",
  "expires_in": 600,
  "user": { "id": 1, "phone": "11999998888", "email": "p***@example.com" }
}
```

**Active user with a password** (`password IS NOT NULL AND status = 'active'`):
```json
{ "action": "REQUIRE_PASSWORD" }
```

**Self-registered, email not yet verified** (`status = 'pending' AND email_verified = false`, only when `EMAIL_OTP_ENABLED = true`):
```json
{ "action": "VERIFY_EMAIL_OTP", "temp_token": "<...>", "expires_in": 600 }
```

**Awaiting admin approval** (`status = 'pending' AND email_verified = true`):
```json
{ "action": "GO_TO_PENDING_APPROVAL" }
```

**Not registered**:
```json
{ "action": "NOT_FOUND" }
```

**Suspended** (`status = 'suspended'`):
```json
{ "action": "ACCOUNT_SUSPENDED" }
```

### Backend behavior
1. Normalize `country_code` + `phone`; look up the user row.
2. No row → `NOT_FOUND`. (Return **200** with the action, **not** 404 — do not surface an HTTP error for an unknown phone; master-prompt acceptance #7.)
3. Branch on `status` + `password IS NULL` + `email_verified` per the table above.
4. For `CREATE_NEW_PASSWORD` / `VERIFY_EMAIL_OTP`, mint the appropriately-scoped `temp_token` (TTL 10 min) and include it.
5. Rate limit: 5 req/min per (IP + phone). On breach → `429 RATE_LIMITED` with `Retry-After`.

---

## 2. `POST auth/set-initial-password`

Consumes a `set-password`-scoped `temp_token`; sets the password, flips `status = 'active'`, returns the final JWT.

### Request
```json
{ "temp_token": "<set-password scope>", "password": "S3cret!!", "password_confirmation": "S3cret!!" }
```

### Response (200) — login shape
```json
{ "data": { /* full UserModel */ }, "access_token": "eyJ..." }
```

### Errors
| HTTP | `code` | When |
|---|---|---|
| 401 | `TOKEN_INVALID` | token unknown / already consumed |
| 401 | `TOKEN_EXPIRED` | token older than 10 min |
| 403 | `TOKEN_SCOPE_MISMATCH` | token scope ≠ `set-password` |
| 422 | `VALIDATION_ERROR` | password rules failed / confirmation mismatch |

### Backend behavior
1. Validate token: exists, unconsumed, unexpired, scope == `set-password`. Else error above.
2. Validate password (min 8 chars, confirmation match — align with mobile rule `sda_error_password_weak`).
3. `password = bcrypt(...)`, `status = 'active'`, consume the token (single-use).
4. Mint the standard access token (same path as `/auth/login`) and return user + token.

---

## 3. `POST auth/self-register`

Creates a `pending` user; branches on `EMAIL_OTP_ENABLED`.

### Request
```json
{
  "name": "Maria Silva",
  "phone": "11999998888",
  "country_code": "+55",
  "email": "maria@example.com",
  "password": "S3cret!!",
  "password_confirmation": "S3cret!!",
  "role": "parent"
}
```

### Response (200 — uniform envelope)

**`EMAIL_OTP_ENABLED = true` (default):**
```json
{ "action": "VERIFY_EMAIL_OTP", "temp_token": "<...>", "expires_in": 600 }
```

**`EMAIL_OTP_ENABLED = false` (bypass):**
```json
{ "action": "GO_TO_PENDING_APPROVAL" }
```

### Errors
| HTTP | `code` | When |
|---|---|---|
| 409 | `EMAIL_ALREADY_REGISTERED` | email already on a row |
| 422 | `VALIDATION_ERROR` | field validation (incl. duplicate phone) |
| 429 | `RATE_LIMITED` | > 5 req/min per (IP + phone/email) |

### Backend behavior
1. Validate; reject duplicate email/phone.
2. Create row: `password = bcrypt(...)`, `status = 'pending'`, `email_verified = false`.
3. **If `EMAIL_OTP_ENABLED = true`:** generate a 6-digit OTP, store hashed (10-min TTL), dispatch the queued Gmail-SMTP mail job, return `VERIFY_EMAIL_OTP` + a `temp_token` bound to this registration.
4. **If `EMAIL_OTP_ENABLED = false`:** set `email_verified = true`, `email_verified_at = now()`, **no OTP, no email**, return `GO_TO_PENDING_APPROVAL`; log `[WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}`.

---

## 4. `POST auth/verify-email-otp`

Verifies the registration OTP, flips `email_verified = true`.

### Request
```json
{ "temp_token": "<registration temp_token>", "code": "123456" }
```

### Response (200)
```json
{ "action": "GO_TO_PENDING_APPROVAL" }
```
*(If product later wants verified self-registered users to be auto-active, this could instead return the login shape — out of scope for v1; v1 always routes to pending approval.)*

### Errors
| HTTP | `code` | When |
|---|---|---|
| 400 | `OTP_INVALID` | hash mismatch (increment attempts) |
| 410 | `OTP_EXPIRED` | code older than 10 min |
| 429 | `OTP_TOO_MANY_ATTEMPTS` | ≥ 5 wrong attempts; invalidate code |
| 401 | `TOKEN_INVALID` / `TOKEN_EXPIRED` | bad temp_token |
| 503 | `OTP_BYPASSED` | reached while `EMAIL_OTP_ENABLED = false` (defense-in-depth; mobile should never call it then) |

---

## 5. `POST auth/login`

Standard phone + password. Only succeeds for `status = 'active'`.

### Request
```json
{ "phone": "11999998888", "country_code": "+55", "password": "S3cret!!", "role": "parent", "device_token": "<fcm token|null>" }
```

### Response (200) — login shape
```json
{ "data": { /* full UserModel */ }, "access_token": "eyJ..." }
```

### Errors
| HTTP | `code` | When |
|---|---|---|
| 401 | `INVALID_CREDENTIALS` | wrong password / no active row |
| 403 | `ACCOUNT_SUSPENDED` | `status = 'suspended'` |
| 422 | `VALIDATION_ERROR` | missing fields |
| 429 | `RATE_LIMITED` | brute-force throttle |

> This is the same `auth/login` mobile uses today, with the addition that it may now be reached after `REQUIRE_PASSWORD`. Existing fields (`device_token`, `role`) are preserved so `UserBloc.loggedIn` parsing is unchanged.

---

## 6. `POST auth/forgot-password`

Email-based reset request. Branches on `EMAIL_OTP_ENABLED`. **Never leaks whether the email exists.**

### Request
```json
{ "email": "maria@example.com" }
```

### Response (200 — uniform envelope)

**`EMAIL_OTP_ENABLED = true` AND email found AND `status = 'active'`:**
```json
{ "action": "VERIFY_RESET_OTP", "temp_token": "<reset-flow temp_token>", "expires_in": 600 }
```

**Email not found OR user not active (still `EMAIL_OTP_ENABLED = true`):**
Return the **identical shape** — `VERIFY_RESET_OTP` + a **dummy** `temp_token` that fails at `verify-reset-otp`. No email is sent. (Enumeration prevention.)

**`EMAIL_OTP_ENABLED = false`:**
```json
{ "error": { "code": "PASSWORD_RESET_UNAVAILABLE", "message": "Password reset is currently disabled. Please contact the administrator." } }
```
HTTP 403. Reset is **blocked**, never bypassed (a bypass would let anyone reset a password from just an email — a security hole). See [security.md](security.md) and [email-otp.md](email-otp.md).

### Errors
| HTTP | `code` | When |
|---|---|---|
| 403 | `PASSWORD_RESET_UNAVAILABLE` | `EMAIL_OTP_ENABLED = false` |
| 429 | `RATE_LIMITED` | > 5 req/min per (IP + email) |

### Backend behavior
1. Look up by email.
2. If `EMAIL_OTP_ENABLED = false` → `403 PASSWORD_RESET_UNAVAILABLE`.
3. If found AND active → generate reset OTP, store hashed (10-min TTL), dispatch queued Gmail-SMTP job, return `VERIFY_RESET_OTP` + temp_token.
4. If not found OR not active → return the **same** `VERIFY_RESET_OTP` shape with a dummy temp_token; send no email.

---

## 7. `POST auth/verify-reset-otp`

Verifies the reset OTP; issues a `reset-password`-scoped `temp_token`.

### Request
```json
{ "temp_token": "<reset-flow temp_token>", "code": "123456" }
```

### Response (200)
```json
{ "action": "SET_NEW_PASSWORD", "temp_token": "<reset-password scope, TTL 10m>", "expires_in": 600 }
```

### Errors
| HTTP | `code` | When |
|---|---|---|
| 400 | `OTP_INVALID` | mismatch (incl. dummy-token path) |
| 410 | `OTP_EXPIRED` | expired |
| 429 | `OTP_TOO_MANY_ATTEMPTS` | ≥ 5 attempts |
| 503 | `OTP_BYPASSED` | reached while flag off (defense-in-depth) |

---

## 8. `POST auth/reset-password`

Consumes the `reset-password`-scoped `temp_token`; updates the hash; **invalidates all existing sessions**.

### Request
```json
{ "temp_token": "<reset-password scope>", "password": "N3wSecret!", "password_confirmation": "N3wSecret!" }
```

### Response (200)
```json
{ "success": true }
```

### Errors
| HTTP | `code` | When |
|---|---|---|
| 401 | `TOKEN_INVALID` / `TOKEN_EXPIRED` | bad token |
| 403 | `TOKEN_SCOPE_MISMATCH` | scope ≠ `reset-password` |
| 422 | `VALIDATION_ERROR` | password rules / mismatch |

### Backend behavior
1. Validate token: scope == `reset-password`, unconsumed, unexpired.
2. Validate new password; `password = bcrypt(...)`.
3. **Invalidate all existing JWTs / sessions** for that user (token version bump or token-blacklist — see [security.md](security.md)).
4. Consume the token (single-use). Return `{ success: true }`.
5. Mobile then clears its navigation stack back to LoginScreen; the user logs in fresh with the new password.

---

## Mapping summary — endpoint → which scenario(s)

| Endpoint | Scenario |
|---|---|
| `check-identifier` | entry for all (1,3,4) + routes 2-pending, suspended, not-found |
| `set-initial-password` | 1 (admin first login) |
| `self-register` + `verify-email-otp` | 2 (self-registration) |
| `login` | 3, 4 (subsequent logins) |
| `forgot-password` + `verify-reset-otp` + `reset-password` | 5 (forgot password) |
