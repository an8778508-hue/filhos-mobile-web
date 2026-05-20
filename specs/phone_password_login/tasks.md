# Mobile Tasks: Phone + Password Login with Biometric Access

All tasks target **both flavors** (parents + professores). Behavior is identical across flavors.

---

## Phase B — Mobile Foundation (Wave 1)

No backend dependency. Start immediately.

### M-1: Add `smsOtpEnabled` config flag

**File**: `lib/core/config/config.dart`

Add getter to `Config` class:
```dart
bool get smsOtpEnabled => json['sms_otp_enabled'] == true;
```
Default `false` (key missing = disabled). Same pattern as `emailOtpGloballyVisible`.

**Acceptance**: When `sms_otp_enabled` is absent from config JSON, `Config.get.smsOtpEnabled` returns `false`.

---

### M-2: Add `mustSetPassword` to `UserModel`

**File**: `lib/core/models/user_model.dart`

- Add `final bool mustSetPassword;` field
- Parse from `must_set_password` in `fromJson` (default `false`)
- Include in `toJson` for HydratedBloc round-trip
- Verify cold-start round-trip: set field in persisted state → force-kill → reopen → field reflects

**Acceptance**: `UserModel.fromJson({'must_set_password': true, ...}).mustSetPassword == true`.

---

### M-3: Add localization keys (~20 keys)

**Files**:
- `lib/core/localization/localization_keys.dart`
- `assets/langs/pt.json`, `assets/langs/en.json`, `assets/langs/ar.json`

New keys:

| Key | PT-BR | EN | AR |
|-----|-------|----|----|
| `set_password_title` | Criar senha | Create password | إنشاء كلمة مرور |
| `set_password_subtitle` | Crie uma senha para proteger sua conta | Create a password to protect your account | أنشئ كلمة مرور لحماية حسابك |
| `password_min_length` | A senha deve ter pelo menos 6 caracteres | Password must be at least 6 characters | يجب أن تتكون كلمة المرور من 6 أحرف على الأقل |
| `passwords_dont_match` | As senhas não coincidem | Passwords don't match | كلمات المرور غير متطابقة |
| `change_password` | Alterar senha | Change password | تغيير كلمة المرور |
| `current_password` | Senha atual | Current password | كلمة المرور الحالية |
| `new_password` | Nova senha | New password | كلمة المرور الجديدة |
| `confirm_new_password` | Confirmar nova senha | Confirm new password | تأكيد كلمة المرور الجديدة |
| `forgot_password` | Esqueceu a senha? | Forgot password? | نسيت كلمة المرور؟ |
| `enable_biometric` | Ativar login biométrico | Enable biometric login | تفعيل تسجيل الدخول البيومتري |
| `biometric_login` | Entrar com biometria | Login with biometrics | تسجيل الدخول بالبيومترية |
| `biometric_prompt` | Autentique-se para entrar | Authenticate to sign in | المصادقة لتسجيل الدخول |
| `password_changed_successfully` | Senha alterada com sucesso | Password changed successfully | تم تغيير كلمة المرور بنجاح |
| `password_set_successfully` | Senha criada com sucesso | Password set successfully | تم إنشاء كلمة المرور بنجاح |
| `password_field_hint` | Sua senha | Your password | كلمة المرور |
| `reset_password_title` | Redefinir senha | Reset password | إعادة تعيين كلمة المرور |
| `reset_password_success` | Senha redefinida com sucesso | Password reset successfully | تم إعادة تعيين كلمة المرور بنجاح |
| `sms_otp_fallback` | Entrar com código SMS | Login with SMS code | تسجيل الدخول برمز SMS |
| `enter_phone_and_password` | Digite seu telefone e senha | Enter your phone and password | أدخل رقم هاتفك وكلمة المرور |
| `verify_your_email` | Verificar seu e-mail | Verify your email | تحقق من بريدك الإلكتروني |
| `verify_email_subtitle` | Precisamos verificar seu e-mail para completar o cadastro | We need to verify your email to complete registration | نحتاج للتحقق من بريدك الإلكتروني لإكمال التسجيل |
| `enter_your_email` | Digite seu e-mail | Enter your email | أدخل بريدك الإلكتروني |

---

### M-4: Create `PhoneLoginResponse` model

**File**: `lib/features/login/models/phone_login_response.dart`

