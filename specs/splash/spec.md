---
status: migrated
feature: splash
flavor_scope: both
migrated_from: specs/features.md#splash--b
migrated_date: 2026-05-14
---

# Feature Specification: Splash

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/splash/](../../lib/features/splash/) and [features.md#splash--b](../features.md#splash--b).

## Flavor Scope

- **Target flavor(s)**: both. Same boot logic for parents and teachers; the only visual difference is the logo (driven by remote config `ConfigCubit.logo`) plus a small spacing tweak when `context.isProfessors` is true ([splash_screen.dart:105](../../lib/features/splash/presentation/splash_screen.dart#L105)).
- **Flavor-conditional behavior**: trivial (logo spacing).
- **Server role implication**: none directly. If a hydrated `UserBloc.user` is present, the splash re-fetches the user from the server (the role header is set by the standard `NetworkInterceptor`).

## User Scenarios & Testing

### User Story 1 — Cold start, no persisted user → onboarding (Priority: P1) 🎯 MVP

The user opens the app for the first time. The splash shows the logo, briefly fetches state, and routes to the language picker.

**Why this priority**: First-run experience for every new user.

**Independent Test**:
1. Clear app data (or run with `clearCache = true` in [init_dependencies.dart](../../lib/init_dependencies.dart)).
2. Launch the parents flavor.
3. Verify the splash shows for ~2 seconds then pushes [ChooseLanguageScreen](../../lib/features/choose_language/presentation/choose_language_screen.dart).

**Acceptance Scenarios**:

1. **Given** `UserBloc.state.user == null` (cold install), **When** the splash boots, **Then** `SplashBloc` emits `SplashSuccess(hasUser: false)` and after a 2-second timer pushes `ChooseLanguageScreen`.

---

### User Story 2 — Returning approved user → main shell (Priority: P1)

A user who previously logged in and was approved relaunches the app.

**Why this priority**: This is the everyday path for active users.

**Acceptance Scenarios**:

1. **Given** `UserBloc.state.user != null` and `isApproval == true`, **When** the splash boots, **Then** the app calls `UserRepo.getUser()`, overlays the fresh server payload onto the persisted `accessToken`, calls `UserBloc.loggedIn(refreshed)`, emits `SplashSuccess(hasUser: true)`, waits 2 s, and pushes `MainScreen`.

---

### User Story 3 — Returning pending user → approval gate (Priority: P1)

A user who logged in but whose account is still pending re-opens the app.

**Acceptance Scenarios**:

1. **Given** `UserBloc.state.user != null` and `isApproval == false`, **When** the splash boots, **Then** after the refresh + 2-second timer, the app pushes `YourAccountUnderReviewScreen`.

---

### User Story 4 — Server error during refresh (Priority: P2)

Persisted user exists, but `UserRepo.getUser()` fails (network down, 5xx).

**Acceptance Scenarios**:

1. **Given** `UserRepo.getUser()` returns `Left(Failure)`, **When** the splash receives the result, **Then** `SplashBloc` emits `SplashFailure(failure)`, the listener shows a `SnackBar` with `failure.message`, and after the 2-second timer routes the user based on **persisted** `UserBloc.state.user` (main vs approval-gate vs language picker). *Fixed 2026-05-14 — see [tasks.md T-fix-2](tasks.md).*

---

### Edge Cases

- **`HydratedBloc` hydration not complete when splash fires `FetchSplashEvent`**: features.md (P0) flags this — `getUserData` may run before `UserBloc.fromJson` finishes, so the first network call may go out without `Authorization`. Today `UserBloc.fromJson` is null-guarded ([features.md cross-feature task ✅](../features.md#cross-feature-tasks)), but an explicit `Bootstrap` step is still pending.
- **`initDependecies()` failure**: silently surfaced as a missing `di<SplashBloc>()` — would throw during `BlocProvider.create`, no error UI. ([features.md task](../features.md#splash--b))
- **Fast cold start**: 2-second `Timer` runs *after* `SplashSuccess` is emitted, so on fast devices the logo flashes briefly. Already a known UX item: features.md task "Add an explicit minimum-display-time so the splash doesn't flicker on fast cold starts."
- **Background `accessToken` is `null` after refresh**: `remoteUserResult` is overlaid via `copyWith(accessToken: oldToken)` — if `oldToken` is null, the refreshed user has no token, breaking the next request.
- **Hardcoded color**: `Color(0xffF2F2F2)` at [splash_screen.dart:83](../../lib/features/splash/presentation/splash_screen.dart#L83) violates [constitution principle X](../../.specify/memory/constitution.md). features.md (P2).

## Requirements

### Functional Requirements

- **FR-001**: System MUST render the brand logo from `ConfigCubit.logo`, falling back to [Assets.icons.defaultLogo](../../lib/shared/assets/assets.gen.dart) when remote config has no logo.
- **FR-002**: System MUST render a "Powered by" footer ([PoweredByWidget](../../lib/core/components/text/powered_by.dart)).
- **FR-003**: System MUST dispatch `FetchSplashEvent` immediately on screen construction.
- **FR-004**: System MUST check `UserBloc.state.user != null` to decide whether to refresh from the server.
- **FR-005**: System MUST, when a persisted user exists, call `UserRepo.getUser()` and merge the response with the persisted `accessToken` before re-hydrating `UserBloc`.
- **FR-006**: System MUST delay navigation by 2 seconds after `SplashSuccess` so the logo is visible.
- **FR-007**: System MUST route to `MainScreen` when `hasUser && isApproval == true`, `YourAccountUnderReviewScreen` when `hasUser && !isApproval`, and `ChooseLanguageScreen` when `!hasUser`.
- **FR-008**: System SHOULD show a non-blocking error state (snackbar today) on `SplashFailure` — but **also** route somewhere; currently the user is stuck. See [tasks.md T-fix-2](tasks.md).

### Localization Requirements

None directly. The splash has no user-visible text strings of its own; the `SnackBar` content on `SplashFailure` is `failure.message` which already routes through `LocalizationKeys` upstream.

### Backend Touchpoints

- **REST**: `GET` user via [UserRepo](../../lib/core/user/data_source/user_repo.dart). The base URL + auth header come from the standard `NetworkInterceptor`.
- **No Firestore, no FCM** in this feature directly. FCM subscriptions are owned by [background_services/](../../lib/features/background_services/) which the main shell instantiates *after* splash.

### Permissions & Approval Gate

- Splash is the *gate enforcer* — anyone with `isApproval == false` is routed to `your_account_under_review` here.
- Splash itself requires no device permissions.

### Key Entities

- **`SplashEvent` (sealed)**: only `FetchSplashEvent`.
- **`SplashState` (sealed)**: `SplashInitial`, `SplashLoading` (declared but never emitted), `SplashSuccess(hasUser: bool)`, `SplashFailure(Failure)`.
- **`UserBloc`** (from `lib/core/user/`) — read at splash time; **rehydrated** via `loggedIn(remoteUser.copyWith(accessToken: oldToken))`.

## Success Criteria

- **SC-001**: Cold start on a fast device shows the logo for at least ~2 seconds before any navigation.
- **SC-002**: A returning user with a valid token lands on `MainScreen` (or `YourAccountUnderReviewScreen`) within 5 seconds of launch on a typical network.
- **SC-003**: A new user always reaches `ChooseLanguageScreen` on first launch.
- **SC-004**: If the server refresh fails, the user is **not** silently stuck (current bug — fix tracked).

## Assumptions

- `initDependencies()` has completed before `MyApp` is built (which builds `SplashScreen`).
- `HydratedBloc.storage` has been built before `UserBloc` is created — see [init_dependencies.dart:22](../../lib/init_dependencies.dart#L22).
- `UserBloc` is registered as a singleton in [core/user/user_di.dart](../../lib/core/user/user_di.dart).
- The 2-second branding delay is acceptable to product. Brand guidelines should formalize this duration.
