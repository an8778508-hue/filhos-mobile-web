# Email OTP & Gmail SMTP — Server-Driven Authentication

**Audience: backend team (Laravel 10 + Botble, separate repo).** Defines the OTP email delivery pipeline (Gmail SMTP, queued Mailable), the OTP code lifecycle, and the `EMAIL_OTP_ENABLED` feature flag end to end.

> **Important distinction from the existing `email_otp` feature.** `specs/email_otp/` uses email OTP as a **login** method, delivered via the Firebase "Trigger Email from Firestore" extension + SendGrid. **This feature is different**: it uses email OTP only for (a) verifying a newly-registered email and (b) authorizing a password reset, delivered via the project's own **Gmail SMTP** account using a queued Laravel Mailable. The master prompt explicitly forbids Firebase/Twilio/AWS-SNS for this auth path; the project Gmail SMTP account is the only delivery channel.

---

## 1. Gmail SMTP — `.env` configuration

**The mobile/product owner generated the Gmail App Password out of band.** The backend team wires it in:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USERNAME=<project Gmail address>
MAIL_PASSWORD=<16-character App Password — strip spaces>
MAIL_ENCRYPTION=ssl
MAIL_FROM_ADDRESS=<same as MAIL_USERNAME>
MAIL_FROM_NAME="Criarte"