```dart
class PhoneLoginResponse {
  final UserModel? user;
  final String? accessToken;
  final bool mustSetPassword;

  const PhoneLoginResponse({
    this.user,
    this.accessToken,
    required this.mustSetPassword,
  });

  factory PhoneLoginResponse.fromJson(Map<String, dynamic> json) =>
      PhoneLoginResponse(
        user: json['data'] != null
            ? UserModel.fromJson(json['data'] as Map<String, dynamic>)
            : null,
        accessToken: json['access_token'] as String?,
        mustSetPassword: json['must_set_password'] as bool? ?? false,
      );
}
```

---

### M-5: Add repository methods to `LoginRepository` + `LoginImpl`

**Files**:
- `lib/features/login/data_sources/login_repository.dart`
- `lib/features/login/data_sources/login_impl.dart`

Add endpoint constants:
```dart
static const String phoneLoginEndpoint = 'auth/phone-login';
static const String setPasswordEndpoint = 'auth/set-password';
static const String changePasswordEndpoint = 'auth/change-password';
static const String resetPasswordEndpoint = 'auth/reset-password';
static const String verifyEmailEndpoint = 'auth/verify-email';
```

Add methods:
```dart
Future<Either<Failure, PhoneLoginResponse>> phoneLogin({
  required String phone,
  required String countryCode,
  String? password,
});

Future<Either<Failure, void>> setPassword({
  required String password,
  required String passwordConfirmation,
});

Future<Either<Failure, void>> changePassword({
  required String currentPassword,
  required String password,
  required String passwordConfirmation,
});

Future<Either<Failure, void>> resetPassword({
  required String email,
  required String code,
  required String password,
  required String passwordConfirmation,
});

Future<Either<Failure, void>> verifyEmail({
  required String email,
  required String code,
});
```

All via `networkClient.handleRequest`. `phoneLogin` sends `role` from flavor (`isProfessorsFlavor ? 'teacher' : 'parent'`), `device_token` from `FirebaseMessaging.instance.getToken()`.

`setPassword`, `changePassword`, `verifyEmail` are authenticated (token in interceptor header).

`resetPassword` is **not** authenticated (user has no session).

---

### M-6: Network redaction

**File**: `lib/core/network/network_client.dart`

Add to `_sensitiveBodyKeys`:
```dart
'password_hash',
'password_confirmation',
'current_password',
```

Add to `_sensitivePathPrefixes`:
```dart
'auth/phone-login',
'auth/set-password',
'auth/change-password',
'auth/reset-password',
```

(`password` and `firebase_id_token` already added in prior email-otp work.)

---

## Phase C — Login Screen Rework (Wave 2)

Depends on: M-1 through M-5.

### M-7: Add `phoneLogin` + `LoginMustSetPassword` to LoginBloc

**File**: `lib/features/login/presentation/bloc/login_bloc.dart`

Add method:
```dart
Future<void> phoneLogin({
  required String phone,
  required String countryCode,
  String? password,
}) async {
  emit(LoginLoading());
  final result = await loginRepository.phoneLogin(
    phone: phone,
    countryCode: countryCode,
    password: password?.isNotEmpty == true ? password : null,
  );
  result.fold(
    (failure) => emit(LoginFailure(failure)),
    (response) {
      if (response.user != null) {
        UserBloc.get.loggedIn(response.user!);
      }
      if (response.mustSetPassword) {
        emit(LoginMustSetPassword());
      } else {
        emit(LoginSuccess());
      }
    },
  );
}
```

**File**: `lib/features/login/presentation/bloc/login_state.dart`

Add state:
```dart
final class LoginMustSetPassword extends LoginState {}
```

---

### M-8: Rework LoginScreen for phone + password

**File**: `lib/features/login/presentation/login_screen.dart`

Major changes:
1. **Default phone tab now shows**: phone field + password field + Login button + "Forgot password?" link
2. **SMS OTP link**: small text "Login with SMS code" shown **only when** `Config.get.smsOtpEnabled == true`. Tapping it triggers the existing SMS OTP flow (which is still wired but hidden by default).
3. **Email OTP tab**: still shown when `Config.get.emailOtpGloballyVisible == true` (independent)
4. **Login button action**: calls `LoginBloc.phoneLogin(phone, countryCode, password)` instead of `LoginBloc.requestOTP`
5. **Listener additions**:
   - `LoginMustSetPassword` → navigate to `SetPasswordScreen`
   - `LoginSuccess` → navigate to MainScreen or AccountUnderReview (based on `is_approval`)

