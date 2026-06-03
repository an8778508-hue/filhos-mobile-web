# Data Model — Server-Driven Authentication

This file defines every entity touched by the feature, on both sides of the wire. Backend entities (DB tables, server-stored OTPs, temp tokens) are cross-referenced to [contracts/database-changes.md](contracts/database-changes.md); mobile entities (Dart classes, enums) are normative for the Flutter implementation in this PR.

## 1. Server-side entities (summary)

See [contracts/database-changes.md](contracts/database-changes.md) for the full migration and indexes.

- **`users`** — existing table, gains nullable `password`, `status ENUM('create','pending','active','suspended')`, `email_verified`, `email_verified_at`, optional `token_version`, plus indexes on `phone` and `status`.
- **`password_reset_otps`** — new table. One active row per user × flow. Stores `otp_hash`, `attempts`, `expires_at`, `consumed_at`.
- **`email_verification_otps`** — new table (recommended; same shape as above) for the registration OTP.
- **Temp-token store** — either `auth_temp_tokens` table or Redis. Stores `token_hash` + `scope` ∈ {`set-password`, `reset-password`, `verify-email-otp`, `verify-reset-otp`} + `expires_at` + `consumed_at`.

The mobile app never reads or writes these directly. It only handles the opaque `temp_token` strings, the `action` envelope, and the final JWT.

## 2. Mobile-side entities (Dart)

### 2.1 `AuthAction` — enum + parser
File: `lib/features/server_driven_auth/models/auth_action.dart`

```dart
enum AuthAction {
  createNewPassword,    // CREATE_NEW_PASSWORD
  requirePassword,      // REQUIRE_PASSWORD
  verifyEmailOtp,       // VERIFY_EMAIL_OTP
  goToPendingApproval,  // GO_TO_PENDING_APPROVAL
  verifyResetOtp,       // VERIFY_RESET_OTP
  setNewPassword,       // SET_NEW_PASSWORD
  notFound,             // NOT_FOUND
  accountSuspended,     // ACCOUNT_SUSPENDED
  unknown;              // fallthrough — surfaces sda_error_unknown_action

  static AuthAction fromWire(String? raw) {
    switch (raw) {
      case 'CREATE_NEW_PASSWORD':    return AuthAction.createNewPassword;
      case 'REQUIRE_PASSWORD':       return AuthAction.requirePassword;
      case 'VERIFY_EMAIL_OTP':       return AuthAction.verifyEmailOtp;
      case 'GO_TO_PENDING_APPROVAL': return AuthAction.goToPendingApproval;
      case 'VERIFY_RESET_OTP':       return AuthAction.verifyResetOtp;
      case 'SET_NEW_PASSWORD':       return AuthAction.setNewPassword;
      case 'NOT_FOUND':              return AuthAction.notFound;
      case 'ACCOUNT_SUSPENDED':      return AuthAction.accountSuspended;
      default:                       return AuthAction.unknown;
    }
  }
}
```

**Critical:** `fromWire` is case-sensitive. Any unknown string maps to `AuthAction.unknown` so the dispatcher can surface a controlled error rather than crash.

### 2.2 `AuthActionResponse` — uniform envelope
File: `lib/features/server_driven_auth/models/auth_action_response.dart`

```dart
class AuthActionResponse {
  final AuthAction action;
  final String? tempToken;
  final int? expiresIn;         // seconds; companion to tempToken
  final UserModel? user;        // partial UserModel on CREATE_NEW_PASSWORD entry

  AuthActionResponse({
    required this.action,
    this.tempToken,
    this.expiresIn,
    this.user,
  });

  factory AuthActionResponse.fromJson(Map<String, dynamic> json) {
    return AuthActionResponse(
      action:     AuthAction.fromWire(json['action'] as String?),
      tempToken:  json['temp_token'] as String?,
      expiresIn:  json['expires_in'] as int?,
      user:       json['user'] is Map<String, dynamic>
                      ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
                      : null,
    );
  }
}
```

This envelope is returned by `check-identifier`, `self-register`, `verify-email-otp`, `forgot-password`, `verify-reset-otp`. The terminal endpoints (`set-initial-password`, `login`) return the existing login shape `{ data: UserModel, access_token }` instead — handled by reusing `UserModel.fromJson` in the impl.

### 2.3 Request models

All under `lib/features/server_driven_auth/models/`. Plain data classes with `toJson`.

