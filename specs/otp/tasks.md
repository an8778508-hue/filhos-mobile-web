---
status: migrated
feature: otp
migrated_from: specs/features.md#otp--b
migrated_date: 2026-05-14
---

# Tasks: OTP

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#otp--b](../features.md#otp--b).

**Tests**: No test directory exists — test tasks are aspirational.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/otp/](../../lib/features/otp/) with `models/` + `presentation/bloc/`
- [x] T002 Reuse existing OTP-related localization keys (`phone_verification`, `enter_otp_that_sent_to`, `resend_again`, `did_not_receive_code`); no new keys needed
- [x] T003 ✅ DI placement resolved by [constitution v1.2.0 principle II](../../.specify/memory/constitution.md). OTP uses the central-registration pattern at [core/dependency_injection/di.dart:87](../../lib/core/dependency_injection/di.dart#L87); no feature-root `otp_di.dart` is required because OTP owns no repository.

## Phase 2: Foundational — ✅ Complete (with dead code)

- [x] T010 Define `OTPRequest`, `OTPErrorModel`, `OTPState` (sealed Cubit states)
- [x] T011 Implement `OTPBloc` (Cubit) with `requestOTP`, `resendOTP`, `confirmSMSCode`, and `_successOTP`
- [x] T012 Cross-feature handoff with `LoginRepository.confirmOTP` and `LoginRepository.login`

## Phase 3: User Story 1 — Enter and verify 6-digit code (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement [OTPScreen](../../lib/features/otp/presentation/otp_screen.dart) with 6-cell `PinCodeTextField`
- [x] T021 [US1] Auto-submit on 6th-digit input ([otp_screen.dart:244-250](../../lib/features/otp/presentation/otp_screen.dart#L244-L250))
- [x] T022 [US1] Approval-gate routing in `OTPSuccess` listener — main vs `your_account_under_review`
- [x] T023 [US1] `UserBloc.loggedIn(user)` fires inside `_successOTP` before `OTPSuccess` is emitted

## Phase 4: User Story 2 — Resend OTP (P2) — ✅ Complete (with bug)

- [x] T030 [US2] Add "Resend again" affordance below the pin field
- [x] T031 [US2] Wire `OTPBloc.resendOTP` → `requestOTP` with `rememberMe`
- [x] T032 [US2] Also call `LoginBloc.clearError()` on resend so stale `LoginFailure` doesn't leak

## Phase 5: User Story 3 — Persist "Remember me" (P3) — ✅ Complete

- [x] T040 [US3] Pass `rememberMe` from `LoginScreen` → `OTPScreen` → `OTPBloc.requestOTP`
- [x] T041 [US3] Persist `LocalKeys.rememberMe = true` inside `_successOTP`

---

## Phase 6: Gaps & cleanups

### Bugs / drift

- [x] **T-fix-1** **(P0)** [US2] ✅ **Fixed 2026-05-14** in [OTPBloc](../../lib/features/otp/presentation/bloc/otp_bloc.dart): `_startTimer()` method added (mirrors the working implementation in [LoginBloc._startTimer](../../lib/features/login/presentation/bloc/login_bloc.dart#L69-L86)). Wired at the three previously-commented call sites in `_init`, `requestOTP`, and the `onReady` callback. `pendingOTPTime` now decrements each second and clears `last_otp_request` + `last_otp_phone` when it hits 0. `close()` already cancels the timer (unchanged).

- [ ] **T-fix-2** **(P1)** [US1] OTP screen reads both `OTPBloc` and `LoginBloc` for error display ([otp_screen.dart:171-182](../../lib/features/otp/presentation/otp_screen.dart#L171-L182)). Consolidate by relaying upstream `LoginFailure` into `OTPBloc.state` so the screen subscribes to a single bloc.

- [ ] **T-fix-3** **(P1)** [US2] The `already_sent` branch in `OTPBloc.requestOTP` ([line 80-88](../../lib/features/otp/presentation/bloc/otp_bloc.dart#L80-L88)) emits a `Failure` **and** sets `ready.value = true`. Pick one signal — either treat as success-with-cooldown (no failure) or as failure (no `ready=true`). Mixed signal confuses the UI.

- [ ] **T-fix-4** **(P0)** [US1] *(from [features.md#otp--b](../features.md#otp--b))* Surface the SMS auto-fill suggestion on Android. `pin_code_fields` supports passing `autoDisposeControllers: false` plus a `useExternalAutoFillGroup` wrapper; alternatively use `smart_auth` / `sms_autofill` packages.

- [ ] **T-fix-5** **(P1)** [US1] *(from [features.md#otp--b](../features.md#otp--b))* Handle the "code expired" path explicitly. Today `invalid-verification-code` is the only failure code mapped; if Firebase returns `session-expired` after the auto-retrieval window, the user sees a generic `code: ''` message. Decide on copy and route to a re-request flow.

- [ ] **T-fix-6** **(P2)** [US2] *(from [features.md#otp--b](../features.md#otp--b))* Document the resend cooldown (uses `last_otp_request`). The Hive key is shared with `LoginBloc.requestOTP` — clarify ownership and lifetime.

### Code hygiene

- [ ] **T-cleanup-1** Delete dead code:
  - [models/confirm_otp_requset.dart](../../lib/features/otp/models/confirm_otp_requset.dart) — not referenced.
  - [models/otp_response.dart](../../lib/features/otp/models/otp_response.dart) — verify, then delete.
  - The entire [otp_event.dart](../../lib/features/otp/presentation/bloc/otp_event.dart) is a 24-line commented-out block. `OTPBloc` is a `Cubit`, so events were never wired. Delete the file and remove the `part 'otp_event.dart'` directive (already commented out at [otp_bloc.dart:14](../../lib/features/otp/presentation/bloc/otp_bloc.dart#L14)).
  - `CodeSentVerifyPhoneState` in [otp_state.dart:16](../../lib/features/otp/presentation/bloc/otp_state.dart#L16) is unused.

- [ ] **T-cleanup-2** Rename typo'd files:
  - `otp_requset.dart` → `otp_request.dart`
  - `confirm_otp_requset.dart` → delete instead (T-cleanup-1)

- [ ] **T-cleanup-3** Replace `print('OTPBloc.requestOTP ${l.code}');` at [otp_bloc.dart:102](../../lib/features/otp/presentation/bloc/otp_bloc.dart#L102) with a structured logger. Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about routing 146 print calls through one logger.

- [ ] **T-cleanup-4** Drop unused `country_picker` import from [otp_screen.dart:1](../../lib/features/otp/presentation/otp_screen.dart#L1).

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Cubit test: typing 6 digits triggers `confirmSMSCode` exactly once; wrong code emits `OTPFailure`.
- [ ] **T-test-2** [P] [US1] Widget test for the approval gate on `OTPSuccess`.
- [ ] **T-test-3** [P] [US2] Cubit test: `resendOTP` within cooldown emits `OTPFailure(already_sent)` and does NOT call `LoginRepository.requestOTP` (once T-fix-1 lands and the cooldown actually exists).

### Cross-feature

- [x] **T-cross-1** **(P1)** ✅ **Resolved 2026-05-14** by [constitution v1.2.0](../../.specify/memory/constitution.md#amendment-log). Principle II now explicitly allows central registration for thin features, plus sibling-co-located registration for tightly-coupled siblings (e.g., register inside `login_di.dart`). The "promote when a thin feature grows a domain" rule was added so this stays evolutionary.

---

## Notes

- This is a **migration** — `[x]` items are inferred from existing code + history, not re-verified one by one.
- T-cross-1 is the most consequential follow-up surfaced by this migration. It's not OTP-specific.
- The same `LoginRepository` is shared by `login`, `otp`, and `register`. If T-cross-1 (a) is chosen, the dependency graph at registration time needs care.
