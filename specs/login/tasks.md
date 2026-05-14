---
status: migrated
feature: login
migrated_from: specs/features.md#login--b
migrated_date: 2026-05-14
---

# Tasks: Login

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#login--b](../features.md#login--b).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational with a note. Adding them is encouraged but not yet a blocking quality gate per [constitution Quality Gates](../../.specify/memory/constitution.md#quality-gates).

**Organization**: This is a **migration** of an existing feature. Most implementation tasks are already done (`[x]`). Tasks reflect *real history* (from [features.md](../features.md) and [review.md](../review.md)) plus *gaps surfaced by this migration*. Story labels map to the user stories in [spec.md](spec.md).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: US1 = phone OTP, US2 = social login, US3 = email login, X = cross-cutting

---

## Phase 1: Setup (Shared Infrastructure) — ✅ Complete

- [x] T001 Create feature directory [lib/features/login/](../../lib/features/login/) mirroring sibling layout
- [x] T002 Add localization keys to [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) for login title, CTA, social row, email/password fields, T&C
- [x] T003 Add Portuguese translations to [assets/langs/pt.json](../../assets/langs/pt.json)
- [x] T004 Add English translations to [assets/langs/en.json](../../assets/langs/en.json)
- [x] T005 Add Arabic translations to [assets/langs/ar.json](../../assets/langs/ar.json) — **⚠️ partial coverage; ~40% of repo-wide keys missing per [features.md cross-feature tasks](../features.md#cross-feature-tasks)**
- [x] T006 Create [lib/features/login/login_di.dart](../../lib/features/login/login_di.dart) at feature root (✓ correct per [constitution principle II](../../.specify/memory/constitution.md))
- [x] T007 Register `LoginInjection` in [lib/init_dependencies.dart](../../lib/init_dependencies.dart)

---

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `LoginRequest`, `LoginEmailParamaters` in [lib/features/login/models/](../../lib/features/login/models/) (⚠️ filename typos: `login_requset.dart`, `login_email_paramaters.dart` — see T-cleanup-1)
- [x] T011 Define `LoginRepository` abstract contract in [data_sources/login_repository.dart](../../lib/features/login/data_sources/login_repository.dart) with endpoint constants
- [x] T012 Implement `LoginImpl` using `NetworkClient.handleRequest` → `Either<Failure, UserModel>` in [data_sources/login_impl.dart](../../lib/features/login/data_sources/login_impl.dart)
- [x] T013 Create `LoginBloc` (Cubit) with states `LoginInitial/Loading/Ready/Failure/SocialSuccess/WithEmailSuccess` in [presentation/bloc/](../../lib/features/login/presentation/bloc/)

---

## Phase 3: User Story 1 — Phone + SMS OTP (P1) 🎯 MVP — ✅ Complete (with gaps)

- [x] T020 [US1] Implement `LoginScreen` form with phone field + country picker + remember-me + T&C inline links ([login_screen.dart](../../lib/features/login/presentation/login_screen.dart))
- [x] T021 [US1] Wire `LoginBloc.requestOTP` to Firebase `verifyPhoneNumber` via `LoginImpl.requestOTP`
- [x] T022 [US1] Persist `last_otp_request` / `last_otp_phone` via `LocalDatabaseRepo`; enforce 60s cooldown per phone
- [x] T023 [US1] **(P0)** Source `role` from the flavor binary (`isProfessorsFlavor`), not from `mainKey.currentContext`. *Fixed 2026-05-14 for the phone path. **[features.md#login--b](../features.md#login--b)**.*
- [x] T024 [US1] **(P0)** On logout, call `FirebaseMessaging.deleteToken()`. *Fixed 2026-05-14 in `UserBloc._signOutCleanup`.*
- [x] T025 [US1] **(P0)** Handle 401 in `NetworkInterceptor._handleOnError` — forces `UserBloc.loggedOut()` once per session, re-entrancy-guarded. *Fixed 2026-05-14.*
- [x] T026 [US1] Debug-mode bypass: skip Firebase verification, accept code `123456`, fall back to `device_token: 'debug-device-token'` on FCM failure
- [ ] T027 [US1] **(P0 remaining)** On logout, explicitly `HydratedBloc.storage.clear()` for the `UserState` key. *Partial: `UserBloc.fromJson` is null-guarded and `emit(state.copyWith(user: null))` writes a clean state; explicit clear still optional.*

---

## Phase 4: User Story 2 — Social Login (P2) — ✅ Complete (with drift, see T-fix-2)

- [x] T030 [US2] Implement `signInWithGoogle()` with per-flavor iOS `serverClientId` ([login_impl.dart:213-271](../../lib/features/login/data_sources/login_impl.dart#L213-L271))
- [x] T031 [US2] Implement `signInWithFacebook()` ([login_impl.dart:273-316](../../lib/features/login/data_sources/login_impl.dart#L273-L316))
- [x] T032 [US2] Implement `signInWithApple()` — guarded for iOS only ([login_impl.dart:318-357](../../lib/features/login/data_sources/login_impl.dart#L318-L357))
- [x] T033 [US2] Wire each provider through `LoginBloc.loginWith{Google,Facebook,Apple}` → `LoginSocialSuccess(userModel)` → approval-gate-aware navigation
- [x] T034 [US2] Gate provider visibility on `ConfigCubit.socialLogin.{googleEnabled,facebookEnabled,appleEnabled}` ([social_login_widget.dart](../../lib/features/login/presentation/widget/social_login_widget.dart))
- [x] T035 [US2] Hide Apple button on Android via `Platform.isIOS && state.appleEnabled`

---

## Phase 5: User Story 3 — Email + Password (P3) — ✅ Complete

- [x] T040 [US3] Implement email-form toggle via `ValueNotifier<bool> isEmailLogin`
- [x] T041 [US3] Email regex + password ≥ 6 char client-side validation in [login_screen.dart:540-570](../../lib/features/login/presentation/login_screen.dart#L540-L570)
- [x] T042 [US3] Implement `loginWithEmail()` returning `Either<Failure, UserModel>` and emitting `LoginWithEmailSuccess`
- [x] T043 [US3] Detect server `{error: true}` envelope and surface `ServerException`/`ServerFailure` with server message

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Constitution drift fixes

- [x] **T-fix-1** **(P0)** [US2, US3, register] Replaced **4 remaining** `(mainKey.currentContext?.isProfessors ?? false)` call sites in [login_impl.dart](../../lib/features/login/data_sources/login_impl.dart) with `isProfessorsFlavor`. *Fixed 2026-05-14*:
  - `sendSocialTokenToApi` (line 193) ✓
  - `signInWithGoogle` iOS client-ID branch (line 218) ✓
  - `register` (line 373) ✓
  - `loginWithEmail` (line 401) ✓

  Grep verification: zero `mainKey.currentContext` references remain in `login_impl.dart`; the only repo-wide matches now are doc-comments in `flavors/app_flavors.dart` + `core/user/current_role.dart` and a commented-out line in `chat/data_sources/static_data.dart`. The [features.md cross-feature task](../features.md#cross-feature-tasks) now reads "18 sites swept" with an explicit note about the second sweep.

- [ ] **T-fix-2** **(P2)** [US2] Hardcoded iOS Google OAuth client IDs in [login_impl.dart:218-228](../../lib/features/login/data_sources/login_impl.dart#L218-L228) — move to `--dart-define` or per-flavor platform config so a new flavor doesn't require a code change.

- [ ] **T-fix-3** **(P0)** [US1] **(from [features.md#login--b](../features.md#login--b))** Add explicit invalid-phone-format messaging using `brasil_fields`.

- [ ] **T-fix-4** **(P1)** [US1] **(from [features.md#login--b](../features.md#login--b))** Persist `last_otp_phone` to prefill on retry.

- [ ] **T-fix-5** **(P1)** [US1, US2, US3] **(from [features.md#login--b](../features.md#login--b))** Audit error mapping for 401/403 from `/auth/login`; currently several paths fall back to a generic `ServerFailure()` without a server message.

- [ ] **T-fix-6** **(P0 backend)** [US1] **(from [features.md#login--b](../features.md#login--b))** Server-side `revoke_device_token` endpoint — call from `UserBloc._signOutCleanup` before `NotificationService.clearToken()`. Coordinate with backend; not implementable from the codebase alone.

### Code hygiene

- [ ] **T-cleanup-1** Rename typo'd files (touches imports across the feature):
  - `models/login_requset.dart` → `models/login_request.dart`
  - `models/login_email_paramaters.dart` → `models/login_email_parameters.dart`

- [ ] **T-cleanup-2** **Delete dead code** [lib/features/login/models/login_response.dart](../../lib/features/login/models/login_response.dart) — not referenced anywhere in the feature; `LoginImpl` returns `UserModel` directly.

- [ ] **T-cleanup-3** Remove debug-mode `debugPrint('Google Auth accessToken: ...')` ([login_impl.dart:246](../../lib/features/login/data_sources/login_impl.dart#L246)) and `debugPrint('Facebook Auth AccessToken: ...')` ([line 293](../../lib/features/login/data_sources/login_impl.dart#L293)) — tokens in logs are risky even in debug. Either drop the line or redact the value.

- [ ] **T-cleanup-4** Replace `print('OTPBloc.requestOTP ${l.message}');` ([login_bloc.dart:56](../../lib/features/login/presentation/bloc/login_bloc.dart#L56)) and the typo'd `debugPrint('OTPBloc.requestOtttttttttttttttttttttTP $phone')` ([line 48](../../lib/features/login/presentation/bloc/login_bloc.dart#L48)) with a structured logger. Part of the wider [features.md cross-feature task](../features.md#cross-feature-tasks) "Route 146 print/debugPrint calls through a single logger."

- [ ] **T-cleanup-5** `_isDebugBypass` instance state lives in the `LazySingleton` `LoginImpl` and is only ever set in `kDebugMode`. Document this in a one-line comment so future readers don't think the flag persists across user sessions in release.

### Tests (aspirational — no `test/` directory exists today)

- [ ] **T-test-1** [P] [US1] Cubit test for `LoginBloc.requestOTP` covering: fresh phone, cooldown active, cooldown expired, repository failure mapped to `LoginFailure`.
- [ ] **T-test-2** [P] [US2] Repo test for `LoginImpl.signInWithGoogle()` with mocked `GoogleSignIn` + `NetworkClient`.
- [ ] **T-test-3** [P] [US3] Widget test for the email-mode validators (empty, invalid format, short password).
- [ ] **T-test-4** [X] Widget test for the approval gate: `LoginSocialSuccess` with `isApproval = false` must route to `your_account_under_review`, not `MainScreen`.

---

## Phase 7: Polish & Cross-Cutting — partial (mostly tracked at the repo level)

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-1 through T-fix-5 and T-cleanup-* — no new warnings expected
- [ ] **TX02** [X] Build parents flavor: `flutter build apk --flavor parents -t lib/main.dart`
- [ ] **TX03** [X] Build professores flavor: `flutter build apk --flavor professores -t lib/main_professores.dart`
- [ ] **TX04** [X] Cold-start the app, log in as a teacher, log in as a parent; verify the role header is correct via the backend log on both — confirms T-fix-1
- [ ] **TX05** [X] Verify the social row collapses to nothing when all three providers are disabled in remote `config/*`

---

## Dependencies & Execution Order

- **Phases 1–5 are complete.** No order required beyond what's recorded.
- **Phase 6 (gaps and cleanups)** is the actionable work surfaced by this migration. Internal order:
  1. **T-fix-1** first — closes the most-cited constitution drift and unblocks honest reporting of the cross-feature sweep status.
  2. **T-cleanup-1** and **T-cleanup-2** next — small file-rename + dead-code delete; lowest risk.
  3. **T-fix-3**, **T-fix-4**, **T-fix-5** — UX/error-mapping improvements; independent, parallelizable.
  4. **T-cleanup-3**, **T-cleanup-4**, **T-cleanup-5** — hygiene; can ride along.
  5. **T-fix-2** can wait for the broader "centralize REST paths / `--dart-define` config" effort in [features.md cross-feature tasks](../features.md#cross-feature-tasks).
  6. **T-fix-6** is backend-coordinated; not blocking from this side.
  7. **Tests** are aspirational until [features.md cross-feature task "Add the first tests"](../features.md#cross-feature-tasks) establishes a test baseline.

## Notes

- This `tasks.md` reflects **migration**, not greenfield. Most `[x]` items are inferred from existing code, [features.md](../features.md), and [review.md](../review.md) — not from re-running each individually.
- "Fixed 2026-05-14" attributions come from [features.md](../features.md) and [review.md change log](../review.md) — the source of truth for fix history.
- If you spot drift between this file and reality, update [spec.md](spec.md) / [plan.md](plan.md) here and the matching entry in [features.md](../features.md). Don't let the two diverge.
