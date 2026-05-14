---
status: migrated
feature: otp
migrated_from: lib/features/otp/
migrated_date: 2026-05-14
---

# Implementation Plan: OTP

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

OTP verification screen that completes the phone-OTP login flow. Owns no repository or REST endpoint of its own — it consumes `LoginRepository.confirmOTP` (Firebase credential exchange) and `LoginRepository.login` (Criarte session materialization). 8 .dart files. Several broken pieces in `OTPBloc` (commented-out cooldown timer, raw `print` calls, unused events), plus typo'd filenames and likely-dead `otp_response.dart` and `confirm_otp_requset.dart`.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `OTPBloc` is a `Cubit<OTPState>` despite the unused `otp_event.dart`
- `pin_code_fields` 8.0 — 6-cell PIN UI
- `firebase_auth` 5.5 — credential exchange via `LoginRepository`
- `hive` 2 + `LocalDatabaseRepo` — persists `rememberMe`
- `country_picker` 2.0 — unused import (carried over from login screen)

**Storage**: Hive (`LocalKeys.rememberMe`, plus the cleanup of `last_otp_request` / `last_otp_phone` on success).

**Testing**: None. No `test/features/otp/`.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **`presentation/` only** — no `data_sources/`, no `models/` outside the `models/` folder.

**Performance Goals**: Auto-submit fires within ~50 ms of the 6th digit being typed.

**Constraints**:

- `verificationId` lives in [LoginImpl](../../lib/features/login/data_sources/login_impl.dart) (the `LazySingleton` repo), not in `OTPBloc`. A `verifyPhoneNumber → ... → OTPBloc.confirmSMSCode` flow that crosses a process restart will lose the ID.
- The screen depends on the `LoginBloc` from the previous screen being alive in the navigator (it reads `LoginFailure` via `BlocSelector`). Disposing `LoginScreen` before OTP completes would break error display.

**Scale/Scope**: 8 .dart files (4 are models, 2 of which appear dead); ~370 LOC in the screen alone.

## Constitution Check

- [x] **I. Feature-First Layout** — code is under `lib/features/otp/{models,presentation/bloc}`. No `data_sources/` because there is no repository of its own.
- [x] **II. Dependency Direction** — ✓ OTP follows the **central-registration** pattern (one of three patterns acknowledged by [constitution v1.2.0 principle II](../../.specify/memory/constitution.md)): `OTPBloc` is registered in [lib/core/dependency_injection/di.dart:87](../../lib/core/dependency_injection/di.dart#L87) because OTP owns no repository (it consumes `LoginRepository`). When/if OTP grows its own repo (e.g., a dedicated `revoke_device_token` endpoint owner), promote to `otp_di.dart` per the constitution.
- [x] **III. Networking Contract** — N/A directly. Indirectly correct via `LoginRepository`.
- [x] **IV. Persistence Discipline** — Hive access through `LocalDatabaseRepo`. ✓
- [x] **V. Flavor Branching** — no flavor branches in this feature. ✓
- [x] **VI. Localization** — all strings via `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — honored in `OTPSuccess` listener. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `flutter_screenutil` + `context.colors.*` throughout. ✓

## Project Structure

### Source Code (existing)

```text
lib/features/otp/
├── models/
│   ├── otp_requset.dart                # ⚠️ filename typo
│   ├── otp_error_model.dart
│   ├── confirm_otp_requset.dart        # ⚠️ likely dead code, typo'd
│   └── otp_response.dart               # ⚠️ likely dead code
└── presentation/
    ├── otp_screen.dart                 # PIN field + resend + approval-gate listener
    └── bloc/
        ├── otp_bloc.dart               # Cubit<OTPState>
        ├── otp_event.dart              # almost entirely commented out
        └── otp_state.dart              # sealed
```

### Cross-feature touch points

- **[lib/features/login/](../../lib/features/login/)** — shares `LoginRepository`; reads `LoginFailure` from `LoginBloc` in the navigator stack.
- **[lib/features/main/](../../lib/features/main/)** — destination on success when approved.
- **[lib/features/your_account_under_review/](../../lib/features/your_account_under_review/)** — destination on success when pending.
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — `UserBloc.get.loggedIn(user)` called from `_successOTP`.

**Structure Decision**: Standard layout minus `data_sources/` (intentional: OTP has no REST endpoint of its own). The dead `confirm_otp_requset.dart` and `otp_response.dart` should be deleted; typo'd filenames renamed.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| ~~No feature-root `_di.dart`~~ | ✅ **Resolved 2026-05-14** by [constitution v1.2.0](../../.specify/memory/constitution.md#amendment-log): principle II now explicitly allows central registration for thin features. OTP's current placement is correct. | — |
| `verificationId` held in `LoginImpl` singleton instead of `OTPBloc` state | Matches how Firebase phone-auth presents the token — the same `LoginImpl` instance that called `verifyPhoneNumber` later calls `signInWithCredential`. | Moving the ID into `OTPBloc` would require either passing it down explicitly or duplicating `LoginRepository.requestOTP` ownership. Acceptable as-is. |
| ~~Commented-out cooldown timer~~ | ✅ **Resolved 2026-05-14** by [T-fix-1](tasks.md): `_startTimer` added and wired at three sites. | — |
| Screen reads both `OTPBloc` *and* `LoginBloc` for error display | Allows the OTP screen to surface upstream login errors (timeout, verification-failed) that arrive after navigation. | Move error propagation into `OTPBloc` (subscribe to `LoginBloc.stream` or invert ownership) so the screen has a single source. See [tasks.md → T-fix-2](tasks.md). |
