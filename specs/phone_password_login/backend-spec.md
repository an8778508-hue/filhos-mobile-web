# Backend Specification: Phone + Password Login

**For**: Backend team | **Date**: 2026-05-20 | **Mobile branch**: `Nour_main`

This document is the **complete backend contract**. Mobile will code against these exact request/response shapes. Any deviation should be communicated before implementation.

---

## Overview

Replace Firebase SMS OTP as the primary auth method with **phone + password**. The existing `/auth/login` (Firebase phone-verified) and `/auth/login-with-email` endpoints remain untouched. New endpoints are added alongside them.

### What mobile sends today vs. what it will send

| Flow | Today | After this feature |
|------|-------|--------------------|
| Primary login | Firebase phone auth → `POST /auth/login { phone, country_code, firebase_id_token }` | `POST /auth/phone-login { phone, country_code, password }` |
| Email+password | `POST /auth/login-with-email { email, password }` | **Unchanged** |
| Social login | `POST /auth/social-login { token, provider }` | **Unchanged** |
| Email OTP | `POST /auth/email-otp/send` + `/verify` | **Unchanged** |

---

## Database Changes

### Migration: `users` table

```sql
ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) NULL;
ALTER TABLE users ADD COLUMN must_set_password BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT FALSE;
```

**For existing users:**
- Users who already have a password (from `/auth/login-with-email` flow): set `must_set_password = false`, copy existing password hash to `password_hash` if stored differently.
- Users who only used SMS OTP (no password): set `must_set_password = true`, `password_hash = NULL`.
- All existing users: set `email_verified = false` (or `true` if you have prior email verification data).

---

## New Endpoints

### 1. `POST /auth/phone-login`

**Purpose**: Primary login for both parent and teacher apps. Replaces Firebase SMS OTP as the default login method.

**Request:**
```
POST /api/v1/auth/phone-login
Content-Type: application/json
school: <schoolId>              ← existing interceptor header (ignored by this endpoint pre-login)
```

```json
{
  "phone": "+5511999990000",
  "country_code": "BR",
  "role": "parent",
  "password": "userpassword123",
  "device_token": "fcm_device_token"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `phone` | string | YES | Full international format with `+` prefix |
| `country_code` | string | YES | ISO 3166-1 alpha-2 (e.g., `BR`, `EG`) |
| `role` | string | YES | `"parent"` or `"teacher"` |
| `password` | string | NO | Empty/omitted for first-login of admin-created users |
| `device_token` | string | NO | FCM token for push notifications |

**Backend logic:**

```
1. Find user by phone + country_code + role
   → NOT FOUND: return 404 { "message": "user_not_found" }

2. Check user.password_hash:

   a) password_hash IS NULL (admin-created, never set password):
      → Login succeeds WITHOUT password
      → Generate access token (same as /auth/login)
      → Save device_token if provided
      → Return 200 with must_set_password: true

   b) password_hash IS NOT NULL AND request.password IS EMPTY:
      → Return 422 { "message": "password_required" }

   c) password_hash IS NOT NULL AND request.password IS PROVIDED:
      → bcrypt_verify(request.password, user.password_hash)
      → MATCH: Generate access token, return 200 with must_set_password: user.must_set_password
      → MISMATCH: Return 401 { "message": "invalid_password" }
        → Optional: increment failed_attempts counter. If >= 5 → return 423 { "message": "account_locked" }

3. On success: run the same Auth::login($user) flow as /auth/login
   (token generation, last_login update, etc.)
