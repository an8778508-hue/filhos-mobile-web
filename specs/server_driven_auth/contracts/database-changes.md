# Database Changes — Server-Driven Authentication

**Audience: backend team (Laravel 10 + Botble, separate repo).** This file documents the schema changes required to support the action vocabulary in [rest-endpoints.md](rest-endpoints.md). Mobile does not touch the database directly; this is here so the mobile contract is reproducible by anyone reading the spec-kit alone (master-prompt Acceptance Test for the spec-kit).

---

## 0. Open question — which `users` table?

**Before writing the migration, the backend team MUST confirm:** is the existing `users` table the one Botble's admin panel authenticates against, or is there a separate `app_users` table for mobile-app users?

The master prompt explicitly raised this: *"Botble sometimes manages its own users separately and we must not collide with admin auth."*

- If **same table** is used by both admin and the mobile API → the migration below is correct as written, but the new `status` enum and nullable password must not break the admin login (admins are created with passwords; the backfill rule preserves that).
- If a **separate `app_users` table** exists → apply the migration to `app_users` and adjust the foreign key in `password_reset_otps` accordingly.

Either way, the migration shape and the action-vocabulary semantics are unchanged.

---

## 1. `users` table — column changes

Single migration. Apply in order. Names and types target the existing Botble/Laravel conventions.

```php
Schema::table('users', function (Blueprint $table) {
    // Allow admin-created users to exist with no password yet.
    $table->string('password')->nullable()->change();

    // Replace any prior is_active boolean with an explicit lifecycle enum.
    // Values reflect the 4 states the action dispatcher branches on.
    $table->enum('status', ['create', 'pending', 'active', 'suspended'])
          ->default('create')
          ->after('password');

    // Track email verification for self-register flows.
    $table->boolean('email_verified')->default(false)->after('status');
    $table->timestamp('email_verified_at')->nullable()->after('email_verified');

    // Hot lookup paths used by check-identifier and forgot-password.
    $table->index('phone');
    $table->index('status');
});
```

### Why each column

| Column | Why |
|---|---|
| `password` made nullable | Admin-created users (Scenario 1) have `password = NULL` until they set one via `set-initial-password`. Existing rows are unaffected after the backfill (below). |
| `status` enum | Drives the action dispatcher. `create` = admin-provisioned, no password. `pending` = self-registered, awaiting approval. `active` = full access. `suspended` = blocked. |
| `email_verified` + `email_verified_at` | Self-register Scenario 2: gated until OTP verified (or set immediately when `EMAIL_OTP_ENABLED = false`). |
| `phone` index | `check-identifier` hits this on every login attempt. |
| `status` index | Admin-panel filtering + the approval-gate query. |

### Backfill rule (run as part of the migration, after the column adds)

```php
DB::table('users')
    ->whereNotNull('password')
    ->whereNull('status') // or wherever existing rows now sit
    ->update(['status' => 'active', 'email_verified' => true, 'email_verified_at' => now()]);
```

Rationale: every existing user that has a password is, by construction, a logged-in user today — so they map to `active`. Mark their email verified so they never re-enter the `VERIFY_EMAIL_OTP` flow retroactively. Run inside a transaction.

### Botble-specific guardrails (validate before merge)

- The Botble admin login uses bcrypt verification on `users.password`. With the column merely **nullable** (not removed), bcrypt verification still works for admin rows (NULL passwords cannot match any plaintext).
- If Botble has any seeders that hard-code `is_active = 1`, replace with `'status' => 'active'`.
- If Botble has admin-side scopes filtering on `is_active`, switch them to `status = 'active'` (or `status IN ('active', 'create', 'pending')` to preserve current visibility).
- If a separate `app_users` table exists, the foreign key in `password_reset_otps.user_id` MUST point at it.

---

## 2. `password_reset_otps` — new table

```php
Schema::create('password_reset_otps', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('otp_hash');                         // HMAC-SHA256(code, server_secret)
    $table->unsignedTinyInteger('attempts')->default(0); // max 5; see [security.md]
    $table->timestamp('expires_at');                    // now() + 10 min
    $table->timestamp('consumed_at')->nullable();       // single-use; set on first match
    $table->timestamps();

    $table->index(['user_id', 'consumed_at']);
});
```

### Lifecycle
1. `forgot-password` (when `EMAIL_OTP_ENABLED = true`, email found, user `active`): insert row with `attempts = 0`, `expires_at = now() + 10 min`, `consumed_at = NULL`. Replace any prior unconsumed row for the same `user_id`.
2. `verify-reset-otp`: compare `HMAC-SHA256(submitted_code)` against `otp_hash`.
   - Match → set `consumed_at = now()`, issue a `reset-password`-scoped `temp_token`, return `SET_NEW_PASSWORD`.
   - Mismatch → `attempts++`. If `attempts >= 5` → return `OTP_TOO_MANY_ATTEMPTS` and mark `consumed_at = now()` (invalidates the row). Else `OTP_INVALID`.