The existing `isEmailLogin` toggle (email+password login via social widget) can be **removed or kept** — the new phone+password flow replaces it. The social login buttons (Google, Facebook, Apple) remain unchanged.

**Password field**: Use existing `CustomTextField` with `isPassword: true`, hint: `password_field_hint`, min 6 chars validator. Only validate non-empty when user has typed something (allow empty for first-login admin-created users).

---

### M-9: Hide SMS OTP flow behind config flag

**File**: `lib/features/login/presentation/login_screen.dart`

The existing SMS OTP request (`LoginBloc.requestOTP`) and navigation to `OTPScreen` remain in code but are **only accessible** when `Config.get.smsOtpEnabled == true`. When `false`, no UI element triggers the SMS flow.

Implementation: wrap the "Login with SMS code" link in:
```dart
if (Config.get.smsOtpEnabled)
  TextButton(
    onPressed: () { /* trigger existing SMS OTP flow */ },
    child: Text(LocalizationKeys.sms_otp_fallback.tr(context)),
  ),
```

All SMS OTP code (LoginBloc.requestOTP, OTPBloc.requestOTP/confirmSMSCode, OTPScreen in SMS mode, Firebase phone auth in LoginImpl) remains **untouched**. Only the UI entry point is gated.

---

## Phase D — Set Password Screen (Wave 3)

Depends on: M-5 (repo), M-3 (localization).

### M-10: Create SetPasswordScreen

**File**: `lib/features/set_password/presentation/set_password_screen.dart`

- **Cannot be dismissed**: `PopScope(canPop: false)`, no back button in AppBar
- Two fields: Password + Confirm Password (both `CustomTextField` with `isPassword: true`)
- Validation: min 6 chars, both fields match
- Submit button → calls `loginRepository.setPassword(password, confirmation)`
  - Loading state while request is in flight
  - On success:
    - If `UserBloc.get.state.user?.isApproval == true` → `Navigator.pushAndRemoveUntil(MainScreen)`
    - If `false` → `Navigator.pushAndRemoveUntil(AccountUnderReviewScreen)`
  - On failure → show error via `ErrorField`

**DI**: Use `di<LoginRepository>()` directly (no separate bloc needed — simple request/response).

### M-11: Wire SetPasswordScreen into login flow

**File**: `lib/features/login/presentation/login_screen.dart`

In the `BlocListener<LoginBloc, LoginState>`:
```dart
if (state is LoginMustSetPassword) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
    (route) => false,
  );
}
```

Also in splash/app routing: if persisted `UserModel.mustSetPassword == true` and user has a valid token → route to SetPasswordScreen instead of MainScreen.

---

## Phase E — Forgot Password (Wave 4)

Depends on: M-5 (repo), M-3 (localization). Reuses email OTP send endpoint.

### M-12: Create ForgotPasswordScreen

**File**: `lib/features/login/presentation/widget/forgot_password_screen.dart`

Two-step screen:

**Step 1** — Email entry:
- Email `CustomTextField` with format validator
- "Send code" button → calls `loginRepository.requestEmailOTP(email: email)`
- On success → transition to Step 2
- On failure → show error

**Step 2** — Code + new password:
- 6-digit OTP field (same `PinCodeTextField` as OTPScreen)
- New password + confirm password fields
- Submit → calls `loginRepository.resetPassword(email, code, password, confirmation)`
- On success → `Navigator.pop()` back to LoginScreen + show success snackbar
- On code_expired → show error, allow "Resend code"
- On invalid code → show error, keep input

### M-13: Wire "Forgot password?" link

**File**: `lib/features/login/presentation/login_screen.dart`

Below the password field on the phone tab:
```dart
GestureDetector(
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
  child: Text(LocalizationKeys.forgot_password.tr(context)),
)
```

---

## Phase F — Registration Rework (Wave 5)

Depends on: M-5 (repo), M-3 (localization).

### M-14: Update RegisterScreen — add phone + password fields

**File**: `lib/features/register/presentation/register_screen.dart`

Current register flow: name + email + password → `POST /auth/register`.

New register flow:
1. Replace email field with phone + country code field (reuse `PhoneField` widget)
2. Keep name field
3. Keep password + confirm password fields
4. Update `RegisterBloc` to call updated `POST /auth/register { name, phone, country_code, password, password_confirmation, role }`
5. On success → navigate to `VerifyEmailScreen` (new, M-15)

