# Data Model: Email OTP — login by email-delivered code

Entities introduced or modified by this feature. The OTP record itself is **server-owned** (stored in the backend's `email_otps` table). Mobile only sees the request/response payloads. The `MailDocument` is a Firestore artifact written by the backend and read by the Firebase Extension — mobile never touches it.

---

## OTPDeliveryMode *(new enum)*

```dart
enum OTPDeliveryMode {
  sms,
  email,
}
```

Threaded through `OTPScreen`, `OTPBloc`, and the localized chrome widget. SMS is the default for backward compatibility.

---

## EmailOTPSendRequest *(mobile-built, wire payload)*

```dart
class EmailOTPSendRequest {
  final String email;
  final String lang;   // "pt" | "en" | "ar" — read from ConfigCubit at send time

  Map<String, dynamic> toJson() => {
    'email': email,
    'lang': lang,
  };
}
```

Validation rules:
| Field | Rule |
|---|---|
| `email` | Non-empty, matches `^[^\s@]+@[^\s@]+\.[^\s@]{2,}$` client-side |
| `lang` | Must be one of the three supported codes; defaults to `"pt"` if `ConfigCubit.state.lang` is empty |

---

## EmailOTPSendResponse *(server-sent)*

```dart
class EmailOTPSendResponse {
  final String maskedEmail;   // e.g., "p***@example.com" — displayed verbatim
  final int retryAfter;       // seconds the client should observe before next /send

  factory EmailOTPSendResponse.fromJson(Map<String, dynamic> json) =>
      EmailOTPSendResponse(
        maskedEmail: json['masked_email'] as String,
        retryAfter: (json['retry_after'] as num).toInt(),
      );
}
```

The `maskedEmail` is the **source of truth** for the verification-screen display. Mobile never derives it from the raw email (see research R4).

---

## EmailOTPVerifyRequest

```dart
class EmailOTPVerifyRequest {
  final String email;
  final String code;   // 6-digit numeric string

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
  };
}
```

---

## EmailOTPVerifyResponse

Identical wire shape to the existing `/auth/login` response. Reuses `UserModel.fromJson` for parsing:

```dart
class EmailOTPVerifyResponse {
  final String accessToken;
  final UserModel user;

  factory EmailOTPVerifyResponse.fromJson(Map<String, dynamic> json) =>
      EmailOTPVerifyResponse(
        accessToken: json['access_token'] as String,
        user: UserModel.fromJson(json['data'] as Map<String, dynamic>),
      );
}
```

On success, `OTPBloc.confirmEmailOTP` calls `UserBloc.loggedIn(response.user)` exactly like the SMS path. The `accessToken` is persisted by `UserBloc` via the existing mechanism — no new persistence code.

---

## OTPState *(modified — adds mode field)*

```dart
// Existing states (unchanged shape):
sealed class OTPState extends Equatable { ... }
class OTPInitial extends OTPState { ... }
class OTPLoading extends OTPState { ... }
class OTPReady extends OTPState { ... }
class OTPSuccess extends OTPState { ... }
class OTPFailure extends OTPState {
  final Failure failure;
  ...
}
```

The `OTPBloc` adds a **non-state field**:
```dart
OTPDeliveryMode currentMode = OTPDeliveryMode.sms;   // set by requestOTP/requestEmailOTP
String? currentMaskedEmail;                          // set by requestEmailOTP from response
```

Rationale: keeping these as Cubit fields (not state members) preserves the existing `OTPState` shape so `BlocBuilder<OTPBloc, OTPState>` consumers don't break. The screen reads `bloc.currentMode` and `bloc.currentMaskedEmail` directly in builders — same pattern the existing bloc uses for `pendingOTPTime` and `loginModel`.

---

## OTPBloc *(modified — new methods)*

Existing methods (unchanged): `requestOTP`, `resendOTP`, `confirmSMSCode`, `_init`, `_startTimer`, `_successOTP`.

**New methods**:
```dart
Future<void> requestEmailOTP({
  required String email,
  required bool remember,
}) async {
  currentMode = OTPDeliveryMode.email;
  rememberMe = remember;
  // cooldown check — uses last_email_otp_request / last_email_otp_email
  // ...
  final result = await loginRepository.requestEmailOTP(email: email);
  result.fold(
    (failure) => emit(OTPFailure(failure)),
    (response) {
      currentMaskedEmail = response.maskedEmail;
      pendingOTPTime = response.retryAfter;
      _startTimer();
      emit(OTPReady());
    },
  );
}

Future<void> confirmEmailOTP({
  required String email,
  required String code,
}) async {
  emit(OTPLoading());
  final result = await loginRepository.confirmEmailOTP(email: email, code: code);
  result.fold(
    (failure) => emit(OTPFailure(failure)),
    (response) async {
      localDatabase.delete(key: LocalKeys.last_email_otp_request);
      localDatabase.delete(key: LocalKeys.last_email_otp_email);
      _timer?.cancel();
      if (rememberMe) {
        localDatabase.write(key: LocalKeys.rememberMe, value: true);
      }
      UserBloc.get.loggedIn(response.user);
      emit(OTPSuccess());
    },
  );
}

Future<void> resendEmailOTP({required String email}) async {
  await requestEmailOTP(email: email, remember: rememberMe);
}
```

The cooldown init/start logic mirrors `_init` but reads the email-specific Hive keys — extracted into a private `_initEmailCooldown(String email)` helper.

---

## LoginRepository *(modified — two new methods)*

```dart
abstract class LoginRepository {
  // ... existing methods (login, requestOTP, confirmOTP, etc.) ...

  // NEW:
  Future<Either<Failure, EmailOTPSendResponse>> requestEmailOTP({
    required String email,
  });

  Future<Either<Failure, EmailOTPVerifyResponse>> confirmEmailOTP({
    required String email,
    required String code,
  });
}
```

The corresponding endpoints live as new fields on the interface (or as inline string constants in the impl):
- `static const String emailOtpSendEndpoint = 'auth/email-otp/send';`
- `static const String emailOtpVerifyEndpoint = 'auth/email-otp/verify';`

---

## ConfigCubit / ConfigState *(modified — new field)*

```dart
// On ConfigState:
final bool emailOtpGloballyVisible;   // default false

// ConfigState.fromJson:
emailOtpGloballyVisible: json['email_otp_globally_visible'] as bool? ?? false,

// ConfigState.toJson:
'email_otp_globally_visible': emailOtpGloballyVisible,
```

Sourced from the Firestore global `config/*` document. Hydrated by `ConfigCubit` on app startup.

---

## LocalKeys *(modified — three new keys)*

```dart
// In lib/core/local_db/local_db_repo.dart, alongside the existing constants:
class LocalKeys {
  // existing keys: token, user, last_otp_request, last_otp_phone, rememberMe, seenFeaturedEvents
  static const String last_email_otp_request = 'last_email_otp_request';
  static const String last_email_otp_email = 'last_email_otp_email';
  static const String last_login_mode = 'last_login_mode';   // "sms" | "email"
}
```

Values:
| Key | Type | Notes |
|---|---|---|
| `last_email_otp_request` | `int` (epoch millis) | Set on every `/send` success; deleted on `/verify` success or `code_expired` |
| `last_email_otp_email` | `String` | The email the cooldown applies to (different emails → independent cooldowns) |
| `last_login_mode` | `String` | `"sms"` or `"email"`; set when user submits Send; read on `initState` to pre-select tab |

---

## MailDocument *(server-written, read by Firebase Extension — documented for backend ↔ extension contract)*

```text
Firestore path: mail/{autoId}

{
  to: [string],                            # one entry: the user's email
  message: {
    subject: string,                       # rendered from email_templates/email_otp_{lang}.subject_template
    html: string,                          # rendered HTML body with {{code}} substituted
    text: string,                          # plain-text fallback
  },

  # Written by the extension (server-observable, not by us):
  delivery: {
    state: "PENDING" | "PROCESSING" | "SUCCESS" | "ERROR",
    attempts: int,
    error: string?,
    info: {
      messageId: string,
      accepted: string[],
      rejected: string[],
      pending: string[],
    }?,
    endTime: timestamp?,
  }
}
```

**Mobile never reads this collection.** It is documented here purely as the backend ↔ extension contract.

---

## EmailTemplate *(server-side Firestore doc — documented for backend reference)*

```text
Firestore path: email_templates/email_otp_pt  (and _en, _ar)

{
  subject_template: string,    # e.g., "Seu código Criarte: {{code}}"
  html_template: string,       # full HTML body with {{code}} placeholder
  text_template: string,
  updated_at: timestamp,
}
```

Backend reads on startup (with a cache invalidation listener) and substitutes `{{code}}` per request before writing to `mail/{autoId}`. Admin web edits these without a release.

---

## Entity relationships

```text
LoginScreen ──► tab toggle (sms | email) ──► state.mode (UI-only)
                                          │
                                          └─► persists last_login_mode (Hive)

EmailTab (user types email, taps Send)
  ──► OTPBloc.requestEmailOTP(email)
        ──► LoginRepository.requestEmailOTP(email)
              ──► POST /auth/email-otp/send  { email, lang }
              ◄── 200 { masked_email, retry_after }
        ──► writes last_email_otp_request, last_email_otp_email
        ──► sets currentMode = email, currentMaskedEmail = masked_email
        ──► emits OTPReady

(backend, async)
  /send handler ──► generates 6-digit code, hashes it
                ──► stores (email_hash, otp_hash, school_id, expires_at, attempts) in email_otps
                ──► reads email_templates/email_otp_{lang}
                ──► writes mail/{autoId} with rendered body
  Firebase Extension picks up mail/{autoId} ──► sends via SendGrid SMTP
                                              ──► writes delivery.state back into the doc

OTPScreen (user types 6-digit code)
  ──► OTPBloc.confirmEmailOTP(email, code)
        ──► LoginRepository.confirmEmailOTP(email, code)
              ──► POST /auth/email-otp/verify  { email, code }
              ◄── 200 { access_token, data: <UserModel> }
        ──► UserBloc.loggedIn(user)
        ──► deletes last_email_otp_request / last_email_otp_email
        ──► emits OTPSuccess
        ──► LoginScreen listener navigates to MainScreen or YourAccountUnderReviewScreen
```