```dart
class CheckIdentifierRequest {
  final String phone;
  final String countryCode;
  final String role; // 'parent' | 'teacher'
  Map<String, dynamic> toJson() => {
    'phone': phone, 'country_code': countryCode, 'role': role,
  };
}

class SelfRegisterRequest {
  final String name;
  final String phone;
  final String countryCode;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String role;
  Map<String, dynamic> toJson() => {
    'name': name, 'phone': phone, 'country_code': countryCode,
    'email': email, 'password': password,
    'password_confirmation': passwordConfirmation, 'role': role,
  };
}

class SetPasswordRequest {
  final String tempToken;
  final String password;
  final String passwordConfirmation;
  Map<String, dynamic> toJson() => {
    'temp_token': tempToken, 'password': password,
    'password_confirmation': passwordConfirmation,
  };
}

class LoginRequest {
  final String phone;
  final String countryCode;
  final String password;
  final String role;
  final String? deviceToken;
  Map<String, dynamic> toJson() => {
    'phone': phone, 'country_code': countryCode,
    'password': password, 'role': role,
    if (deviceToken != null) 'device_token': deviceToken,
  };
}

class ForgotPasswordRequest {
  final String email;
  Map<String, dynamic> toJson() => {'email': email};
}

class OtpVerifyRequest {
  final String tempToken;
  final String code;
  Map<String, dynamic> toJson() => {'temp_token': tempToken, 'code': code};
}
```

### 2.4 Error envelope
File: `lib/features/server_driven_auth/models/auth_error_response.dart`

```dart
class AuthErrorResponse {
  final String code;        // machine code (UPPER_SNAKE)
  final String message;     // human readable, never shown to user

  factory AuthErrorResponse.fromJson(Map<String, dynamic> json) {
    final err = json['error'] as Map<String, dynamic>? ?? {};
    return AuthErrorResponse(
      code:    err['code']?.toString() ?? 'UNKNOWN',
      message: err['message']?.toString() ?? '',
    );
  }
  const AuthErrorResponse({required this.code, required this.message});
}
```

The impl converts a non-2xx into `Left(ServerFailure(message: code))` so existing `ErrorField` widgets surface it; the cubit then maps `code` → a localized key. See §4 below.

### 2.5 Repository interface
File: `lib/features/server_driven_auth/data_sources/server_driven_auth_repository.dart`

```dart
abstract class ServerDrivenAuthRepository {
  // Base endpoints
  static const _base = 'auth';

  // Entry
  Future<Either<Failure, AuthActionResponse>> checkIdentifier(CheckIdentifierRequest r);

  // Admin-first-login terminal
  Future<Either<Failure, UserModel>> setInitialPassword(SetPasswordRequest r);

  // Self-register flow
  Future<Either<Failure, AuthActionResponse>> selfRegister(SelfRegisterRequest r);
  Future<Either<Failure, AuthActionResponse>> verifyEmailOtp(OtpVerifyRequest r);

  // Subsequent login
  Future<Either<Failure, UserModel>> login(LoginRequest r);

  // Forgot password flow
  Future<Either<Failure, AuthActionResponse>> forgotPassword(ForgotPasswordRequest r);
  Future<Either<Failure, AuthActionResponse>> verifyResetOtp(OtpVerifyRequest r);
  Future<Either<Failure, void>> resetPassword(SetPasswordRequest r);
}
```

The two terminal endpoints (`setInitialPassword`, `login`) return `UserModel` directly because their response is the login shape; the impl parses `data` via `UserModel.fromJson` and the cubit then calls `UserBloc.get.loggedIn(user)`.

`resetPassword` returns `Either<Failure, void>` on success; the screen clears the nav stack and the user logs in fresh.

### 2.6 Cubit + state
File: `lib/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart`

```dart
class ServerDrivenAuthCubit extends Cubit<ServerDrivenAuthState> {
  final ServerDrivenAuthRepository repo;
  final AuthActionDispatcher dispatcher;
  ServerDrivenAuthCubit(this.repo, this.dispatcher)
    : super(const ServerDrivenAuthInitial());

  Future<void> checkIdentifier(...) async { ... } // emits states + invokes dispatcher
  Future<void> setInitialPassword(...) async { ... }
  Future<void> selfRegister(...) async { ... }
  Future<void> verifyEmailOtp(...) async { ... }
  Future<void> login(...) async { ... }
  Future<void> forgotPassword(...) async { ... }
  Future<void> verifyResetOtp(...) async { ... }
  Future<void> resetPassword(...) async { ... }
}
```

States (sealed-style hierarchy):
- `ServerDrivenAuthInitial` — start screen ready
- `ServerDrivenAuthLoading` — in-flight call
- `LoginPasswordRequired` — `REQUIRE_PASSWORD` received; reveal inline password
- `ServerDrivenAuthNotFound` — `NOT_FOUND` received; inline create-account prompt
- `ServerDrivenAuthSuspended` — `ACCOUNT_SUSPENDED`
- `ServerDrivenAuthSuccess` — terminal (`UserBloc.loggedIn` called, dispatcher routes to home/approval)
- `ServerDrivenAuthFailure(localizedKey)` — error surfaced