### M-15: Create VerifyEmailScreen

**File**: `lib/features/register/presentation/verify_email_screen.dart`

After successful registration, user must verify their email:

**Step 1** — Enter email:
- Email `CustomTextField`
- "Send verification code" button → `POST /auth/email-otp/send { email, lang }`
- On success → transition to Step 2

**Step 2** — Enter OTP code:
- 6-digit `PinCodeTextField`
- Submit → `POST /auth/verify-email { email, code }`
- On success → navigate to `AccountUnderReviewScreen`
- On failure → show error

### M-16: Update RegisterBloc/RegisterEvent

**File**: `lib/features/register/bloc/register_event.dart`, `register_bloc.dart` (or wherever the register cubit lives)

Update `RegisterParamaters` to include `phone`, `countryCode`, `password`, `passwordConfirmation`. Remove `email` from registration step (moved to verification).

---

## Phase G — Biometric Authentication (Wave 6)

Depends on: M-7, M-8 (phone+password login working).

### M-17: Add packages + platform config

**File**: `pubspec.yaml`

Add:
```yaml
local_auth: ^2.3.0
flutter_secure_storage: ^9.2.4
```

**iOS**: Add to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to sign in faster</string>
```

**Android**: Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

Also in `android/app/src/main/kotlin/.../MainActivity.kt`, ensure it extends `FlutterFragmentActivity` (required by `local_auth`).

### M-18: Create BiometricService

**File**: `lib/core/biometric/biometric_service.dart`

```dart
class BiometricService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  // Check if device supports biometric
  Future<bool> isBiometricAvailable();

  // Check if user has opted in (credentials stored)
  Future<bool> isBiometricEnabled();

  // Store encrypted credentials after user opts in
  Future<void> enableBiometric({
    required String phone,
    required String countryCode,
    required String password,
  });

  // Clear stored credentials
  Future<void> disableBiometric();

  // Prompt biometric → on success return decrypted credentials
  Future<BiometricCredentials?> authenticateAndGetCredentials();
}