3. `reset-password`: consumes the `reset-password` `temp_token` (not the OTP row directly). The OTP row was already consumed at step 2.

### Why a separate table (not reuse `password_resets`)
Laravel's default `password_resets` is a link-based scheme keyed by email. This feature is **OTP-based**, attempt-tracked, scoped, and per-user. Mixing the two on one table would couple unrelated semantics; keep them separate.

### Cleanup
A scheduled job (`auth:purge-otps`) should delete rows where `consumed_at IS NOT NULL OR expires_at < now() - 24h` daily. Not blocking for v1.

---

## 3. Self-register OTP — table or column?

The master prompt focuses on `password_reset_otps`. **Registration OTPs (`VERIFY_EMAIL_OTP`) need an equivalent store.** Two acceptable shapes:

**Option A (recommended): mirror `password_reset_otps` as `email_verification_otps`.**
```php
Schema::create('email_verification_otps', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('otp_hash');
    $table->unsignedTinyInteger('attempts')->default(0);
    $table->timestamp('expires_at');
    $table->timestamp('consumed_at')->nullable();
    $table->timestamps();
    $table->index(['user_id', 'consumed_at']);
});
```
Same lifecycle as `password_reset_otps`. Same purge job.

**Option B: a single polymorphic `otp_codes(table, kind enum, user_id, ...)` table.** Cleaner long-term but expands the migration surface; defer to v1.x unless the backend team prefers it now.

Mobile is indifferent — both options produce the same wire contract.

---

## 4. `temp_token`s — storage option

`temp_token`s are short-lived (10 min), scoped (`set-password` | `reset-password`), and single-use. They are NOT JWTs and SHOULD NOT be issued by the JWT mint path. Two acceptable shapes:

**Option A: `auth_temp_tokens` table.**
```php
Schema::create('auth_temp_tokens', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('token_hash', 64)->unique();          // HMAC-SHA256(token, server_secret)
    $table->enum('scope', ['set-password', 'reset-password', 'verify-email-otp', 'verify-reset-otp']);
    $table->timestamp('expires_at');
    $table->timestamp('consumed_at')->nullable();
    $table->timestamps();
    $table->index(['token_hash', 'consumed_at']);
});
```
On issue: insert `(user_id, HMAC(token), scope, expires_at)`. The plaintext token is returned to mobile; only the hash is stored. On consume: look up by hash, check scope + expiry + `consumed_at IS NULL`, then set `consumed_at = now()`.

**Option B: Laravel cache (`Cache::store('redis')->put($key, payload, 10*60)`).** Lighter weight; acceptable if Redis is already in production. Same semantics from the mobile side.

Either way, the rules in [security.md §Temp tokens](security.md) apply.

---

## 5. Session-invalidation hook on `reset-password`

After a successful `reset-password` (Scenario 5), all existing JWTs for that user MUST stop working. Two acceptable implementations:

- **`users.token_version` column** — increment on reset; JWT middleware rejects any token whose embedded `tv` claim mismatches. Smallest change.
- **`revoked_tokens` table** — insert a row per (user_id, before_timestamp); middleware checks. Heavier; useful if you also want per-device revocation later.

Recommended: `token_version` for v1. Migration:
```php
Schema::table('users', function (Blueprint $table) {
    $table->unsignedInteger('token_version')->default(0)->after('email_verified_at');
});
```
Bump on every `reset-password` success (and optionally on a "log out everywhere" admin action later).

---

## 6. ERD delta

```
users
  + password           (was NOT NULL → NULLABLE)
  + status             ENUM('create','pending','active','suspended') DEFAULT 'create'
  + email_verified     BOOL DEFAULT false
  + email_verified_at  TIMESTAMP NULL
  + token_version      UINT DEFAULT 0     (recommended for §5)
  IDX(phone), IDX(status)

password_reset_otps    (NEW)
  id PK, user_id FK→users.id ON DELETE CASCADE
  otp_hash, attempts, expires_at, consumed_at, timestamps
  IDX(user_id, consumed_at)

email_verification_otps (NEW, recommended §3 Option A)
  identical shape to password_reset_otps

auth_temp_tokens       (NEW, §4 Option A; or use Redis)
  id PK, user_id FK→users.id
  token_hash UNIQUE, scope ENUM(...), expires_at, consumed_at, timestamps
  IDX(token_hash, consumed_at)
```

---

## 7. Pre-flight checklist (backend team)

- [ ] Confirm `users` vs `app_users` table choice and update FKs accordingly.
- [ ] Verify Botble admin login still authenticates after the migration on staging (smoke test).
- [ ] Backfill ran: every prior `password IS NOT NULL` row is now `status = 'active'`, `email_verified = true`.
- [ ] `OTP_HMAC_SECRET` + `TEMP_TOKEN_HMAC_SECRET` set in `.env` (separate secrets per concern — see [security.md]).
- [ ] Scheduled purge for OTP tables wired.
- [ ] Indices visible in `EXPLAIN` for `check-identifier`'s phone lookup.
