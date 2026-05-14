---
status: migrated
feature: your_account_under_review
migrated_from: specs/features.md#your_account_under_review--b
migrated_date: 2026-05-14
---

# Tasks: Your Account Under Review

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#your_account_under_review--b](../features.md#your_account_under_review--b).

**Tests**: No `test/` directory; tests are aspirational. [features.md (P0)](../features.md#your_account_under_review--b) lists a gate test as the blocking item.

## Migration summary

Single-screen feature (1 .dart file, ~105 LOC). No bloc, no data layer. Observes `UserBloc.state.user.isApproval` through the upstream routers; dispatches `BackgroundServicesBloc.CallServices` on entry. Approval-gate enforcement is cross-cutting and is covered in the [splash](../splash/), [login](../login/), [otp](../otp/), and [register](../register/) specs as well.

---

## Phase 1: Setup — Complete

- [x] T001 Create [lib/features/your_account_under_review/presentation/](../../lib/features/your_account_under_review/presentation/)
- [x] T002 Add localization keys `your_account_is_under_review` and `login_with_another_account` to [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) (already present at line 56 and 63 respectively)
- [x] T003 Add PT / EN translations to [assets/langs/pt.json](../../assets/langs/pt.json) and [en.json](../../assets/langs/en.json)
- [x] T004 Add AR translation (⚠️ part of the [features.md cross-feature task](../features.md#cross-feature-tasks) on AR coverage — verify both keys are in `ar.json`).

## Phase 2: Foundational — Complete

- [x] T010 No models, no repos, no bloc — by design. The gate observes a flag owned by `UserBloc`.

## Phase 3: User Story 1 — Pending user lands on the gate after login (P1) — Complete

- [x] T020 [US1] Implement [`YourAccountUnderReviewScreen`](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart) with clock icon, headline, and top-end "login with another account" CTA
- [x] T021 [US1] Dispatch `BackgroundServicesBloc.CallServices()` from `initState`
- [x] T022 [US1] Wire the gate as the navigation destination in `LoginSocialSuccess` / `LoginWithEmailSuccess` / `SuccessRegisterState` listeners across login & register
- [x] T023 [US1] Wire the gate in the OTP success listener ([otp_screen.dart](../../lib/features/otp/presentation/otp_screen.dart))

## Phase 4: User Story 2 — Returning pending user from cold start (P1) — Complete

- [x] T030 [US2] Splash routes to the gate when `hasUser && !isApproval` ([splash_screen.dart](../../lib/features/splash/presentation/splash_screen.dart) — see [splash spec FR-007](../splash/spec.md#functional-requirements))

## Phase 5: User Story 3 — Push tap from terminated state (P1) — Complete (P0 closed 2026-05-14)

- [x] **T040** [US3] **(P0)** Enforce approval check inside `notification_helper.dart`. *Fixed 2026-05-14*: `if (user.isApproval == false) return;` at [notification_helper.dart:42](../../lib/core/notifications_service/notification_helper.dart#L42). Per [features.md](../features.md#your_account_under_review--b).

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Constitution drift fixes

- [ ] **T-fix-1** **(P2)** [theming] Replace hardcoded `Color(0xff053E60)` at [your_account_under_review_screen.dart:36](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L36) with a `context.colors.*` token (`primaryDark` or a new `gateLogoTint`). Same pattern as the splash drift in [splash/tasks.md T-fix-3](../splash/tasks.md#bugs--drift).

### Functional gaps (from features.md)

- [ ] **T-fix-2** **(P0)** *(from [features.md](../features.md#your_account_under_review--b))* Add an integration / widget test that proves the gate is enforced from **all three** entry vectors: splash on cold start, OTP success, and a push tap from terminated state. No `test/` directory exists yet; this task is blocked by the [features.md cross-feature task "Add the first tests"](../features.md#cross-feature-tasks).

- [ ] **T-fix-3** **(P2)** *(from [features.md](../features.md#your_account_under_review--b))* Add a "contact your school" CTA that appears after the user has been pending for ≥ N minutes (product to pick `N`). Likely launches a phone-call intent or `mailto:` to `school.contactEmail`.

- [ ] **T-fix-4** **(P2)** *(from [features.md](../features.md#your_account_under_review--b))* Differentiate copy when the server signals `rejected` vs `pending`. Requires a server field (today only `isApproval` is exposed) — coordinate with backend.

- [ ] **T-fix-5** **(P2)** [US2] Auto-route to main when `BackgroundServicesBloc.CallServices` returns a refreshed user with `isApproval == true`. Today the user must relaunch or log out/in. Listen to `UserBloc` state in the screen and `Navigator.pushAndRemoveUntil(MainScreen())` on `isApproval` flipping to `true`.

### Code hygiene

- [ ] **T-cleanup-1** Remove `with TickerProviderStateMixin` at [your_account_under_review_screen.dart:20](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L20) — unused (no animation).

- [ ] **T-cleanup-2** Pull `LogoBackGround` out of [splash_screen.dart](../../lib/features/splash/presentation/splash_screen.dart) and into [lib/core/components/](../../lib/core/components/) so this feature stops cross-importing splash. Part of the wider [features.md cross-feature task](../features.md#cross-feature-tasks).

### Tests (aspirational — no `test/` directory exists today)

- [ ] **T-test-1** [P] [US1] Widget test: with `UserBloc.state.user.isApproval == false`, the post-OTP listener pushes `YourAccountUnderReviewScreen` (not `MainScreen`).
- [ ] **T-test-2** [P] [US2] Widget test: same gate fires from splash on cold start with a hydrated pending user.
- [ ] **T-test-3** [P] [US3] Integration test: tapping a push from terminated state with a pending user does not deep-link past `notification_helper.dart:42`.
- [ ] **T-test-4** [P] [US1] Widget test: tapping "login with another account" pushes `LoginScreen(hasBackButton: true)`.

---

## Phase 7: Polish & Cross-Cutting — partial

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-1 / T-cleanup-1
- [ ] **TX02** [X] Verify the gate render on both flavors (parents + professores) since the screen has no flavor branching

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| T-fix-1 | Hardcoded `Color(0xff053E60)` instead of theme token | Low (P2) |

## Gaps Found

- **No re-route on approval flip** (T-fix-5): screen does not observe `UserBloc` and pivot to main when `isApproval` becomes `true` mid-session.
- **No "rejected" copy** (T-fix-4): single headline regardless of server-side state.
- **No escalation CTA** (T-fix-3): user has no in-app path to contact the school.
- **No tests** (T-fix-2): the cross-cutting gate enforcement has no automated coverage despite spanning 5 navigators.
- **Cross-feature widget import** (T-cleanup-2): `LogoBackGround` belongs in `lib/core/components/`.
- **Unused mixin** (T-cleanup-1): `TickerProviderStateMixin` with no animations.

## Notes

- This is a **migration** of an existing feature; most `[x]` items are inferred from the existing code, [features.md](../features.md), and [review.md](../review.md).
- The approval-gate is enforced in five separate navigators (FR-005). Future work should consolidate this into a single `RouteGuard` to reduce drift surface.
