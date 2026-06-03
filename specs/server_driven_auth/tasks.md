# Tasks — Server-Driven Authentication

**Feature**: `server_driven_auth` · **Branch**: `ahmed_nour_` · **Date**: 2026-06-01

Format: `[ID] [P] [Area] [Story] Description`. `[P]` = parallel-safe (no shared file with other `[P]` in the same wave). Story tags map to `spec.md` user stories: `[US1]…[US5]`, `[X]` cross-cutting. Tick `[x]` and append the commit/PR reference when shipping; **do not delete** ticked items.

> Two parallel work tracks: **Mobile (this repo)** and **Backend (other repo)**. Backend tasks here are reproduced from [contracts/integration-contract.md §2](contracts/integration-contract.md) so the dependency order is visible in one place; the backend team owns and tracks them in their own repo's task tracker.

---

## Wave 0 — Pre-flight (must finish first)

- [ ] **T-000** [Backend] [X] Confirm `users` vs `app_users` table choice with mobile team. Required before writing the migration. *(Est: 0.25 d)*
- [ ] **T-001** [Product] [X] Drop the Gmail address + 16-char App Password into the backend `.env`. Verify a "Hello World" Mailable sends. *(Est: 0.5 d)*
- [ ] **T-002** [Product] [X] Add `server_driven_auth_enabled: bool` field (default `false`) to the org-wide Firestore `config/*` doc. *(Est: 0.1 d)*

## Wave 1 — Mobile data layer (parallel with Wave 1 backend)

- [ ] **T-100** [Mobile] [X] Create `lib/features/server_driven_auth/` folder skeleton with `presentation/`, `data_sources/`, `models/`, `dispatcher/`, `presentation/bloc/`, `presentation/widgets/`. *(Est: 0.1 d)*
- [ ] **T-101** [P] [Mobile] [X] Add `AuthAction` enum + `fromWire` parser in `models/auth_action.dart`. **Case-sensitive exact match** to the 8 spec strings, fallback `unknown`. *(Est: 0.25 d)*
- [ ] **T-102** [P] [Mobile] [X] Add request models (`CheckIdentifierRequest`, `SelfRegisterRequest`, `SetPasswordRequest`, `LoginRequest`, `ForgotPasswordRequest`, `OtpVerifyRequest`) with `toJson`. *(Est: 0.5 d)*
- [ ] **T-103** [P] [Mobile] [X] Add `AuthActionResponse.fromJson` + `AuthErrorResponse.fromJson`. *(Est: 0.25 d)*
- [ ] **T-104** [Mobile] [X] Create `ServerDrivenAuthRepository` (abstract) with the 8 method signatures from data-model.md §2.5. *(Est: 0.25 d)*
- [ ] **T-105** [Mobile] [X] Create `ServerDrivenAuthImpl` wiring the 8 endpoints through `NetworkClient.handleRequest → Either<Failure, T>`. Mirror the pattern in [login_impl.dart](../../lib/features/login/data_sources/login_impl.dart). Terminal endpoints (`set-initial-password`, `login`) parse via `UserModel.fromJson`; envelope endpoints parse via `AuthActionResponse.fromJson`. *(Est: 1 d)*
- [ ] **T-106** [Mobile] [X] Create `server_driven_auth_di.dart` implementing `DependencyInjection`. Register `ServerDrivenAuthRepository` as a lazy singleton; the cubit as a factory. Wire into `lib/init_dependencies.dart`. *(Est: 0.25 d)*

## Wave 2 — Mobile localization + config

- [ ] **T-200** [Mobile] [X] Add ~35 `sda_*` keys to `lib/core/localization/localization_keys.dart`. *(Est: 0.25 d)*
- [ ] **T-201** [P] [Mobile] [X] Add PT-BR translations to `assets/langs/pt.json`. *(Est: 0.25 d)*
- [ ] **T-202** [P] [Mobile] [X] Add EN translations to `assets/langs/en.json`. *(Est: 0.25 d)*
- [ ] **T-203** [P] [Mobile] [X] Add AR placeholder entries to `assets/langs/ar.json`. *(Est: 0.1 d)*
- [ ] **T-204** [Mobile] [X] Add `serverDrivenAuthEnabled: bool` (default `false`) to `ConfigState` with `toJson`/`fromJson` round-trip; verify HydratedBloc cold-start preserves it. *(Est: 0.5 d)*
- [ ] **T-205** [P] [Mobile] [X] Extend `NetworkClient._redactBody` allowlist to cover all 8 `auth/*` endpoints — phone, email, password, code, temp_token. Spot-check via Crashlytics in staging. *(Est: 0.25 d)*

