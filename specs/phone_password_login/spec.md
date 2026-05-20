# Feature Specification: Phone + Password Login with Biometric Access

**Created**: 2026-05-20 | **Status**: Draft | **Flavors**: both (parents + professores)

---

## Summary

Replace SMS OTP as the **primary** login method with **phone + password** to eliminate SMS sending costs. SMS OTP is **disabled by default** via a config flag (`sms_otp_enabled: false`) but the code stays in the codebase — flipping the flag to `true` re-enables it instantly without a release.

Two user-creation paths:

1. **Admin-created users** — admin enters phone + email in the panel. User logs in with phone only (password field empty) on first login, then is **forced to set a password** before accessing the app. No email OTP needed (admin verified the data).

2. **Self-registered users** — user enters phone + password on the register screen, then **verifies their email** via OTP code. Account waits for admin activation (`is_approval: false`).

After password is set, users can enable **biometric login** (Face ID / Fingerprint) for subsequent logins.

---

## Config Flags

| Flag | Location | Default | Effect |
|------|----------|---------|--------|
| `sms_otp_enabled` | `config/*` (Firestore, global) | `false` | When `false`: SMS OTP option hidden on login screen. When `true`: "Login with SMS code" link appears as fallback. All SMS OTP code remains in codebase regardless. |
| `email_otp_globally_visible` | `config/*` (existing) | `false` | When `true`: email OTP tab appears on login. Independent of SMS flag. |

Mobile reads both flags from `ConfigCubit` (already hydrated). No code removal needed — just UI visibility.

---

## Flows

### Flow 1 — Admin-Created User, First Login

```
LoginScreen: user enters phone (password field empty) → tap Login
  → POST /auth/phone-login { phone, country_code, role, device_token }
  → 200 { data: { ...user }, access_token, must_set_password: true }
  → Mobile navigates to SetPasswordScreen (mandatory, cannot be dismissed)
  → User enters password + confirmation (min 6 chars)
  → POST /auth/set-password { password, password_confirmation }
  → 200 { success: true }
  → if is_approval == true  → MainScreen
  → if is_approval == false → AccountUnderReviewScreen
```

### Flow 2 — Normal Login (password already set)

```
LoginScreen: user enters phone + password → tap Login
  → POST /auth/phone-login { phone, country_code, role, password, device_token }
  → 200 { data: { ...user }, access_token, must_set_password: false }
  → if is_approval == true  → MainScreen
  → if is_approval == false → AccountUnderReviewScreen
```

### Flow 3 — Biometric Login

```
App launch → check flutter_secure_storage for saved credentials
  → if biometric enabled → show biometric prompt (Face ID / Fingerprint)
  → on success → decrypt stored phone + countryCode + password
  → POST /auth/phone-login { phone, country_code, role, password, device_token }
  → normal login routing
  → on biometric fail or cancel → show LoginScreen for manual entry
```

### Flow 4 — Self-Registration

```
RegisterScreen:
  Step 1: phone + country_code + name + password + confirm_password → tap Register
    → POST /auth/register { phone, country_code, name, password, password_confirmation, role }
    → 200 { data: { ...user }, access_token }

  Step 2: VerifyEmailScreen → enter email → tap "Send code"
    → POST /auth/email-otp/send { email, lang }
    → 200 { masked_email, retry_after }
    → Enter 6-digit code
    → POST /auth/verify-email { email, code }
    → 200 { success: true }

  Step 3: → AccountUnderReviewScreen (waiting admin activation)
```

### Flow 5 — Forgot Password

```
LoginScreen → tap "Forgot password?"
  → ForgotPasswordScreen
  → Step 1: enter registered email → tap "Send code"
    → POST /auth/email-otp/send { email, lang }
  → Step 2: enter 6-digit code + new password + confirm
    → POST /auth/reset-password { email, code, password, password_confirmation }
    → 200 { success: true }
  → Navigate back to LoginScreen with success snackbar
```

### Flow 6 — Change Password (in Settings)

```
Settings → My Information → Change Password
  → Enter current password + new password + confirm
  → POST /auth/change-password { current_password, password, password_confirmation }
  → 200 { success: true }
  → If biometric enabled → update stored credentials silently
  → Show success snackbar
```

### Flow 7 — Admin Force Reset Password

```
Admin panel → force-reset user's password
  → Backend clears password_hash, sets must_set_password = true
  → Optional push: { type: "force_reset_password" }
  → Next login: phone (empty password) → must_set_password: true → SetPasswordScreen
  → Same as Flow 1
```

---

## Security Considerations

- Passwords hashed with bcrypt server-side (never plain-text)
- Biometric credentials encrypted via OS keychain (`flutter_secure_storage` → iOS Keychain / Android EncryptedSharedPreferences)
- Rate limiting on `/auth/phone-login`: 5 failed password attempts → 15 min lockout (recommended)
- `must_set_password` token should have limited scope (only `/auth/set-password` allowed)
- Admin force-reset should invalidate all existing tokens for that user
- `password`, `password_hash`, `password_confirmation` in `_sensitiveBodyKeys` for Crashlytics redaction
