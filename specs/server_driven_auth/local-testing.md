# Local testing — Server-Driven Authentication without the backend

The Laravel + Botble backend lives in a separate repository and is not yet live. To drive the 9 Flutter screens end-to-end from this app right now, flip a single debug flag and the app uses a canned-response mock in place of the real HTTP impl.

> When the real backend ships, **set the flag back to `false`** — the production wiring relies on the Firestore `config/*.server_driven_auth_enabled` flag and real `criarte.filhos.app/api/v1/auth/*` calls.

## 1. Enable the mock (one-line change)

Open `lib/core/utils/debug_flags.dart` and set:

```dart
class DebugFlags {
  static const bool kSdaDevTest = true; // ← flip from false
}
```

That single switch:
- Forces `Config.serverDrivenAuthEnabled` to `true` regardless of Firestore (so LoginScreen renders the new flow).
- Registers `SdaMockImpl` instead of `ServerDrivenAuthImpl` in DI (so calls return canned responses instead of hitting the network).

Hot-restart (not just hot-reload) once so DI re-runs and HydratedBloc rehydrates.

## 2. Run

```bash
flutter run -t lib/main.dart            --flavor parents
flutter run -t lib/main_professores.dart --flavor professores
```

You should land on the **new** LoginScreen (phone field + `Avançar` button + `Criar nova conta` link at the bottom). If you still see the legacy SMS-OTP login, the flag isn't propagated — hot-restart again.

## 3. Test phone numbers

The mock keys every response off the phone number you enter on LoginScreen. Country code always `+55`.

| Phone (enter in field) | Action returned | Where you land |
|---|---|---|
| `11111110001` | `CREATE_NEW_PASSWORD` | **SetInitialPasswordScreen** (no back button). Type any password ≥ 8 chars + matching confirm → JWT minted → `MainScreen`. |
| `11111110002` | `REQUIRE_PASSWORD` | Password field reveals **inline on the same screen** (no nav). Type `Senha123` → `MainScreen`. Wrong password → `INVALID_CREDENTIALS`. **"Forgot password?"** is visible below the field — see §6. |
| `11111110003` | `VERIFY_EMAIL_OTP` | **EmailOtpScreen**. Type `123456` → `PendingApprovalScreen`. Anything else → `OTP_INVALID`. |
| `11111110004` | `GO_TO_PENDING_APPROVAL` | **PendingApprovalScreen** directly. |
| `11111110005` | `ACCOUNT_SUSPENDED` | Inline suspended-account error on LoginScreen. No nav. |
| anything else | `NOT_FOUND` | Inline "no account found — create one?" prompt with a button into SelfRegisterScreen. |

## 4. Testing the registration → OTP screen (your question)

Two ways to reach `EmailOtpScreen`:

**A. Via self-register (the natural user flow):**
1. On LoginScreen, tap **Criar nova conta**.
2. Fill any name, phone, email, password, confirm.
3. Submit.
4. Mock returns `VERIFY_EMAIL_OTP` → app navigates to **EmailOtpScreen**.
5. Enter `123456` → `verify-email-otp` returns `GO_TO_PENDING_APPROVAL` → app navigates to **PendingApprovalScreen**.

**B. Via the dedicated test phone:**
1. On LoginScreen, enter phone `11111110003`, tap **Avançar**.
2. Mock returns `VERIFY_EMAIL_OTP` → directly to **EmailOtpScreen**.
3. Enter `123456` → success path as above.

Wrong code paths:
- Type any 6-digit code that isn't `123456` → `OTP_INVALID` snackbar surfaces `sda_error_invalid_credentials` over the pin field.
- After 60 s the resend button enables (cosmetic in the mock; the real backend re-dispatches the queued Gmail-SMTP `OtpMail`).

## 5. Testing the admin-first-login flow

1. Enter `11111110001`, tap **Avançar**.
2. App navigates to **SetInitialPasswordScreen** — try the OS back gesture: nothing happens (`PopScope(canPop:false)` enforced by FR-SDA-06).
3. Type any password ≥ 8 chars in both fields, tap **Save**.
4. App routes through the approval gate to **MainScreen** (since the fake user has `is_approval: true`).

Negative checks:
- Mismatched confirmation → `sda_error_password_mismatch` snackbar; no request fires.
- Password < 8 chars → `sda_error_password_weak`; no request fires.

