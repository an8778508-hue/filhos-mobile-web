# Implementation Plan: Server-Driven Authentication

**Branch**: `ahmed_nour_` | **Date**: 2026-06-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/server_driven_auth/spec.md`

## Summary

Replace the current client-driven login (Flutter infers account state from password-field emptiness, account-type from flavor, etc.) with a **server-driven** model. The app hits one unified entry endpoint `auth/check-identifier` and obeys the returned `action` string. Eight actions cover five canonical scenarios: admin-created first login (`CREATE_NEW_PASSWORD`), inline password reveal for active users (`REQUIRE_PASSWORD`), self-registration + email OTP verification (`VERIFY_EMAIL_OTP` → `GO_TO_PENDING_APPROVAL`), forgot-password (`VERIFY_RESET_OTP` → `SET_NEW_PASSWORD`), and the terminal `NOT_FOUND` / `ACCOUNT_SUSPENDED`.

The Laravel + Botble backend that owns these endpoints lives in a **separate repository** and is not modified by this PR. The backend half is delivered as a complete **integration contract** in [contracts/](contracts/) for that team to implement. The mobile half is implemented here: nine screens, a single `AuthActionDispatcher`, a new feature `lib/features/server_driven_auth/`, and a `ConfigCubit.serverDrivenAuthEnabled` flag (default `false`) that gates the new flow behind a rollout switch. Until the flag flips, the legacy Firebase phone-SMS login keeps running unchanged — **no code is deleted**, deliberately deviating from the master prompt's "delete all old auth" because the backend endpoints don't exist yet and a hard cutover would brick login.

Implementation approach: **new feature folder + flag-gated routing entry**. `SplashScreen` and `OnBoardScreen` already route into `LoginScreen`; when the flag is on, that entry is rerouted into `lib/features/server_driven_auth/presentation/login_screen.dart` instead of the legacy one. The new screens reuse existing primitives (`UserBloc.loggedIn`, `NetworkClient.handleRequest`, `LocalDatabaseRepo`, the approval gate, the localization pipeline, `flutter_screenutil`, `context.colors.*`). JWT storage stays in `UserBloc` — the master prompt's `flutter_secure_storage` is **declined** with rationale in spec.md §Deviations.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**: `flutter_bloc` 9 (HydratedCubit + Cubit), `get_it` 8, `dio` 5, `hive` 2 (via `LocalDatabaseRepo`), `dartz` 0.10 (`Either<Failure, T>`), `flutter_screenutil`, existing `pin_code_fields` (OTP entry). Firebase remains in `pubspec.yaml` for chat / FCM / Crashlytics; Firebase Auth stays linked **only** for the legacy SMS-OTP path that runs when the flag is off.

**New Dependencies**: **None.** `flutter_secure_storage` is deliberately not added — JWT continues to live in `UserBloc.state.user.accessToken`, persisted by the existing HydratedCubit (Constitution Principle IV; spec.md §Deviations).

**Storage**:
- JWT in `UserBloc.state.user.accessToken` (HydratedCubit, auto-persisted).
- New `ConfigCubit.serverDrivenAuthEnabled` field (HydratedCubit, auto-persisted via `toJson`/`fromJson`).
- No new Hive keys — `temp_token`s are in-memory only by design (FR-SDA-16).

**Testing**: No unit-test suite exists today. This feature ships without tests in v1; a follow-up tasks.md item proposes Bloc-test coverage for the dispatcher and a widget test for `LoginScreen`'s inline-reveal transition.

**Target Platform**: iOS + Android, **both flavors** (`parents` and `professores`). Behaviour is identical across flavors except for the `role` value sent at `check-identifier` (derived from `context.isProfessors`).

**Performance Goals**:
- `check-identifier` happy path round-trip ≤ 600 ms on a normal 4G connection (server p95, mobile observed).
- The inline password reveal in `LoginScreen` MUST be a state transition only (no `Navigator.push`), so the keyboard does not dismiss/re-show and there is zero visible flicker.
- Final JWT response from `set-initial-password` / `login` parses straight into `UserModel.fromJson` (no transform layer).

**Constraints**:
- Mobile must perform **zero** local account-state inference (FR-SDA-03, SC-SDA-05).
- All 8 endpoints via `NetworkClient.handleRequest` returning `Either<Failure, T>` (Constitution Principle III, NON-NEGOTIABLE).
- Token persistence via `UserBloc` only — no parallel store (Principle IV, FR-SDA-15).
- Approval gate (`isApproval == false` → `PendingApprovalScreen` / existing `YourAccountUnderReviewScreen`) honored on every JWT issuance (Principle VIII).
- PII redaction in Crashlytics extended to the 8 new endpoints (FR-SDA-20).

**Scale/Scope**: 1 new feature folder, 1 dispatcher, 9 screens (the existing `MainScreen` is reused as Home; the new `PendingApprovalScreen` is a thin variant of the existing `YourAccountUnderReviewScreen` and may delegate to it), 8 data-layer methods, ~10 model classes, ~35 new localization keys, 1 new `ConfigState` field, 1 new redaction allowlist entry, 0 deletions in the legacy auth path.

## Constitution Check

*Pre-design gate — verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md) v1.3.0.*

- [x] **I. Feature-First Layout** — new code lives under `lib/features/server_driven_auth/` with the standard `presentation/`, `data_sources/`, `models/`, `dispatcher/` substructure mirroring `lib/features/login/`. DI is co-located (`server_driven_auth_di.dart`), matching the `login_di.dart` pattern.
- [x] **II. Dependency Direction** — only depends on `lib/core/` (NetworkClient, LocalDatabaseRepo, UserBloc, ConfigCubit, localization, theme, components). No cross-feature imports. Legacy `lib/features/login/` is **not** imported by the new code; both run side by side under the flag.
- [x] **III. Networking Contract (NON-NEGOTIABLE)** — all 8 endpoints go through `NetworkClient.handleRequest` returning `Either<Failure, T>`. The interceptor attaches `school` / `school_id` / `lang` headers automatically (pre-login endpoints ignore the first two; `lang` is honored for OTP email language). Base URL from `api_const.dart`. Crashlytics redaction extended.
- [x] **IV. Persistence Discipline** — Hive only via `LocalDatabaseRepo` (no new keys this version). HydratedCubit state for the new `ConfigCubit.serverDrivenAuthEnabled` field with toJson/fromJson round-trip. JWT in `UserBloc.state.user.accessToken` — no parallel store.
- [x] **V. Flavor Branching** — role sent at `check-identifier` derived from `context.isProfessors ? 'teacher' : 'parent'`. No screens fork on flavor. Both flavors verified to build + run.
- [x] **VI. Localization** — ~35 new `sda_*` keys in `localization_keys.dart` with PT-BR primary, EN parallel, AR placeholders. All user-visible strings localized (FR-SDA-19). Strings remain remote-overridable via Firestore `config/*`.
- [x] **VII. Realtime Surfaces Source of Truth (NON-NEGOTIABLE)** — not applicable. Auth is REST only. Chat / diary reactions / diary comments stay on Firestore; this feature does not touch them.
- [x] **VIII. Approval Gate (NON-NEGOTIABLE)** — every terminal JWT path (`set-initial-password`, `login`) routes through the existing `isApproval` gate; `PendingApprovalScreen` honors it for `pending` users. Deep-links / push handlers added later MUST respect this — documented in `tasks.md`.
- [x] **IX. Medicine Reminders** — not applicable.
- [x] **X. Theming & Sizing** — `flutter_screenutil` 430×932; theme from `ConfigCubit.styling`; colors via `context.colors.*`; no hardcoded colors. Fonts: Gabarito (per existing convention).
- [x] **Quality Gates** — `flutter analyze` planned for both flavors. Release build planned before pilot flag flip.

No violations. Complexity Tracking section is blank.

*Post-design re-check*: No new violations surfaced. The only conscious deviation (vs. the master prompt) is `flutter_secure_storage` → existing `UserBloc` storage — that **strengthens** Principle IV compliance, not violates it.

## Project Structure

### Documentation (this feature)

```text
specs/server_driven_auth/
├── plan.md                              # This file
├── spec.md                              # FRs, scenarios, success criteria
├── data-model.md                        # Phase 1: entities, enums, request/response shapes
├── tasks.md                             # Phase 2: dependency-ordered checklist
├── quickstart.md                        # Phase 1: how to pick up implementation, run, toggle flags
└── contracts/                           # Phase 1: backend integration contract
    ├── rest-endpoints.md                # All 8 endpoints + action vocabulary
    ├── database-changes.md              # users + password_reset_otps + tokens
    ├── security.md                      # rate limits, scoped tokens, enumeration, sessions
    ├── email-otp.md                     # Gmail SMTP + EMAIL_OTP_ENABLED flag
    └── integration-contract.md          # per-team hand-off + requested API changes
```

### Source Code (changes by file)

```text
lib/features/server_driven_auth/                ← NEW FEATURE FOLDER
├── server_driven_auth_di.dart                  ← NEW: DependencyInjection wire-up
├── dispatcher/
│   └── auth_action_dispatcher.dart             ← NEW: maps the 8 actions → nav/state
├── data_sources/
│   ├── server_driven_auth_repository.dart      ← NEW: abstract repo, 8 methods
│   └── server_driven_auth_impl.dart            ← NEW: NetworkClient.handleRequest impls
├── models/
│   ├── auth_action.dart                        ← NEW: enum + parser
│   ├── auth_action_response.dart               ← NEW: uniform envelope {action, tempToken, expiresIn, user}
│   ├── check_identifier_request.dart           ← NEW
│   ├── self_register_request.dart              ← NEW
│   ├── set_password_request.dart               ← NEW: used by set-initial + reset-password
│   ├── login_request.dart                      ← NEW: {phone, country_code, password, role, device_token}
│   ├── forgot_password_request.dart            ← NEW
│   ├── otp_verify_request.dart                 ← NEW: {temp_token, code}
│   └── auth_error_response.dart                ← NEW: {error: {code, message}} mapping
├── presentation/
│   ├── bloc/
│   │   ├── server_driven_auth_cubit.dart       ← NEW: orchestrates dispatcher + repo
│   │   └── server_driven_auth_state.dart       ← NEW: states incl. LoginPasswordRequired
│   ├── login_screen.dart                       ← NEW: phone + inline password reveal + Forgot link + Create link
│   ├── self_register_screen.dart               ← NEW
│   ├── set_initial_password_screen.dart        ← NEW (PopScope canPop:false)
│   ├── email_otp_screen.dart                   ← NEW: registration OTP
│   ├── pending_approval_screen.dart            ← NEW: delegates to existing YourAccountUnderReviewScreen for now
│   ├── forgot_password_email_screen.dart       ← NEW
│   ├── reset_otp_screen.dart                   ← NEW: reset OTP (distinct from email_otp_screen)
│   ├── set_new_password_screen.dart            ← NEW (PopScope canPop:false)
│   └── widgets/
│       ├── password_field.dart                 ← NEW: shared between Set/Reset/Login inline
│       ├── otp_pin.dart                        ← NEW (wraps pin_code_fields with 60s resend)
│       └── inline_forgot_button.dart           ← NEW: appears only on LoginPasswordRequired

lib/core/
├── config/
│   └── cubit/ (existing files)                 ← extend ConfigState with `serverDrivenAuthEnabled: bool` (default false); update toJson/fromJson
├── localization/
│   └── localization_keys.dart                  ← +~35 sda_* keys
└── network/
    └── network_client.dart                     ← extend _redactBody allowlist for /auth/check-identifier, /auth/set-initial-password, /auth/self-register, /auth/verify-email-otp, /auth/login (already there for the phone path — confirm), /auth/forgot-password, /auth/verify-reset-otp, /auth/reset-password

lib/features/splash/presentation/splash_screen.dart      ← if ConfigCubit.serverDrivenAuthEnabled == true, route post-language/onboard to the new login_screen instead of the legacy one
lib/features/onboard/presentation/onboard_screen.dart    ← same gate at "Skip" / "Next" terminals

lib/init_dependencies.dart                       ← register ServerDrivenAuthDi

assets/langs/
├── pt.json                                      ← ~35 translations (primary)
├── en.json                                      ← ~35 translations
└── ar.json                                      ← ~35 keys (placeholder OK)

TESTING.md                                       ← repo root: 5-scenario walkthrough + flag matrix
```

**Legacy auth code untouched (deliberate).** `lib/features/login/`, `lib/features/otp/`, `lib/features/register/`, `lib/features/your_account_under_review/`, and the Firebase Auth dependency stay in place. They run whenever `ConfigCubit.serverDrivenAuthEnabled == false`. The flag flip is the cutover; deletion happens in a follow-up PR once the backend is live and a pilot school has soaked for ≥ 7 days.

**DI**: `ServerDrivenAuthDi.register(di)` is added to `initDependecies()` in `lib/init_dependencies.dart` next to the existing `LoginDi.register(di)`. The new repo + cubit are GetIt-registered as singletons (`registerLazySingleton` for the repo, `registerFactory` for the cubit so each LoginScreen instance gets a fresh one).

**Server-side** (out of mobile scope, documented in [contracts/](contracts/)):
- 8 REST endpoints in the Laravel/Botble backend
- DB migration (nullable password, status enum, email_verified columns, OTP + temp-token tables)
- Queued Gmail-SMTP `OtpMail`
- `config/auth.php` + `EMAIL_OTP_ENABLED` flag + `auth:check-config` artisan command
- `users.token_version` for session invalidation on reset-password

## Complexity Tracking

| Deviation | Justification | Where documented |
|---|---|---|
| Master prompt says "delete all old auth, hard cutover." This plan keeps the legacy Firebase path and gates the new flow behind `serverDrivenAuthEnabled`. | The backend endpoints don't exist yet (separate repo). A hard cutover now would break login for every user. Product owner confirmed "flag on Firebase, pass not delete" on 2026-05-25. Old code removal is a tracked follow-up post-cutover. | spec.md §Deviations item 1; tasks.md Wave 7 |
| Master prompt says JWT in `flutter_secure_storage`. This plan keeps JWT in `UserBloc.state.user.accessToken`. | `flutter_secure_storage` is not a dependency; CLAUDE.md and Constitution Principle IV require Hive access only via `LocalDatabaseRepo` / HydratedBloc. Migrating to secure storage is a separate hardening item. | spec.md §Deviations item 2; FR-SDA-15 |
| Backend code is not written in this repo; it's documented as a hand-off. | The Laravel/Botble backend lives in a separate repository confirmed by the product owner. | spec.md §Scope note; contracts/integration-contract.md |