## Wave 3 — Mobile dispatcher + cubit

- [ ] **T-300** [Mobile] [X] Implement `AuthActionDispatcher` mapping all 9 `AuthAction` cases (8 + `unknown`) to navigation/state. **No widget may branch on `action` strings.** *(Est: 0.5 d)*
- [ ] **T-301** [Mobile] [X] [US1][US2][US3][US4][US5] Implement `ServerDrivenAuthCubit` with one method per endpoint, all returning via the dispatcher on success and via `ServerDrivenAuthFailure(localizedKey)` on error. Map error `code` → key per [data-model.md §4](data-model.md). *(Est: 1 d)*
- [ ] **T-302** [P] [Mobile] [X] Implement shared widgets: `password_field.dart`, `otp_pin.dart` (wraps `pin_code_fields` with 60s resend timer), `inline_forgot_button.dart`. *(Est: 0.5 d)*

## Wave 4 — Mobile screens (parallel across screens; common cubit/dispatcher already done)

- [ ] **T-400** [Mobile] [US1][US3][US4][US5] Build `LoginScreen`: phone field + Next + state-driven inline password reveal on `LoginPasswordRequired` (no navigation) + "Forgot password?" inline + "Create new account" link at bottom. Approval gate on terminal success. *(Est: 1 d)*
- [ ] **T-401** [P] [Mobile] [US2] Build `SelfRegisterScreen` with name/phone/email/password/confirm fields + client-side validation. *(Est: 0.5 d)*
- [ ] **T-402** [P] [Mobile] [US1] Build `SetInitialPasswordScreen` wrapped in `PopScope(canPop: false)`. *(Est: 0.5 d)*
- [ ] **T-403** [P] [Mobile] [US2] Build `EmailOtpScreen` (registration). 60s resend timer. *(Est: 0.5 d)*
- [ ] **T-404** [P] [Mobile] [US2][US4] Build `PendingApprovalScreen` (delegating styling/content to existing `YourAccountUnderReviewScreen` for visual consistency). *(Est: 0.25 d)*
- [ ] **T-405** [P] [Mobile] [US5] Build `ForgotPasswordEmailScreen` (single email field + Send code). *(Est: 0.25 d)*
- [ ] **T-406** [P] [Mobile] [US5] Build `ResetOtpScreen` (distinct from EmailOtpScreen). 60s resend timer. *(Est: 0.5 d)*
- [ ] **T-407** [P] [Mobile] [US5] Build `SetNewPasswordScreen` wrapped in `PopScope(canPop: false)` once user is past OTP verify. On success: clear stack → `LoginScreen` + success snackbar. *(Est: 0.5 d)*

## Wave 5 — Mobile flag-gated routing

- [ ] **T-500** [Mobile] [X] In `SplashScreen` (and `OnBoardScreen` terminals), route to the new `server_driven_auth/presentation/login_screen.dart` when `ConfigCubit.state.serverDrivenAuthEnabled == true`, else to the legacy `login/presentation/login_screen.dart`. Do not modify the legacy screen. *(Est: 0.5 d)*
- [ ] **T-501** [Mobile] [X] Verify `flutter analyze` clean on both flavors. Build `apk` + `appbundle` on both flavors with the flag both `true` and `false`. *(Est: 0.5 d)*

## Wave 6 — Backend (other repo; mirrored from contracts/integration-contract.md §2)