# Email OTP feature flag — see §3 of this file
EMAIL_OTP_ENABLED=true
```

Rules:
- The Gmail account MUST have **2-Step Verification** enabled (Google requirement for App Passwords).
- The 16-character **App Password** (not the Gmail account password) goes in `MAIL_PASSWORD`. Strip any spaces Google's UI inserts.
- `.env` MUST be in `.gitignore` (verify before commit).
- `.env.example` MUST contain the keys with placeholder values and a comment explaining `EMAIL_OTP_ENABLED` (see §3).
- The queue worker (§2) MUST be running in every environment where email is expected to ship.

---

## 2. Queued Mailable — `OtpMail`

OTP delivery MUST be a queued job so SMTP latency never blocks the API response (master-prompt rule).

### Mailable class (sketch)

```php
namespace App\Mail\Auth;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $code,
        public string $purpose, // 'verify_email' | 'reset_password'
        public string $lang,    // 'pt' | 'en' | 'ar'
    ) {}

    public function build()
    {
        return $this
            ->subject(__($this->subjectKey(), [], $this->lang))
            ->view("emails.auth.otp_{$this->lang}")
            ->with([
                'code'    => $this->code,
                'purpose' => $this->purpose,
            ]);
    }

    private function subjectKey(): string
    {
        return $this->purpose === 'reset_password'
            ? 'auth_otp.subject_reset'
            : 'auth_otp.subject_verify';
    }
}
```

### Dispatch sites
- `auth/self-register` (when `EMAIL_OTP_ENABLED = true`): `Mail::to($email)->queue(new OtpMail($code, 'verify_email', $lang));`
- `auth/forgot-password` (when `EMAIL_OTP_ENABLED = true`, email found, user active): `Mail::to($email)->queue(new OtpMail($code, 'reset_password', $lang));`
- Resend triggers re-dispatch the same Mailable with a new code (and a new DB row replacing the prior unconsumed one).

### Queue worker — `README` / ops note
The README (deploy + dev guide) MUST instruct running:
```bash
php artisan queue:work --tries=3 --backoff=30 --queue=default
```
On dev/QA you may run `queue:work --once` after each action; in production it MUST be a supervised long-running worker (Supervisor / systemd / Horizon).

### Failure handling
- If SMTP raises after 3 tries, the job goes to `failed_jobs`. Surface a daily alert.
- The API response is **not** affected by SMTP failure — `auth/self-register` and `auth/forgot-password` return their `action` envelope immediately after the job is queued.

---

## 3. The `EMAIL_OTP_ENABLED` flag — full matrix

A single global server-side flag controlling whether the OTP email step is enforced.

### Where it lives
- **`.env`:** `EMAIL_OTP_ENABLED=true|false` (default `true`).
- **`config/auth.php`:**
  ```php
  return [
      // existing ...
      'email_otp_enabled' => env('EMAIL_OTP_ENABLED', true),
  ];
  ```
- **Business logic reads `config('auth.email_otp_enabled')`** — **NEVER `env()` directly** in controllers/services, because Laravel caches `config/` (and `config:cache` would freeze a stale value otherwise).
- **`.env.example` block (must include the inline warning):**
  ```env
  # ┌────────────────────────────────────────────────────────────────────────────┐
  # │ EMAIL_OTP_ENABLED — server-side OTP enforcement flag                        │
  # │ Default: true (production-safe). When true, the OTP email step is enforced  │
  # │ for self-registration and password reset.                                   │
  # │                                                                              │
  # │ When false: self-registration skips the OTP email entirely (account is      │
  # │ created with email_verified = true immediately). Password reset is BLOCKED  │
  # │ (returns 403 PASSWORD_RESET_UNAVAILABLE) — never bypassed.                  │
  # │                                                                              │
  # │ DEV / QA ONLY. NEVER set to false in production — the artisan command       │
  # │ `php artisan auth:check-config` warns when APP_ENV=production AND this is  │
  # │ false.                                                                       │
  # └────────────────────────────────────────────────────────────────────────────┘
  EMAIL_OTP_ENABLED=true
  ```

### Behavior matrix

| Flow | `EMAIL_OTP_ENABLED=true` (default) | `EMAIL_OTP_ENABLED=false` (dev/QA only) |
|---|---|---|
| **Self-register** (`auth/self-register`) | Generate OTP, queue Mailable, return `{ action: "VERIFY_EMAIL_OTP", temp_token, expires_in: 600 }`. `email_verified` flipped only after the user enters the correct OTP. | **Skip OTP entirely.** Set `email_verified = true` + `email_verified_at = now()` immediately. Return `{ action: "GO_TO_PENDING_APPROVAL" }`. No email sent. |
| **Forgot password** (`auth/forgot-password`) | Generate OTP, queue Mailable, return `{ action: "VERIFY_RESET_OTP", temp_token, expires_in: 600 }`. Reset proceeds only after correct OTP entry. | **Block the flow.** Return `403 { error: { code: "PASSWORD_RESET_UNAVAILABLE", message: "Password reset is currently disabled. Please contact the administrator." } }`. **Reset is NEVER bypassed** — that would let anyone who knows a target's email reset the password. |
| **`auth/verify-email-otp`** | Validate OTP against `email_verification_otps.otp_hash`; increment attempts; fail after 5. | Return `503 { error: { code: "OTP_BYPASSED" } }`. Defense in depth — mobile should never call this endpoint while the flag is off. |
| **`auth/verify-reset-otp`** | Validate OTP against `password_reset_otps.otp_hash`; increment attempts; fail after 5. | Return `503 { error: { code: "OTP_BYPASSED" } }`. Same reason as above. |

### Mandatory side effects when the flag is `false`

1. **Warning log on every affected request:**
   ```
   [WARN] EMAIL_OTP_ENABLED=false — OTP bypassed for user_id={id}
   ```
   Emit on self-register (when `email_verified` is auto-set) and on the rejected forgot-password (`PASSWORD_RESET_UNAVAILABLE`). Make it loud in dashboards so accidental production misconfiguration is obvious.

2. **Production guard — artisan health-check command.** Add `php artisan auth:check-config` that prints an error (does **not** block boot — boot is not gated):
   ```
   ERROR: EMAIL_OTP_ENABLED is false while APP_ENV=production.
          OTP enforcement is disabled. Set EMAIL_OTP_ENABLED=true in production.
   ```
   when `APP_ENV=production AND config('auth.email_otp_enabled') === false`. Run as part of CI/CD pre-deploy gates and as the first step in `composer run post-update-cmd`.

3. **Mobile does not know the flag.** The server returns a different `action` and mobile obeys via the dispatcher. No conditional UI based on the flag.

### Toggling
Switching the flag requires NO code change and NO app rebuild — only a server config refresh (`php artisan config:cache` if cached). Master-prompt acceptance #17.

---

## 4. Email body templates

Three blade views (one per language) ship in `resources/views/emails/auth/`:

- `otp_pt.blade.php` (primary)
- `otp_en.blade.php`
- `otp_ar.blade.php`

Each view must:
- Render the 6-digit `{{ $code }}` prominently (large font, monospaced).
- Differentiate copy by `$purpose`:
  - `verify_email` → "Confirme seu e-mail" / "Verify your email"
  - `reset_password` → "Recuperar senha" / "Reset your password"
- State the 10-minute expiry explicitly.
- Include a "did not request this?" sentence directing the user to contact their school.
- Be PT-BR primary; EN parallel; AR follow-up acceptable.

Localization strings live in `lang/{pt,en,ar}/auth_otp.php`:

```php
return [
    'subject_verify' => 'Seu código Criarte: confirme seu e-mail',
    'subject_reset'  => 'Seu código Criarte: recuperar senha',
    'verify_body'    => 'Use o código abaixo para confirmar seu e-mail. Ele expira em 10 minutos.',
    'reset_body'     => 'Use o código abaixo para recuperar sua senha. Ele expira em 10 minutos.',
    'help_line'      => 'Não solicitou este código? Entre em contato com sua escola.',
];
```

---

## 5. OTP code lifecycle (mobile sees only steps 4, 6, 9)

1. Endpoint (`self-register` / `forgot-password`) decides to send.
2. Backend generates `random_int(0, 999999)` zero-padded.
3. Backend stores `HMAC-SHA256(code, OTP_HMAC_SECRET)` in `email_verification_otps` / `password_reset_otps`, with `attempts = 0`, `expires_at = now() + 10 min`, `consumed_at = NULL`.
4. **Mobile receives** the uniform envelope (`action`, `temp_token`, `expires_in`). No code.
5. Backend dispatches the `OtpMail` job to the queue.
6. **User receives** the email; types the code into `EmailOtpScreen` / `ResetOtpScreen`.
7. Mobile POSTs `verify-*-otp` with `{ temp_token, code }`.
8. Backend compares `HMAC-SHA256(submitted, secret)` to stored hash:
   - Match → set `consumed_at = now()`, advance the flow (`GO_TO_PENDING_APPROVAL` / `SET_NEW_PASSWORD`).
   - Mismatch → `attempts++`; return `OTP_INVALID` (or `OTP_TOO_MANY_ATTEMPTS` once `attempts >= 5`, and invalidate the row).
   - Expired → return `OTP_EXPIRED`; mobile clears the cooldown and unlocks Send.
9. **Mobile** moves on per the returned `action`.

---

## 6. Resend / cooldown

- 60-second cooldown between consecutive sends per (user, flow).
- Server enforces: `auth/forgot-password` / `auth/self-register` re-invoked within 60 s of the prior dispatch → `429 RATE_LIMITED` + `Retry-After`.
- Mobile mirrors: visible countdown + disabled button.
- An expired OTP (`OTP_EXPIRED` response) clears the mobile cooldown immediately so the user can resend right away.

---

## 7. Deliverability checklist (DevOps)

- Gmail SMTP via App Password works out of the box (no DKIM/SPF action on the user side — Gmail signs it).
- **However**, Gmail's daily send limits apply (currently 500 / day for free Gmail; 2000 / day for Workspace). Document the limit; the queue worker MUST surface a clear failure metric if a day approaches the cap.
- Volume estimate: OTP volume per day ≈ daily registrations + daily forgot-password attempts. Confirm with product before launch.
- If volume exceeds Gmail's cap, the path to a transactional provider (Mailgun / Postmark / Brevo) is one Mailer change in `config/mail.php` — no contract change. Document the swap procedure.

---

## 8. Test plan (backend QA)

- [ ] `EMAIL_OTP_ENABLED=true` + happy path: registration → email received within 30 s → OTP entered → `GO_TO_PENDING_APPROVAL`.
- [ ] `EMAIL_OTP_ENABLED=true` + wrong code 5 times → 5th attempt returns `OTP_TOO_MANY_ATTEMPTS`; record invalidated; 6th attempt returns `TOKEN_INVALID` (record gone).
- [ ] `EMAIL_OTP_ENABLED=true` + 10-min wait → next attempt returns `OTP_EXPIRED`.
- [ ] `EMAIL_OTP_ENABLED=true` + resend within 60 s → `429 RATE_LIMITED` with `Retry-After`.
- [ ] `EMAIL_OTP_ENABLED=false` + self-register → returns `GO_TO_PENDING_APPROVAL` immediately; no email sent; `[WARN] EMAIL_OTP_ENABLED=false` line in log.
- [ ] `EMAIL_OTP_ENABLED=false` + forgot-password → returns `403 PASSWORD_RESET_UNAVAILABLE`; no email; warning log.
- [ ] `EMAIL_OTP_ENABLED=false` + direct call to `verify-email-otp` / `verify-reset-otp` → `503 OTP_BYPASSED`.
- [ ] `php artisan auth:check-config` with `APP_ENV=production` + flag false → prints the error.
- [ ] Toggle `EMAIL_OTP_ENABLED` true → false → true with `php artisan config:cache` between flips → behavior changes without app rebuild (master-prompt acceptance #17).
- [ ] Queue worker stopped → API still returns 200 on send (queue piles up); restart worker drains the queue.
- [ ] Spot-check 50 staging log lines: no plaintext email / phone / code / temp_token.