Navigation transitions (`CREATE_NEW_PASSWORD`, `VERIFY_EMAIL_OTP`, `GO_TO_PENDING_APPROVAL`, `VERIFY_RESET_OTP`, `SET_NEW_PASSWORD`) are performed by the dispatcher — the cubit only emits a transient state that the dispatcher reacts to via a `BlocListener`.

### 2.7 Dispatcher
File: `lib/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart`

Single mapper from `AuthAction` (+ accompanying `tempToken`) to a navigation/state action.

```dart
class AuthActionDispatcher {
  void dispatch(BuildContext context, AuthActionResponse r) {
    switch (r.action) {
      case AuthAction.createNewPassword:
        return _goSetInitialPassword(context, r.tempToken!);
      case AuthAction.requirePassword:
        return _revealPasswordField(context); // cubit emits LoginPasswordRequired
      case AuthAction.verifyEmailOtp:
        return _goEmailOtp(context, r.tempToken!);
      case AuthAction.goToPendingApproval:
        return _goPendingApproval(context);
      case AuthAction.verifyResetOtp:
        return _goResetOtp(context, r.tempToken!);
      case AuthAction.setNewPassword:
        return _goSetNewPassword(context, r.tempToken!);
      case AuthAction.notFound:
        return _showSelfRegisterPrompt(context);
      case AuthAction.accountSuspended:
        return _showSuspendedError(context);
      case AuthAction.unknown:
        return _showUnknownActionError(context);
    }
  }
}
```

This is the **only** place that maps actions to UI side-effects (FR-SDA-04). No widget or cubit may branch on `action` strings.

### 2.8 Config flag
File: `lib/core/config/cubit/config_state.dart` (existing — extend)

Add field:
```dart
final bool serverDrivenAuthEnabled; // default false
```

Round-trip in `toJson`/`fromJson`. Source: Firestore `config/*` org-wide doc.

## 3. Reused entities (no changes)

- **`UserModel`** — parsed unchanged from `set-initial-password`, `login`, and (if/when chosen later) `verify-email-otp`. The JSON keys (`access_token`, `is_approval`, `role`, …) are guaranteed by [contracts/rest-endpoints.md](contracts/rest-endpoints.md).
- **`UserBloc.loggedIn(user)`** — sole materialization path for an authenticated user (Constitution Principle VIII relies on this).
- **`NetworkClient.handleRequest<T>`** — every endpoint uses it (Principle III).
- **`Failure` hierarchy** — `ServerFailure`, `NetworkFailure` unchanged; the message field carries the error `code` for the cubit to map.

## 4. Error code → localization key mapping (mobile-side)

| Backend `code` | Localization key | Notes |
|---|---|---|
| `INVALID_CREDENTIALS` | `sda_error_invalid_credentials` | wrong password |
| `ACCOUNT_SUSPENDED` | `sda_error_account_suspended` | also reached via `action: ACCOUNT_SUSPENDED` |
| `TOKEN_INVALID` / `TOKEN_EXPIRED` / `TOKEN_SCOPE_MISMATCH` | `sda_error_token_invalid` | route back to start of sub-flow |
| `OTP_INVALID` | `sda_error_invalid_credentials` | shown on the pin field |
| `OTP_EXPIRED` | `sda_error_otp_expired` | clears local cooldown |
| `OTP_TOO_MANY_ATTEMPTS` | `sda_error_otp_too_many` | force back to start |
| `PASSWORD_RESET_UNAVAILABLE` | `sda_error_reset_unavailable` | shown on `ForgotPasswordEmailScreen` |
| `RATE_LIMITED` | `sda_error_generic` | + countdown if `Retry-After` parsed |
| `VALIDATION_ERROR` | `sda_error_password_weak` or `sda_error_password_mismatch` | depending on field |
| `EMAIL_ALREADY_REGISTERED` | `sda_error_generic` | shown on `SelfRegisterScreen` |
| `OTP_BYPASSED` | `sda_error_generic` | should never reach UI |
| *(unknown)* | `sda_error_unknown_action` / `sda_error_generic` | + Crashlytics log |

## 5. State invariants

- A `temp_token` is held only by the screen that received it. The cubit's `current temp_token` is cleared on screen pop and on flow restart.
- `serverDrivenAuthEnabled` is read once at app start (HydratedCubit hydration) and re-read on `ConfigCubit` refresh; a runtime flip takes effect on next return to LoginScreen.
- `LoginPasswordRequired` is **not** persisted — it is a screen-local state. Cold-restarting while inline-reveal is shown returns the user to the phone-entry state.
- `temp_token` is **never** persisted to Hive/HydratedBloc (FR-SDA-16).