## 6. Testing the forgot-password flow (Scenario 5)

1. Enter `11111110002`, tap **Avançar** → inline password field appears.
2. Tap **Esqueceu a senha?** (below the password field) → app navigates to **ForgotPasswordEmailScreen**.
3. Type any email, tap **Enviar código**.
4. Mock returns `VERIFY_RESET_OTP` → **ResetOtpScreen**.
5. Enter `123456` → mock returns `SET_NEW_PASSWORD` → **SetNewPasswordScreen** (PopScope active).
6. Type any password ≥ 8 chars + matching confirm, tap **Save**.
7. App pops the stack back to **LoginScreen** with a green snackbar showing `sda_reset_success`.

## 7. Hide the OTP step locally — `kSdaSkipOtp` flag

A single flag in `lib/core/utils/debug_flags.dart` makes the SDA mock behave as if the backend's `EMAIL_OTP_ENABLED=false` was set:

```dart
static const bool kSdaSkipOtp =
    bool.fromEnvironment('SDA_SKIP_OTP', defaultValue: false);
```

When **on** (alongside `kSdaDevTest=true`), the mock returns:

| Endpoint | Returns | Effect in the UI |
|---|---|---|
| `self-register` | `GO_TO_PENDING_APPROVAL` directly | **Registration form → Pending Approval screen.** No OTP screen, no email. |
| `check-identifier` for `11111110003` | `GO_TO_PENDING_APPROVAL` instead of `VERIFY_EMAIL_OTP` | The "OTP test phone" shortcut now lands on Pending Approval too. |
| `forgot-password` | `403 PASSWORD_RESET_UNAVAILABLE` | Forgot-password is **blocked** (per spec — never bypassed, otherwise anyone with an email could reset). |
| `verify-email-otp` / `verify-reset-otp` | `OTP_BYPASSED` (defense in depth) | Mobile should never reach these when OTP is hidden. |

### How to turn it on

For a single run with the OTP step hidden:

```powershell
flutter run -t lib/main.dart --flavor parents \
  --dart-define=SDA_DEV_TEST=true \
  --dart-define=SDA_SKIP_OTP=true
```

For a more permanent change while you're working manually, edit `defaultValue: false` → `defaultValue: true` on `kSdaSkipOtp` in `lib/core/utils/debug_flags.dart` (same trick as `kSdaDevTest`). **Flip back to `false` before merging.**

### Flutter sees nothing — the dispatcher still drives the UI

The flag affects only the mock impl's responses; the `AuthActionDispatcher` and the 9 screens are unchanged. With OTP hidden the `EmailOtpScreen` and `ResetOtpScreen` simply never get pushed — they're still in the codebase, ready for production where the backend's `EMAIL_OTP_ENABLED` flips back on. This mirrors the production-side contract exactly (see `contracts/email-otp.md` §3 — Flutter never reads `EMAIL_OTP_ENABLED`, it just obeys whichever action the backend returns).

## 8. When you flip back to the real backend

1. Set `DebugFlags.kSdaDevTest = false` in `lib/core/utils/debug_flags.dart`.
2. Set `config/{schoolId or org}.server_driven_auth_enabled = true` in Firestore for the schools you want on the new flow.
3. Backend `.env`: `EMAIL_OTP_ENABLED=true` + `php artisan config:cache`.
4. Hot-restart the app.
5. The DI now wires `ServerDrivenAuthImpl` (real HTTP); the test phones above are no longer special — the backend's DB rows are what determine each phone's `action` per the table in [contracts/rest-endpoints.md §1](contracts/rest-endpoints.md).

## 9. Why a mock, not a stub server

A mock impl wired through GetIt is:
- Zero new dependencies (no MSW / WireMock / json-server).
- Same `Either<Failure, T>` surface as the real impl, so the cubit + dispatcher exercise their full state machine.
- Toggleable with one const — no separate build flavor for "with mock".
- Safe to leave in the codebase: with `kSdaDevTest = false`, `SdaMockImpl` is constructed by nothing and tree-shaken out of release builds.

The trade-off is that you don't exercise actual HTTP / interceptors / JSON parsing in the mock path. Once the backend is up, run the same scenarios with the flag off for a true end-to-end pass — see [TESTING.md](../../TESTING.md).
