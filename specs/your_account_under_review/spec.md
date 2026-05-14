---
status: migrated
feature: your_account_under_review
flavor_scope: both
migrated_from: specs/features.md#your_account_under_review--b
migrated_date: 2026-05-14
---

# Feature Specification: Your Account Under Review

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/your_account_under_review/](../../lib/features/your_account_under_review/) and the existing [features.md `## your_account_under_review · B`](../features.md#your_account_under_review--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores). The approval gate is enforced for both flavors. Teachers are far more likely to hit it (school-admin approval), but a parent enrolled by an admin may also land here on first login.
- **Flavor-conditional behavior**: none. Same single screen, same copy key (`your_account_is_under_review`).
- **Server role implication**: none directly. The screen reads `UserBloc.state.user?.isApproval`; the role behind that user was set upstream during login.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Pending user lands on the gate after login (Priority: P1) MVP

A teacher (or parent) finishes the login flow. The backend returns `UserModel.isApproval == false`. The post-login navigator pushes the gate screen instead of the main shell.

**Why this priority**: This is the only path that exists today. Without it, an unapproved user would reach the main shell with no permission to act and crash on the first authenticated call.

**Independent Test**:
1. Log in as a teacher whose server record has `isApproval == false`.
2. Verify the OTP success listener routes to `YourAccountUnderReviewScreen` (not `MainScreen`).
3. Verify the screen renders the clock icon, the `your_account_is_under_review` headline, and the "login with another account" CTA in the top-end corner.

**Acceptance Scenarios**:

1. **Given** `UserBloc.state.user?.isApproval == false`, **When** the OTP success / social success / register success listener fires, **Then** the user is pushed to `YourAccountUnderReviewScreen` with the navigator stack cleared.
2. **Given** the gate screen is on top of the stack, **When** the user taps the "Login with another account" CTA, **Then** `LoginScreen(hasBackButton: true)` is pushed (no stack clear — they can return).
3. **Given** the gate screen mounts, **When** `initState` runs, **Then** `BackgroundServicesBloc.add(CallServices())` is dispatched immediately.

---

### User Story 2 — Returning pending user from cold start (Priority: P1)

A user who was already pending re-opens the app. `UserBloc` rehydrates with `isApproval == false`; the splash routes here.

**Why this priority**: Same enforcement, different entry point. Splash is the gate enforcer for cold starts.

**Independent Test**:
1. With persisted `UserBloc.state.user` whose `isApproval == false`, cold-start the app.
2. Splash refreshes the user via `UserRepo.getUser()`; after the 2-second timer, navigates to `YourAccountUnderReviewScreen`.

**Acceptance Scenarios**:

1. **Given** persisted user with `isApproval == false`, **When** splash completes, **Then** `YourAccountUnderReviewScreen` is pushed (see [splash spec FR-007](../splash/spec.md#functional-requirements)).
2. **Given** the gate screen is mounted, **When** `BackgroundServicesBloc.CallServices` resolves with a refreshed `UserModel.isApproval == true`, **Then** the user remains on the gate screen until the next foreground refresh / login — *Gap-2: no automatic flip-to-main when approval clears in-app*.

---

### User Story 3 — Push tap from terminated state (Priority: P1)

The backend sends a push (e.g., approval-pending reminder) while the app is killed. The user taps it.

**Why this priority**: Push deep-links are a third entry vector into authenticated screens. P0 fix from [features.md](../features.md#your_account_under_review--b) ensures `notification_helper.dart` returns early on unapproved users so push-driven deep-links don't bypass the gate.

**Acceptance Scenarios**:

1. **Given** the user is unapproved, **When** a push is tapped while the app is terminated, **Then** [notification_helper.dart:42](../../lib/core/notifications_service/notification_helper.dart#L42) returns early (`if (user.isApproval == false) return;`), the notification routes nowhere, and the splash flow re-establishes the gate. *Fixed 2026-05-14.*

---

### Edge Cases

- **`UserBloc.state.user == null` at mount**: theoretical; the screen requires `BackgroundServicesBloc` in the tree, which `MainShell` builds. If a navigation bug pushes the gate before a user exists, `CallServices` returns early ([background_services_bloc.dart:33](../../lib/features/background_services/bloc/background_services_bloc.dart#L33)) and the screen renders harmlessly. No explicit guard.
- **No "rejected" copy**: the screen shows the same "under review" headline regardless of whether the server returned `pending` or `rejected`. [features.md task](../features.md#your_account_under_review--b): "Show a short reason string if the server returns one (rejected vs. pending)."
- **No "contact your school" CTA**: a user pending for a long time has no escalation path from this screen. [features.md task](../features.md#your_account_under_review--b): "Add a 'contact your school' CTA after N minutes pending."
- **Approval flips while the screen is mounted**: `BackgroundServicesBloc.CallServices` does poll (`await userBloc.getUserData()`) but the gate screen does **not** observe `UserBloc` state changes and re-route to main. The user must manually relaunch or log out/in. *Gap-2.*
- **Stack on "login with another account"**: pushing `LoginScreen` rather than clearing the stack means an authenticated `LoginScreen` is now layered above the gate. If the user backs out, they land back on the gate of the previous account — semantically correct but worth a UX review.
- **Hardcoded `Color(0xff053E60)`** at [your_account_under_review_screen.dart:36](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L36) — violates [constitution principle X](../../.specify/memory/constitution.md). Same `LogoBackGround` widget is reused in splash; same pattern, same drift.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a centered clock icon + the `your_account_is_under_review` headline on a primary-color background.
- **FR-002**: System MUST surface a top-end "Login with another account" CTA that pushes `LoginScreen(hasBackButton: true)`.
- **FR-003**: System MUST dispatch `BackgroundServicesBloc.CallServices()` from `initState` so notification subscriptions, FCM token registration, and the next `UserBloc.getUserData()` refresh run on screen entry.
- **FR-004**: System MUST be reachable from all three login paths (phone-OTP, social, email) and from register, splash, and push-tap deep-links — every navigator that consults `isApproval` must route here on `false`.
- **FR-005**: System MUST NOT route an unapproved user to any authenticated screen. The check is performed:
  - In splash ([splash_bloc.dart](../../lib/features/splash/presentation/bloc/splash_bloc.dart)) before pushing main.
  - In the OTP success listener ([otp_screen.dart](../../lib/features/otp/presentation/otp_screen.dart)).
  - In `LoginSocialSuccess` / `LoginWithEmailSuccess` listeners ([login_screen.dart](../../lib/features/login/presentation/login_screen.dart)).
  - In `SuccessRegisterState` listener ([register_screen.dart](../../lib/features/register/presentation/register_screen.dart)).
  - In [notification_helper.dart:42](../../lib/core/notifications_service/notification_helper.dart#L42) before routing on a push tap.
- **FR-006**: System SHOULD surface a "contact your school" CTA when the user has been pending for an extended period — *not implemented, [features.md task](../features.md#your_account_under_review--b).*
- **FR-007**: System SHOULD differentiate the copy when the server returns `rejected` instead of `pending` — *not implemented.*

### Localization Requirements

| Key | Use site |
|---|---|
| `your_account_is_under_review` | headline ([your_account_under_review_screen.dart:52](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L52)) |
| `login_with_another_account` | top-end CTA ([your_account_under_review_screen.dart:80](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L80)) |

No new keys required by this migration. Translations live in [assets/langs/pt.json](../../assets/langs/pt.json) / [en.json](../../assets/langs/en.json) / [ar.json](../../assets/langs/ar.json).

### Backend Touchpoints

- **REST**: indirect via `BackgroundServicesBloc.CallServices` → `UserBloc.getUserData()` → `UserRepo.getUser()`. Updates `UserBloc.state.user` (including `isApproval`) on each foreground entry.
- **FCM**: indirect via `notificationService.configureNotifications(onTokenRefresh: …)`; ensures the device token stays current while the user is pending.
- **Firestore**: none.

### Permissions & Approval Gate

- **This feature *is* the approval gate.** Cross-cutting enforcement is documented in FR-005 above.
- Device permissions: none required by the screen itself. The dispatched `CallServices` may surface notification permissions through `NotificationService.configureNotifications`.

### Key Entities

- **`YourAccountUnderReviewScreen`** ([your_account_under_review_screen.dart](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart)) — stateful widget; only state is the `TickerProviderStateMixin` (unused in the current build — leftover scaffolding for an animation that was never wired).
- **`BackgroundServicesBloc`** (consumed, not owned) — see [background_services/](../../lib/features/background_services/).
- **`UserBloc.state.user.isApproval`** — the single boolean that decides the gate.
- **`LogoBackGround`** — reused from [splash_screen.dart:126-148](../../lib/features/splash/presentation/splash_screen.dart#L126-L148). Imported directly from splash, a cross-feature import the [features.md cross-feature task](../features.md#cross-feature-tasks) flags.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An unapproved user never reaches `MainScreen` via any of the 5 entry vectors listed in FR-005.
- **SC-002**: When an unapproved user taps a push notification, [notification_helper.dart:42](../../lib/core/notifications_service/notification_helper.dart#L42) returns early; the notification does not deep-link into an authenticated screen.
- **SC-003**: From mount, `BackgroundServicesBloc.CallServices` fires within one frame.
- **SC-004**: The "Login with another account" CTA always reaches `LoginScreen` regardless of the prior auth method.

## Assumptions

- A non-null `UserBloc.state.user` is available at the time the gate screen mounts (every entry path establishes it first).
- `BackgroundServicesBloc` is provided above this screen by the app root. It is registered as a singleton in [core/dependency_injection/](../../lib/core/dependency_injection/di.dart).
- The server's `isApproval` flag is the source of truth; the app trusts the most recent value persisted in `UserBloc`.
- Approval state is a binary today — `pending` vs `rejected` distinction is a future enhancement, not a blocker.