- [ ] **T-600** [Backend] [X] Migration: `users` changes + backfill + indexes ([contracts/database-changes.md §1](contracts/database-changes.md)). *(Est: 0.5 d)*
- [ ] **T-601** [Backend] [X] Migration: `password_reset_otps` + `email_verification_otps` + temp-token store ([§2-4](contracts/database-changes.md)). *(Est: 0.25 d)*
- [ ] **T-602** [Backend] [X] `users.token_version` + JWT middleware update for session invalidation ([§5](contracts/database-changes.md)). *(Est: 0.5 d)*
- [ ] **T-603** [Backend] [X] `POST auth/check-identifier` controller + Form Request ([contracts/rest-endpoints.md §1](contracts/rest-endpoints.md)). *(Est: 0.5 d)*
- [ ] **T-604** [Backend] [X] `POST auth/set-initial-password` controller. *(Est: 0.5 d)*
- [ ] **T-605** [Backend] [X] `POST auth/self-register` controller including the `EMAIL_OTP_ENABLED` branch. *(Est: 0.5 d)*
- [ ] **T-606** [Backend] [X] `POST auth/verify-email-otp` controller. *(Est: 0.5 d)*
- [ ] **T-607** [Backend] [X] `POST auth/login` extended with password field + uniform error envelope. *(Est: 0.5 d)*
- [ ] **T-608** [Backend] [X] `POST auth/forgot-password` controller including the `EMAIL_OTP_ENABLED` branch + enumeration prevention. *(Est: 0.5 d)*
- [ ] **T-609** [Backend] [X] `POST auth/verify-reset-otp` controller. *(Est: 0.5 d)*
- [ ] **T-610** [Backend] [X] `POST auth/reset-password` controller + `token_version` bump. *(Est: 0.5 d)*
- [ ] **T-611** [Backend] [X] `OtpMail implements ShouldQueue` + 3 blade views + 3 `lang/{pt,en,ar}/auth_otp.php` files ([contracts/email-otp.md §2, §4](contracts/email-otp.md)). *(Est: 0.5 d)*
- [ ] **T-612** [Backend] [X] `config/auth.php` + `EMAIL_OTP_ENABLED` env wiring + `.env.example` comment block ([contracts/email-otp.md §3](contracts/email-otp.md)). *(Est: 0.25 d)*
- [ ] **T-613** [Backend] [X] `auth:check-config` artisan command (warns when `APP_ENV=production AND email_otp_enabled = false`). *(Est: 0.25 d)*
- [ ] **T-614** [Backend] [X] Warning log line on every flag-bypassed request. *(Est: 0.1 d)*
- [ ] **T-615** [Backend] [X] Rate-limit rules per [contracts/security.md §1](contracts/security.md). *(Est: 0.5 d)*
- [ ] **T-616** [Backend] [X] Enumeration prevention: `check-identifier` returns `200 NOT_FOUND`; `forgot-password` returns identical shape regardless of email existence; constant-time login. *(Est: 0.25 d)*
- [ ] **T-617** [Backend] [X] Log discipline: ensure no plaintext PII / secrets in logs; hashed bucket keys. *(Est: 0.25 d)*
- [ ] **T-618** [Backend] [X] Update Botble admin to honor the new `status` enum (replace any `is_active` filters). Smoke-test admin login on staging. *(Est: 0.5 d)*

## Wave 7 — QA + cutover

- [ ] **T-700** [QA] [X] All 5 scenarios end-to-end on staging, both flavors, `server_driven_auth_enabled = true`, `EMAIL_OTP_ENABLED = true`. *(Est: 1 d)*
- [ ] **T-701** [QA] [X] Flag matrix: `EMAIL_OTP_ENABLED` `true → false → true` (with `php artisan config:cache` between flips). Verify each branch in [contracts/email-otp.md §3](contracts/email-otp.md). *(Est: 0.5 d)*
- [ ] **T-702** [QA] [X] Rollout-flag matrix: `server_driven_auth_enabled` `false → true`. Verify legacy login byte-for-behavior identical when off. *(Est: 0.5 d)*
- [ ] **T-703** [QA] [X] Approval-gate audit: `is_approval = false` test user on every terminal-JWT path → `PendingApprovalScreen` (not `MainScreen`). *(Est: 0.25 d)*
- [ ] **T-704** [QA] [X] Crashlytics audit: 100+ staging events, zero PII leaks. *(Est: 0.5 d)*
- [ ] **T-705** [QA] [X] Enumeration audit: `forgot-password` with two emails (one real, one fabricated) → identical response shape and timing. *(Est: 0.25 d)*
- [ ] **T-706** [Product] [X] Pick pilot school. Flip `server_driven_auth_enabled = true` on that school's config. Monitor 7 days. *(Est: 0.25 d up-front)*
- [ ] **T-707** [Product] [X] After 7-day soak: expand flag to additional schools.

