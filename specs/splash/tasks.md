---
status: migrated
feature: splash
migrated_from: specs/features.md#splash--b
migrated_date: 2026-05-14
---

# Tasks: Splash

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#splash--b](../features.md#splash--b).

**Tests**: No `test/` directory; test tasks are aspirational.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/splash/](../../lib/features/splash/) with `presentation/bloc/`
- [x] T002 No new localization keys needed (no user-visible text in this feature)
- [x] T003 ✅ DI placement resolved by [constitution v1.2.0 principle II](../../.specify/memory/constitution.md). Splash uses central registration; no feature-root `splash_di.dart` is required.

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `SplashEvent` (sealed) with `FetchSplashEvent`
- [x] T011 Define `SplashState` (sealed): `Initial / Loading / Success(hasUser) / Failure(Failure)`
- [x] T012 Implement `SplashBloc(this.userBloc, this.userRepo)`

## Phase 3: User Stories 1–3 — Boot routing (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Dispatch `FetchSplashEvent` on screen construction ([splash_screen.dart:34](../../lib/features/splash/presentation/splash_screen.dart#L34))
- [x] T021 [US2] Refresh user from server via `UserRepo.getUser()` when persisted user exists; overlay `copyWith(accessToken: oldToken)` before `UserBloc.loggedIn(refreshed)`
- [x] T022 [US1] Route to `ChooseLanguageScreen` when `!hasUser`
- [x] T023 [US2] Route to `MainScreen` when `hasUser && isApproval == true`
- [x] T024 [US3] Route to `YourAccountUnderReviewScreen` when `hasUser && isApproval == false`
- [x] T025 [all] 2-second `Timer` between `SplashSuccess` and navigation

---

## Phase 6: Gaps & cleanups

### Bugs / drift

- [ ] **T-fix-1** **(P0)** [US-all] *(from [features.md#splash--b](../features.md#splash--b))* Add a `Bootstrap` step that awaits `UserBloc` hydration **before** any network call. Today `FetchSplashEvent` may run before `UserBloc.fromJson` finishes. `UserBloc.fromJson` is null-guarded ([features.md cross-feature ✅](../features.md#cross-feature-tasks)) so it can't crash, but the first request from splash may still go out without `Authorization` if hydration is mid-flight. Promote the 2-second `Timer` to a *minimum-display-time* that also gates on a `hydrationCompleter`.

- [x] **T-fix-2** **(P1)** [US4] ✅ **Fixed 2026-05-14** in [splash_screen.dart](../../lib/features/splash/presentation/splash_screen.dart): on `SplashFailure`, after the SnackBar, the listener now routes on the **persisted** `UserBloc.state.user` after the 2-second timer — same approval-gate logic as `SplashSuccess(hasUser: true)`, with a fallback to `ChooseLanguageScreen` if persisted user is null. The user is no longer stranded by a transient refresh failure; the SnackBar still surfaces the underlying error message.

- [ ] **T-fix-3** **(P2)** [theming] *(from [features.md#splash--b](../features.md#splash--b))* Replace `Color(0xffF2F2F2)` at [splash_screen.dart:83](../../lib/features/splash/presentation/splash_screen.dart#L83) with a `context.colors.*` token (probably `divider` or a new `splashBackgroundTint`).

- [ ] **T-fix-4** **(P1)** [US-all] *(from [features.md#splash--b](../features.md#splash--b))* Add an explicit minimum-display-time so the splash doesn't flicker on fast cold starts. Couple with T-fix-1.

- [ ] **T-fix-5** **(P1)** [US-all] *(from [features.md#splash--b](../features.md#splash--b))* Surface a clear error state if `initDependecies()` fails — today silent.

- [ ] **T-fix-6** **(P1)** [US2] Guard against `oldToken == null` in `_FetchSplashEvent` ([splash_bloc.dart:20-27](../../lib/features/splash/presentation/bloc/splash_bloc.dart#L20-L27)). If the persisted token is somehow null, the refreshed `UserModel` is left tokenless and the next request will 401.

### Code hygiene

- [ ] **T-cleanup-1** `SplashLoading` state ([splash_states.dart:13](../../lib/features/splash/presentation/bloc/splash_states.dart#L13)) is declared but never emitted. Either:
  - Emit it before the `userRepo.getUser()` call (UX win: shows a brief spinner over the logo), or
  - Delete it.

- [ ] **T-cleanup-2** `didChangeDependencies` override at [splash_screen.dart:27-29](../../lib/features/splash/presentation/splash_screen.dart#L27-L29) is empty and just calls `super`. Remove.

- [ ] **T-cleanup-3** `LogoBackGround` class at [splash_screen.dart:126-148](../../lib/features/splash/presentation/splash_screen.dart#L126-L148) appears unused inside the splash file. Verify with a project-wide grep and remove if confirmed dead.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: `FetchSplashEvent` with `userBloc.state.user == null` emits `SplashSuccess(hasUser: false)` without touching `userRepo`.
- [ ] **T-test-2** [P] [US2] Bloc test: with persisted user, `userRepo.getUser()` returning success triggers `UserBloc.loggedIn(merged)` and emits `SplashSuccess(hasUser: true)`.
- [ ] **T-test-3** [P] [US4] Widget test: `SplashFailure` should not strand the user (gated on T-fix-2).
- [ ] **T-test-4** [P] [US-all] Widget test for the approval gate routing on `SplashSuccess`.

---

## Notes

- This is a **migration** — `[x]` items are inferred from existing code + history.
- T-cross-1 (shared DI decision) is documented under [otp/tasks.md](../otp/tasks.md#cross-feature) — same issue, single resolution.
- T-fix-1 + T-fix-4 should be solved together: the "bootstrap" step naturally subsumes "minimum-display-time."