class BiometricCredentials {
  final String phone;
  final String countryCode;
  final String password;
}
```

Storage keys in `flutter_secure_storage`: `bio_phone`, `bio_country_code`, `bio_password`, `bio_enabled`.

Register as singleton in DI: `di.registerLazySingleton<BiometricService>(...)`.

### M-19: Biometric opt-in dialog after login

**File**: `lib/features/login/presentation/login_screen.dart` (or in the navigation listener)

After successful `LoginSuccess` (not `LoginMustSetPassword`):
1. Check `BiometricService.isBiometricAvailable()`
2. Check Hive key `biometric_prompt_shown` — if already shown, skip
3. Show dialog: "Enable Face ID / Fingerprint for faster login?"
   - "Enable" → `BiometricService.enableBiometric(phone, countryCode, password)` → set `biometric_prompt_shown = true`
   - "Not now" → set `biometric_prompt_shown = true` (don't ask again)
4. Then navigate to MainScreen/AccountUnderReview

### M-20: Biometric login button on LoginScreen

**File**: `lib/features/login/presentation/login_screen.dart`

Below the login form, if `BiometricService.isBiometricEnabled()`:
- Show a biometric icon button (fingerprint or face icon)
- On tap → `BiometricService.authenticateAndGetCredentials()`
- On success → `LoginBloc.phoneLogin(phone, countryCode, password)` with decrypted credentials
- On failure / cancel → stay on login screen

### M-21: Biometric auto-prompt on app launch

**File**: `lib/features/splash/presentation/splash_screen.dart` (or routing logic)

On app launch, if:
- User has `rememberMe == true` (persisted in Hive)
- `BiometricService.isBiometricEnabled() == true`

Then:
- Auto-prompt biometric
- On success → auto-login → route to MainScreen
- On failure → route to LoginScreen
- If login returns `must_set_password: true` (admin force-reset) → clear biometric credentials → route to SetPasswordScreen

### M-22: Update biometric after password change

**File**: wherever `changePassword` success is handled (Settings screen)

After successful `POST /auth/change-password`:
- If `BiometricService.isBiometricEnabled()` → call `BiometricService.enableBiometric(phone, countryCode, newPassword)` to update stored password

---

## Phase H — Settings Integration (Wave 7)

Depends on: M-5, M-18.

### M-23: Change Password screen in Settings

**File**: `lib/features/settings/change_password/change_password_screen.dart`

- Current password field
- New password field
- Confirm new password field
- Validation: current not empty, new min 6 chars, confirmation matches
- Submit → `loginRepository.changePassword(currentPassword, password, confirmation)`
- On success → snackbar `password_changed_successfully` + update biometric if enabled
- On `current_password_incorrect` → show error on current password field

### M-24: Add "Change password" to My Information settings

**File**: `lib/features/settings/edit_profile/` (wherever My Information items are listed)

Add a list tile / button: "Change password" → navigates to `ChangePasswordScreen`.

### M-25: Biometric toggle in Settings

**File**: `lib/features/settings/` (settings screen or my information)

Toggle switch:
- When ON and biometric not enabled → prompt biometric → on success → enable with current credentials
  (Need user to enter password to store it — show a password confirmation dialog first)
- When ON and already enabled → no-op
- When OFF → `BiometricService.disableBiometric()`

---

## Phase I — Edge Cases (Wave 8)

### M-26: Handle `force_reset_password` push notification

**File**: `lib/core/notifications_service/` (push handler)

When receiving `{ type: "force_reset_password" }`:
1. Clear biometric credentials (`BiometricService.disableBiometric()`)
2. Clear local session (`UserBloc.get.logout()`)
3. Navigate to LoginScreen
4. Next login will return `must_set_password: true` → SetPasswordScreen

### M-27: Handle `mustSetPassword` on app launch

**File**: Splash routing logic

If persisted `UserModel.mustSetPassword == true` and user has a valid token:
- Route to SetPasswordScreen instead of MainScreen
- User cannot bypass this screen

### M-28: Handle `mustSetPassword` from biometric login

If biometric auto-login returns `must_set_password: true` (admin force-reset between sessions):
1. Clear biometric credentials
2. Route to SetPasswordScreen (user sets new password)
3. After setting password, offer biometric opt-in again

---

## Phase J — QA (Wave 9)

- [ ] **M-29**: `flutter analyze` both flavors — zero warnings
- [ ] **M-30**: Test admin-created user: phone-login (no password) → set password → phone-login (with password)
- [ ] **M-31**: Test normal login: phone + password → MainScreen
- [ ] **M-32**: Test wrong password → error displayed
- [ ] **M-33**: Test forgot password: email OTP → reset → login with new password
- [ ] **M-34**: Test self-registration: phone + password → verify email → account under review
- [ ] **M-35**: Test biometric: enable → close app → reopen → biometric prompt → auto-login
- [ ] **M-36**: Test biometric after password change → credentials auto-updated
- [ ] **M-37**: Test admin force-reset → next login forces password change → biometric cleared
- [ ] **M-38**: Test SMS OTP fallback when `sms_otp_enabled = true`
- [ ] **M-39**: Test SMS OTP hidden when `sms_otp_enabled = false`
- [ ] **M-40**: Test email OTP tab still works independently
- [ ] **M-41**: Release build both flavors

---

## Dependency Graph

```
M-1 (config flag)
M-2 (UserModel) ──► M-4 (response model) ──► M-5 (repo methods)
M-3 (localization)                                  │
M-6 (redaction)                         ┌───────────┼────────────┐
                                        ▼           ▼            ▼
                                  M-7 (bloc)    M-10 (set pw)  M-12 (forgot pw)
                                  M-8 (login UI)  M-11        M-13
                                  M-9 (sms gate)               │
                                        │              M-14..16 (register)
                                        ▼
                                  M-17 (packages)
                                  M-18 (biometric service)
                                  M-19..22 (biometric UI)
                                        │
                                  M-23..25 (settings)
                                  M-26..28 (edge cases)
                                  M-29..41 (QA)
```

## Estimate

| Phase | Tasks | Dev-days |
|-------|-------|----------|
| B — Foundation | M-1..M-6 | 1 |
| C — Login rework | M-7..M-9 | 1 |
| D — Set password | M-10..M-11 | 0.5 |
| E — Forgot password | M-12..M-13 | 1 |
| F — Registration | M-14..M-16 | 1 |
| G — Biometric | M-17..M-22 | 1.5 |
| H — Settings | M-23..M-25 | 0.5 |
| I — Edge cases | M-26..M-28 | 0.5 |
| J — QA | M-29..M-41 | 1 |
| **Total** | **41 tasks** | **~8.5 dev-days** |