## Wave 8 — Post-cutover cleanup *(only after a successful 7-day pilot)*

- [ ] **T-800** [Mobile] [X] Delete `lib/features/login/`, `lib/features/otp/`, `lib/features/register/` legacy auth code paths. Update `lib/init_dependencies.dart` and `lib/my_app.dart`. *(Est: 1 d)*
- [ ] **T-801** [Mobile] [X] Remove `firebase_auth` from `pubspec.yaml` if no other path depends on it (verify the rest of Firebase — `firebase_core`, `cloud_firestore`, `firebase_messaging`, `firebase_storage`, `firebase_crashlytics`, `firebase_app_check` — still link). *(Est: 0.25 d; check first)*
- [ ] **T-802** [Backend] [X] Deprecate `auth/login-with-email`. *(Est: 0.25 d)*
- [ ] **T-803** [Mobile] [X] Update sibling specs (`login/`, `otp/`, `register/`) status to `deprecated` and add a "superseded by server_driven_auth" banner. *(Est: 0.5 d)*
- [ ] **T-804** [Backend] [X] Daily purge job for OTP rows + consumed temp tokens > 24h old. *(Est: 0.5 d)*

## Wave 9 — Follow-ups *(not blocking pilot)*

- [ ] **T-900** [Mobile] [X] Add Bloc-test coverage for `ServerDrivenAuthCubit`: one test per action mapping. *(Est: 1 d)*
- [ ] **T-901** [Mobile] [X] Add widget test for `LoginScreen` inline-reveal transition (no navigation, keyboard stays open). *(Est: 0.5 d)*
- [ ] **T-902** [Mobile] [X] Evaluate `flutter_secure_storage` as a follow-up hardening; currently JWT lives in HydratedBloc state (FR-SDA-15, spec.md §Deviations item 2). *(Est: 1 d if pursued)*
- [ ] **T-903** [Backend] [X] Consider polymorphic `otp_codes(kind)` table to fold registration + reset OTPs (Option B in [contracts/database-changes.md §3](contracts/database-changes.md)). *(Est: 1 d if pursued)*
- [ ] **T-904** [Product] [X] Decide whether social login (Google/FB/Apple) remains visible under the server-driven flow. *(Est: discussion)*
- [ ] **T-905** [Mobile] [X] Biometric login on top of `REQUIRE_PASSWORD` — coordinate with the `phone_password_login` draft.

---

## Critical-path summary

```
T-000, T-001, T-002 (pre-flight, 1 day, parallel)
   │
   ├──► Mobile: T-100 → T-101..103 [P] → T-104 → T-105 → T-106            (~3 d)
   │       └──► T-200 → T-201..203 [P], T-204, T-205 [P]                   (~1.5 d)
   │              └──► T-300, T-301, T-302 [P]                              (~2 d)
   │                     └──► T-400 → T-401..407 [P]                        (~3 d)
   │                            └──► T-500, T-501                            (~1 d)
   │
   └──► Backend: T-600 → T-601 → T-602                                       (~1.25 d)
           └──► T-603..610 [P among controllers]                              (~3 d)
                  └──► T-611, T-612, T-613, T-614, T-615..617, T-618          (~3 d)
                         │
                         ▼
                  Both tracks converge at Wave 7 (QA + pilot) — ~3 d
                         │
                         ▼
                  Wave 8 (cleanup) — after 7-day pilot soak
```

Mobile track ~10 dev-days. Backend track ~7 dev-days. Both parallel-feasible from day 1 because mobile runs dark behind `server_driven_auth_enabled = false`.
