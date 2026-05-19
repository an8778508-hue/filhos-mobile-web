# REST Contract — Email OTP Endpoints

Two new pre-login endpoints on the existing backend (`https://criarte.filhos.app/api/v1/`). Both reuse the existing `NetworkClient.handleRequest` path — the interceptor attaches `school` / `school_id` / `lang` headers automatically, which these endpoints ignore (harmless).

---

## POST `auth/email-otp/send`

Initiates the email-OTP flow. Backend generates the code, hashes it, stores the record, and writes a `mail/{autoId}` Firestore doc that the Firebase Extension picks up and dispatches via SendGrid SMTP.

### Request

**Headers** (added by `NetworkInterceptor`):
```
school: <schoolName>
school_id: <schoolId>     # both ignored by this endpoint
lang: pt | en | ar
Content-Type: application/json
```

No `Authorization` header (pre-login endpoint).

**Body**:
```json
{
  "email": "parent@example.com",
  "lang": "pt"
}
```

### Response

**Success (`200`)**:
```json
{
  "success": true,
  "masked_email": "p***@example.com",
  "retry_after": 60
}
```

`masked_email` is the **only** representation of the user's email that mobile renders on the verification screen. `retry_after` is the cooldown duration in seconds — mobile mirrors this on the local timer.

**Errors**:

| Status | `code` | Mobile behavior |
|---|---|---|
| `422` | `email_otp_not_enabled_for_school` | Surface `email_otp_error_not_enabled`; nudge user back to Telefone tab |
| `404` | `email_not_found` | Surface `email_otp_error_not_registered` |
| `429` | `already_sent` (with `Retry-After` header) | Surface `email_otp_error_too_soon` with countdown; align local timer to header value |
| `503` | `email_send_failed` | Surface `email_otp_error_send_failed`; DO NOT start cooldown (user can immediately retry) |
| `400` | `invalid_email_format` | Should not occur (mobile validates first); surface `email_otp_error_invalid_format` if it does |
| `5xx` | (other) | Surface `email_otp_error_generic` |
| Timeout (> 30 s) | — | Surface `email_otp_error_generic`; no auto-retry |

### Backend behavior

1. Look up user by email (case-insensitive). If no match → `404 email_not_found`.
2. Read user's `school_id`. Read Firestore `config/{schoolId}.email_otp_enabled`. If `false` or missing → `422 email_otp_not_enabled_for_school`.
3. Check `email_otps` table for an existing pending record for this email. If `created_at` is within the 60 s cooldown → `429 already_sent` with `Retry-After: <seconds-remaining>`.
4. Generate cryptographically-random 6-digit numeric code.
5. Compute `HMAC-SHA256(code, server_secret)`.
6. Upsert `email_otps` record:
   ```
   email_hash    = HMAC-SHA256(lowercased_email, server_secret)
   otp_hash      = HMAC-SHA256(code, server_secret)
   school_id     = <user's school>
   expires_at    = now() + 5 minutes
   attempts      = 0
   created_at    = now()
   ```
   Replace any prior pending record for the same `email_hash` (one active code per email).
7. Read Firestore `email_templates/email_otp_{lang}` (falling back to `email_otp_pt` if the requested lang doc is missing). Substitute `{{code}}`.
8. Write Firestore doc to `mail/{autoId}` (see [firestore-mail-schema.md](firestore-mail-schema.md)).
9. Return `200` with the masked email and retry-after. **Do not** await SMTP send — the extension handles delivery asynchronously.

### LGPD notes

- Server logs MUST NOT contain the plain-text email or the OTP code. Log only `email_hash`, `school_id`, status, request id.
- Audit log retention: 90 days. After 90 days, all rows for a user_id are purged. The user-initiated "Delete my account" path triggers immediate purge.

---

## POST `auth/email-otp/verify`

Verifies the 6-digit code and mints an access token identical to the SMS-OTP `/auth/login` path.

### Request

**Headers**: same as `/send`. No `Authorization`.

**Body**:
```json
{
  "email": "parent@example.com",
  "code": "123456"
}
```

### Response

**Success (`200`)** — same shape as `/auth/login`:
```json
{
  "data": {
    "id": 42,
    "name": "Maria Silva",
    "email": "parent@example.com",
    "phone": "+55...",
    "type": "parent",
    "school_id": 7,
    "is_approval": true,
    ...
  },
  "access_token": "eyJ0eXA..."
}
```

Mobile parses `data` via `UserModel.fromJson` (same as SMS OTP) and calls `UserBloc.loggedIn(user)`. The approval gate routing (`isApproval == false` → `YourAccountUnderReviewScreen`) is unchanged.

**Errors**:

| Status | `code` | Mobile behavior |
|---|---|---|
| `400` | `invalid-verification-code` | Surface generic error key on pin field; keep code in input for re-edit; **increment local attempt counter** for UX only (server enforces truth) |
| `410` | `code_expired` | Surface `email_otp_error_expired`; clear `last_email_otp_request`; unlock Send button immediately |
| `429` | `too_many_attempts` | Surface `email_otp_error_too_many_attempts`; force user back to email entry; clear pending state |
| `5xx` | (any) | Surface `email_otp_error_generic` |

### Backend behavior

1. Look up pending `email_otps` record by `email_hash`. If none → `400 invalid-verification-code` (don't leak that the email isn't registered at this stage).
2. If `expires_at < now()` → `410 code_expired`; delete the record.
3. Compute `HMAC-SHA256(submitted_code, server_secret)`. Compare to `otp_hash`.
   - **Match**: delete the record; mint access token via the existing login path; return `{data, access_token}`.
   - **Mismatch**: increment `attempts`. If `attempts >= 5` → invalidate the record + `429 too_many_attempts`. Otherwise `400 invalid-verification-code`.

### Token issuance

Uses the same token-mint path as `/auth/login`. The user is materialized with `role` derived from their persisted user record (not from any request field — the email lookup determined the user, and the user's `role` is already known server-side).

---

## Error code → localization key mapping (mobile-side)

| Backend `code` | Localization key | English fallback |
|---|---|---|
| `email_otp_not_enabled_for_school` | `email_otp_error_not_enabled` | "Your school uses phone OTP. Use the 'Phone' tab." |
| `email_not_found` | `email_otp_error_not_registered` | "No account found with this email. Check with your school." |
| `email_send_failed` | `email_otp_error_send_failed` | "Could not send right now. Try again in a few minutes." |
| `already_sent` | `email_otp_error_too_soon` | "Wait {seconds}s before requesting again." |
| `invalid_email_format` | `email_otp_error_invalid_format` | "Invalid email format." |
| `invalid-verification-code` | `otp_invalid_code` (existing) | "Invalid code. Try again." |
| `code_expired` | `email_otp_error_expired` | "Code expired. Request a new one." |
| `too_many_attempts` | `email_otp_error_too_many_attempts` | "Too many attempts. Request a new code." |
| (any other / network / 5xx) | `email_otp_error_generic` | "Could not verify right now. Try again." |
