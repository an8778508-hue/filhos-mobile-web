---
status: migrated
feature: login
migrated_from: lib/features/login/
migrated_date: 2026-05-14
---

# Implementation Plan: Login

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/login/spec.md](spec.md) and code in [lib/features/login/](../../lib/features/login/).

## Summary

Login is the entry point for both Criarte flavors. Primary path is phone + Firebase SMS OTP; secondary paths are Google / Facebook / Apple social and email + password. The feature is implemented (11 .dart files) but has several constitution drifts and unresolved P0/P1 items from [review.md](../review.md) — see [tasks.md](tasks.md).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `LoginBloc` is a `Cubit<LoginState>`
- `get_it` 8 — `LoginInjection` registered in [lib/init_dependencies.dart](../../lib/init_dependencies.dart)
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart) — handles auth headers, 401 interception, body redaction
- `dartz` — `Either<Failure, UserModel>` return type on repo methods
- `firebase_auth` 5.5 — phone OTP verification
- `firebase_messaging` 15.2 — FCM device token in login request body
- `google_sign_in` 6.3, `flutter_facebook_auth` 7.1, `sign_in_with_apple` 7.0 — social providers
- `country_picker` 2.0 — flag/code chooser
- `brasil_fields` 1.15 (project-wide) — used by `PhoneField`
- `hive` 2 + `hydrated_bloc` 10 — `UserBloc.loggedIn(...)` persists `UserState`
- `pin_code_fields` 8.0 — OTP screen (downstream)
- `flutter_screenutil` 5.9 — 430×932 design size

**Storage**:

- Hive (via [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart)): `last_otp_request` (epoch ms), `last_otp_phone` (string).
- HydratedBloc: `UserState` — round-trips `UserModel` JSON.

**Testing**: None today — no `test/` directory in the repo. The feature is operationally tested against staging.

**Target Platform**: iOS + Android, both flavors (`parents` / `professores`). Apple sign-in is iOS-only.

**Project Type**: Flutter mobile feature, follows feature-first layout.

**Performance Goals**: Login form interactive within 200 ms after `LoginScreen` builds; SMS round-trip dominated by Firebase + carrier (not under our control).

**Constraints**:

- Pre-login `UserBloc.user` is null; the `role` field cannot be sourced from it. Must come from the flavor binary.
- FCM token retrieval may fail on emulators without Google Play Services; debug-mode fallback path is required.
- Auth-related logs must redact tokens/Authorization headers — already wired in [NetworkClient._redactHeaders / _redactBody](../../lib/core/network/network_client.dart).

**Scale/Scope**: 11 .dart files, ~600 LOC. 4 server endpoints touched. 4 auth providers integrated.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code is under `lib/features/login/` with `presentation/{bloc,widgets}`, `data_sources/`, `models/`. Bloc lives under `presentation/bloc/`. ✓
- [x] **II. Dependency Direction** — `LoginInjection.init()` registered in `lib/init_dependencies.dart`. Login imports only from `lib/core/*` and adjacent auth-cluster features (`otp/`, `register/`, `privacy_policy/`, `terms_and_condtions/`, `main/`, `your_account_under_review/`). ⚠️ The cross-feature imports of `otp/`, `register/`, `main/`, `your_account_under_review/` from the login *screen* are navigation targets — acceptable per current code, but worth flagging at the [features.md cross-feature task](../features.md#cross-feature-tasks) about banning cross-feature absolute imports.
- [x] **III. Networking Contract** — all REST calls go through `NetworkClient.handleRequest` returning `Either<Failure, UserModel>`. ✓
- [x] **IV. Persistence Discipline** — Hive access goes through `LocalDatabaseRepo` (✓). `UserBloc` HydratedBloc state round-trips. ✓
- [x] **V. Flavor Branching** — ✓ All 4 remaining `mainKey.currentContext` sites in [login_impl.dart](../../lib/features/login/data_sources/login_impl.dart) replaced with `isProfessorsFlavor` on 2026-05-14 (T-fix-1). Repo-wide grep confirms no active references remain.
- [x] **VI. Localization** — every visible string routes through `LocalizationKeys.*.tr(context)`. No hardcoded copy. ✓
- [x] **VII. Chat Source of Truth** — N/A (no chat surface).
- [x] **VIII. Approval Gate** — `LoginSocialSuccess` and `LoginWithEmailSuccess` listeners check `UserBloc.get.state.user?.isApproval` before pushing main. Phone-OTP delegates the check to the OTP screen.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — all sizes use `.h`/`.w`/`.sp`/`.csh`/`.csw`; colors pulled from `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/login/
├── spec.md              # User scenarios, requirements, success criteria
├── plan.md              # This file
└── tasks.md             # Implementation tasks (mostly ✅; remaining gaps + cleanups)
```

### Source Code (existing)

```text
lib/features/login/
├── login_di.dart                                   # DependencyInjection — at feature root
├── data_sources/
│   ├── login_repository.dart                       # Abstract contract + endpoint constants
│   └── login_impl.dart                             # NetworkClient + Firebase Auth + social providers
├── models/
│   ├── login_requset.dart                          # ⚠️ filename typo: 'requset'
│   ├── login_response.dart                         # ⚠️ DEAD CODE: not referenced
│   └── login_email_paramaters.dart                 # ⚠️ filename typo: 'paramaters'
└── presentation/
    ├── login_screen.dart                           # Form + listeners + navigation
    ├── bloc/
    │   ├── login_bloc.dart                         # Cubit<LoginState>
    │   ├── login_event.dart                        # Mostly empty (Cubit, not Bloc)
    │   └── login_state.dart                        # LoginInitial/Loading/Ready/Failure/SocialSuccess/WithEmailSuccess
    └── widget/
        └── social_login_widget.dart                # Google/Facebook/Apple/email-toggle row
```

### Cross-feature touch points

- [lib/features/otp/](../../lib/features/otp/) — OTP screen receives `phone`, `phoneCode`, `countryCode`, `rememberMe` from login.
- [lib/features/register/](../../lib/features/register/) — register screen reachable from login footer; `RegisterBloc` is also registered by `LoginInjection`.
- [lib/features/your_account_under_review/](../../lib/features/your_account_under_review/) — destination when `isApproval == false`.
- [lib/features/main/](../../lib/features/main/) — destination when `isApproval == true`.
- [lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart) — `UserBloc.get.loggedIn(userModel)` is called on social/email success.

**Structure Decision**: Standard layout, no deviations except the two typo'd filenames and a dead `login_response.dart` model that should be removed in cleanup (see tasks.md).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| ~~`mainKey.currentContext?.isProfessors` in 4 sites of `login_impl.dart`~~ | ✅ **Resolved 2026-05-14** via T-fix-1. All 4 sites replaced with `isProfessorsFlavor`. | — |
| Hardcoded iOS Google OAuth client IDs in [login_impl.dart:218-228](../../lib/features/login/data_sources/login_impl.dart#L218-L228) | These are public client IDs (not secrets), so check-in is acceptable. But mixing them per-flavor inside `signInWithGoogle()` makes config impossible without a code change. | Move to `--dart-define` or per-flavor `Info.plist` / `google-services.json`; let the platform side surface the right ID. **See tasks.md T-fix-2.** |
| `_isDebugBypass` instance state in the LazySingleton `LoginImpl` | Allows mid-session toggling between debug and real OTP without re-instantiating the repo. | The flag is read only inside `kDebugMode` guards, so in release builds it can never be true. Acceptable; documented in [spec.md edge cases](spec.md#edge-cases). No action. |
