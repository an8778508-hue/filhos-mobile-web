# Backend Issues Report — Criarte Mobile App

**Date:** 2026-05-20 (updated with backend team feedback)
**Reporter:** Mobile team (Nour)
**Environment:** Android emulator (API 34), debug build, parents flavor
**API Base:** `https://disney.filhos.app/api/v1/`

---

## CRITICAL — P0

### 1. SSL Certificate Expired on `criarte.filhos.app`

**Impact:** App cannot connect to `criarte.filhos.app`. All API requests fail with `CERTIFICATE_VERIFY_FAILED: certificate has expired`.

**Evidence:**
```
$ curl -sv "https://criarte.filhos.app" 2>&1 | grep expire
* schannel: next InitializeSecurityContext failed: SEC_E_CERT_EXPIRED (0x80090328)
  - The received certificate has expired.
```

**Workaround:** Mobile app temporarily bypasses SSL validation in debug builds only (`HttpOverrides` with `badCertificateCallback = true`). NOT safe for production.

**Action required:** Renew the SSL/TLS certificate for `criarte.filhos.app`. Check if auto-renewal (certbot) is configured.

**Note:** Mobile app is currently pointed at `disney.filhos.app` which has a valid cert. This issue only blocks if we need to switch back to `criarte.filhos.app`.

---

## HIGH — P1

### 2. `disney.filhos.app` and `criarte.filhos.app` Have Different User Databases

**Impact:** Accounts registered on `criarte.filhos.app` do not exist on `disney.filhos.app`, and vice versa. Test accounts created on one backend return 422 on the other.

**Evidence:**
```bash
# disney.filhos.app — account NOT found
$ curl -s -X POST "https://disney.filhos.app/api/v1/auth/login" \
  -H "school: 1" -H "Content-Type: application/json" \
  -d '{"phone":"201150005372","country_code":"EG","device_token":"test","role":"parent"}'
# → 422: "These credentials do not match our records."

# criarte.filhos.app — account FOUND
$ curl -sk -X POST "https://criarte.filhos.app/api/v1/auth/login" \
  -H "school: 1" -H "Content-Type: application/json" \
  -d '{"phone":"201150005372","country_code":"EG","device_token":"test","role":"parent"}'
# → 200: {"data":{"id":107,"role":"parent","access_token":"158|k5vZ..."}}
```

**Questions for backend team:**
1. Is `disney.filhos.app` intended to replace `criarte.filhos.app`?
2. If yes, was a user migration planned? It hasn't happened — the databases are separate.
3. Which backend should the mobile app target for production?
4. Are both servers running the same API version/codebase?
5. Should test accounts be created on `disney.filhos.app` so mobile can develop against it?

---

## MEDIUM — P2

### ~~3. Phone format normalization~~ — RESOLVED

**Backend team confirmed:** Phone normalization is already handled server-side. Backend strips `+`, spaces, and does suffix-matching. DB format is digits only (Egyptian: `20` + 10 digits, e.g., `201111100757`). Some legacy rows may have `0` prefix format (`01111100757`).

**No action needed** from mobile or backend.

---

### 4. Login Endpoint Hardcoded `school` Header

**Context:** The mobile app sends `school: 1` as a header on every login request (from `StaticConfig.schoolId`). This means:
- Only school ID 1 users can log in
- If the app is deployed to a new school, the static config must be changed and a new build published

**Question:** Is there a plan to make the school ID dynamic (e.g., from a school selection screen, QR code, or deep link)?

---

### 5. Double Config Fetch on Splash

**Observation:** The app makes two `/config` requests on startup — first without headers, then with `{lang: ar}`. Adds ~2s to splash screen time.

```
Request url: https://disney.filhos.app/api/v1/config   Headers: {}
Request url: https://disney.filhos.app/api/v1/config   Headers: {lang: ar}
```

**Suggestion:** Could be optimized to a single request if the first call included the default language header.

---

## LOW — P3

### 6. Auth Token Exposed in Verbose Logging

**Observation:** Debug builds print full request/response bodies (phone, device token) to logcat. Acceptable for debug, but production interceptors should suppress body logging.

---

## OTP Clarification

**Backend team confirmed:** OTP verification is handled entirely by Firebase Phone Auth on the mobile side. The backend has no involvement in SMS delivery or OTP validation. Any OTP issues should be debugged via:
- Firebase Console → Authentication → Phone
- SMS delivery logs
- The mobile app's debug OTP bypass (`kDebugMode` → code `123456`)

---

## Summary Table

| # | Issue | Severity | Owner | Status |
|---|-------|----------|-------|--------|
| 1 | SSL cert expired on `criarte.filhos.app` | P0 Critical | DevOps/Infra | Open |
| 2 | `disney` vs `criarte` — separate user databases | P1 High | Backend | Open — needs clarification |
| ~~3~~ | ~~Phone format normalization~~ | ~~P1~~ | — | **Resolved** — backend normalizes |
| 4 | Hardcoded `school: 1` header | P2 Medium | Backend + Mobile | Open |
| 5 | Double config fetch on splash | P2 Medium | Mobile | Open |
| 6 | Auth token in debug logs | P3 Low | Mobile | Acceptable for debug |