```

**Success response (user has no password — first login):**
```json
{
  "data": {
    "id": 42,
    "name": "Maria Silva",
    "email": "maria@example.com",
    "phone": "+5511999990000",
    "type": "parent",
    "school_id": 7,
    "is_approval": true,
    "must_set_password": true,
    "email_verified": false
  },
  "access_token": "eyJ0eXAiOiJKV1Q..."
}
```

**Success response (password verified):**
```json
{
  "data": {
    "id": 42,
    "name": "Maria Silva",
    "email": "maria@example.com",
    "phone": "+5511999990000",
    "type": "parent",
    "school_id": 7,
    "is_approval": true,
    "must_set_password": false,
    "email_verified": true
  },
  "access_token": "eyJ0eXAiOiJKV1Q..."
}
```

**Error responses:**

| Status | Body | When |
|--------|------|------|
| 404 | `{ "message": "user_not_found" }` | No user matches phone + country_code + role |
| 401 | `{ "message": "invalid_password" }` | Password provided but doesn't match hash |
| 422 | `{ "message": "password_required" }` | User has a password set but request omitted it |
| 423 | `{ "message": "account_locked" }` | Too many failed attempts (optional) |

---

### 2. `POST /auth/set-password` (authenticated)

**Purpose**: First-time password creation for admin-created users. Called immediately after first login.

**Request:**
```
POST /api/v1/auth/set-password
Content-Type: application/json
Authorization: Bearer <access_token>
```

```json
{
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Backend logic:**
```
1. Authenticate via Bearer token
2. Check user.must_set_password == true
   → If false: return 403 { "message": "password_already_set" }
     (forces users to use /auth/change-password instead)
3. Validate password: min 6 characters, confirmation matches
4. Hash with bcrypt, store in password_hash
5. Set must_set_password = false
6. Return 200
```

**Success response:**
```json
{
  "success": true,
  "message": "password_set_successfully"
}
```

**Errors:**

| Status | Body | When |
|--------|------|------|
| 401 | `{ "message": "Unauthorized" }` | Invalid/expired token |
| 403 | `{ "message": "password_already_set" }` | User already has a password (use change-password) |
| 422 | `{ "message": "password_too_short" }` | Less than 6 characters |
| 422 | `{ "message": "passwords_dont_match" }` | password ≠ password_confirmation |

---

### 3. `POST /auth/change-password` (authenticated)

**Purpose**: User changes their existing password from Settings.

**Request:**
```
POST /api/v1/auth/change-password
Content-Type: application/json
Authorization: Bearer <access_token>
```

```json
{
  "current_password": "oldpassword",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Backend logic:**
```
1. Authenticate via Bearer token
2. bcrypt_verify(current_password, user.password_hash)
   → MISMATCH: return 401
3. Validate new password: min 6 chars, confirmation matches
4. Hash new password, update password_hash
5. Return 200
```

**Success response:**
```json
{
  "success": true,
  "message": "password_changed_successfully"
}
```

**Errors:**

| Status | Body | When |
|--------|------|------|
| 401 | `{ "message": "current_password_incorrect" }` | Current password wrong |
| 422 | `{ "message": "password_too_short" }` | Less than 6 characters |
| 422 | `{ "message": "passwords_dont_match" }` | Confirmation mismatch |

---

### 4. `POST /auth/reset-password`

**Purpose**: Password reset via email OTP. Called from "Forgot password?" flow. **Not authenticated** — user doesn't have a valid session.

**Prerequisite**: User has already called `POST /auth/email-otp/send` and received the OTP code in their email.

**Request:**
```
POST /api/v1/auth/reset-password
Content-Type: application/json
```

```json
{
  "email": "parent@example.com",
  "code": "123456",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Backend logic:**
```
1. Verify OTP code against email_otps table (same logic as /auth/email-otp/verify)
   → Invalid/expired/too many attempts: return same errors as /auth/email-otp/verify
2. Look up user by email
3. Validate new password: min 6 chars, confirmation matches
4. Hash password, update password_hash
5. Set must_set_password = false
6. Delete the email_otps record (code consumed)
7. Return 200
```

**Success response:**
```json
{
  "success": true,
  "message": "password_reset_successfully"
}
```

**Errors:** Same as `/auth/email-otp/verify` for code validation, plus:

| Status | Body | When |
|--------|------|------|
| 422 | `{ "message": "password_too_short" }` | Less than 6 characters |
| 422 | `{ "message": "passwords_dont_match" }` | Confirmation mismatch |
| 400 | `{ "message": "invalid-verification-code" }` | Wrong OTP code |
| 410 | `{ "message": "code_expired" }` | OTP expired |
| 429 | `{ "message": "too_many_attempts" }` | 5+ wrong code attempts |

---

### 5. `POST /auth/verify-email` (authenticated)

**Purpose**: Verify user's email after self-registration. User provides their email + OTP code.

**Prerequisite**: User called `POST /auth/email-otp/send` with their email.

**Request:**
```
POST /api/v1/auth/verify-email
Content-Type: application/json
Authorization: Bearer <access_token>
```

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

**Backend logic:**
```
1. Authenticate via Bearer token
2. Verify OTP code (same as /auth/email-otp/verify)
3. Update user: email = request.email, email_verified = true
4. Delete the email_otps record
5. Return 200
```

**Success response:**
```json
{
  "success": true,
  "message": "email_verified_successfully"
}
```

**Errors:** Same as `/auth/email-otp/verify` for code validation.

---

### 6. `POST /admin/users/{id}/force-reset-password`

**Purpose**: Admin forces a user to re-create their password. Used when a user forgets their password and can't do email reset, or for security reasons.

**Request:**
```
POST /api/v1/admin/users/{id}/force-reset-password
Authorization: Bearer <admin_token>
```

No body required.

**Backend logic:**
```
1. Authenticate admin
2. Find user by ID
3. Set password_hash = NULL
4. Set must_set_password = true
5. Invalidate all active tokens for this user (force logout)
6. Optional: send push notification { type: "force_reset_password" } to user's device_token
7. Return 200
```

**Success response:**
```json
{
  "success": true,
  "message": "password_reset_forced"
}
```

---

### 7. Update: `POST /auth/register`

**Changes**: Add `password` + `password_confirmation` to the request body. Add `phone` + `country_code` fields.

**Updated request:**
```json
{
  "name": "João Silva",
  "phone": "+5511999990000",
  "country_code": "BR",
  "password": "userpassword",
  "password_confirmation": "userpassword",
  "role": "parent"
}
```

**Backend changes:**
```
1. Validate phone uniqueness (per role)
2. Hash password, store in password_hash
3. Set must_set_password = false (user chose their own)
4. Set is_approval = false (waiting admin activation)
5. Set email_verified = false (email verified in next step)
6. Generate access token
7. Return user + token (same shape as /auth/phone-login success)
```

Note: `email` is NOT collected at registration time — it's collected and verified in the next step (`/auth/verify-email`).

---

### 8. Update: User JSON response

Add these fields to the user object (`data`) in **all** auth endpoint responses:

```json
{
  "data": {
    ...existing fields...,
    "must_set_password": false,
    "email_verified": true
  }
}
```

Affected endpoints: `/auth/phone-login`, `/auth/login`, `/auth/login-with-email`, `/auth/social-login`, `/auth/register`, `/auth/email-otp/verify`.

---

### 9. Config flag: `sms_otp_enabled`

Add `sms_otp_enabled` (boolean, default `false`) to the global Firestore `config/*` document that mobile reads via `GET /api/v1/config`.

When `false`: mobile hides the "Login with SMS code" option. When `true`: mobile shows it as a fallback. **No backend enforcement needed** — the existing SMS OTP endpoints (`/auth/login` with `firebase_id_token`) remain functional regardless. This is a UI-only toggle.

---

## Summary of all endpoints

| Method | Path | Auth | Status |
|--------|------|------|--------|
| POST | `/auth/phone-login` | No | **NEW** |
| POST | `/auth/set-password` | Bearer | **NEW** |
| POST | `/auth/change-password` | Bearer | **NEW** |
| POST | `/auth/reset-password` | No | **NEW** |
| POST | `/auth/verify-email` | Bearer | **NEW** |
| POST | `/admin/users/{id}/force-reset-password` | Admin | **NEW** |
| POST | `/auth/register` | No | **UPDATED** (add password + phone fields) |
| GET | `/config` | No | **UPDATED** (add `sms_otp_enabled` flag) |
| POST | `/auth/login` | No | **UNCHANGED** (Firebase phone OTP) |
| POST | `/auth/login-with-email` | No | **UNCHANGED** |
| POST | `/auth/social-login` | No | **UNCHANGED** |
| POST | `/auth/email-otp/send` | No | **UNCHANGED** |
| POST | `/auth/email-otp/verify` | No | **UNCHANGED** |

---

## Backend Task Checklist

- [ ] **B-1**: Migration — add `password_hash`, `must_set_password`, `email_verified` columns to users table. Backfill existing users.
- [ ] **B-2**: `POST /auth/phone-login` — full implementation with all error cases.
- [ ] **B-3**: `POST /auth/set-password` — with `must_set_password == true` guard.
- [ ] **B-4**: `POST /auth/change-password` — verify current before setting new.
- [ ] **B-5**: `POST /auth/reset-password` — verify email OTP code + set new password.
- [ ] **B-6**: `POST /auth/verify-email` — verify email OTP code + set `email_verified = true`.
- [ ] **B-7**: `POST /admin/users/{id}/force-reset-password` — clear password, invalidate tokens, optional push.
- [ ] **B-8**: Update `POST /auth/register` — add phone, password, country_code fields. Set `email_verified = false`, `must_set_password = false`.
- [ ] **B-9**: Add `must_set_password` and `email_verified` to user JSON in all auth responses.
- [ ] **B-10**: Add `sms_otp_enabled: false` to `config/*` Firestore document / config API response.
- [ ] **B-11**: Test: admin-create user → phone-login (no password) → set-password → phone-login (with password) → change-password → force-reset → phone-login (no password again).
- [ ] **B-12**: Test: register → verify-email → admin approve → phone-login.
- [ ] **B-13**: Test: forgot password → email-otp/send → reset-password → phone-login with new password.

**Estimated backend effort**: 3–4 dev-days.
