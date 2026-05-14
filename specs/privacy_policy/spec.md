---
status: migrated
feature: privacy_policy
flavor_scope: both
migrated_from: specs/features.md#privacy_policy--b
migrated_date: 2026-05-14
---

# Feature Specification: Privacy Policy

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/privacy_policy/](../../lib/features/privacy_policy/) and [features.md `## privacy_policy · B`](../features.md#privacy_policy--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both. Same WebView, same URL source (`Config.get.appInfo.privacyUrl`). No flavor branching in the screen.
- **Flavor-conditional behavior**: none.
- **Server role implication**: none. The URL comes from `ConfigCubit` (`config/*` Firestore doc), which is school-scoped — different schools may have different privacy URLs, but role does not affect the URL.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — View the privacy policy from login or register (Priority: P1) MVP

A user signing up or logging in taps the inline "privacy policy" link beneath the CTA. A WebView opens to the school's privacy URL. The user reads it and pops back to the prior screen.

**Why this priority**: LGPD compliance — every signup flow must present privacy terms before account creation.

**Independent Test**:
1. From [LoginScreen](../../lib/features/login/presentation/login_screen.dart) (or [RegisterScreen](../../lib/features/register/presentation/register_screen.dart)), tap the "privacy policy" inline link.
2. Verify `PrivacyPolicy` screen pushes, a loading spinner shows while the page loads, then the WebView renders the remote document.
3. Tap the system back button; the user returns to the prior screen.

**Acceptance Scenarios**:

1. **Given** the user reaches [LoginScreen](../../lib/features/login/presentation/login_screen.dart), **When** they tap the inline "privacy policy" link ([login_screen.dart:421](../../lib/features/login/presentation/login_screen.dart#L421)), **Then** `PrivacyPolicy` is pushed.
2. **Given** the same screen on the register flow ([register_screen.dart:311](../../lib/features/register/presentation/register_screen.dart#L311)), **When** the user taps "privacy policy", **Then** the same `PrivacyPolicy` is pushed.
3. **Given** the WebView is loading, **When** `onPageStarted` fires, **Then** the `Loading()` overlay is visible.
4. **Given** the WebView finishes loading, **When** `onPageFinished` fires, **Then** the overlay disappears.
5. **Given** the WebView is rendered, **When** the user taps the system back button, **Then** the previous screen is restored.

---

### User Story 2 — Payment success interception (Priority: P3)

When the WebView navigates to a URL containing `payment/status/success`, the screen pops with `Navigator.pop(context, true)` so a payment flow that reused this screen can detect success.

**Why this priority**: Specific to a payment integration that piggybacks on this WebView. Not used by privacy-policy reads.

**Acceptance Scenarios**:

1. **Given** the WebView is on a page that redirects to `…/payment/status/success`, **When** the navigation request is intercepted, **Then** the screen pops with `true` and the navigation is prevented ([privacy_policy_screen.dart:25-28](../../lib/features/privacy_policy/privacy_policy_screen.dart#L25-L28)).

---

### Edge Cases

- **No URL configured** (`Config.get.appInfo.privacyUrl == null` or empty): `Uri.parse(...)` is called on `null` — would throw. *Gap-1.* Defensive check needed before `loadRequest`.
- **JavaScript-enabled remote URL with no nav-host allowlist** (`JavaScriptMode.unrestricted` at [line 22](../../lib/features/privacy_policy/privacy_policy_screen.dart#L22)): any link in the page loads in-app — **phishing vector** if the URL is ever tampered with. P1 task in [features.md](../features.md#privacy_policy--b).
- **White flash on first paint**: the WebView's background defaults to white before content paints. P1 task — set `WebView.setBackgroundColor` to the screen's scaffold color.
- **Slow / failing remote URL**: no error UI — the spinner just spins indefinitely. No `onWebResourceError` handler today.
- **Environment-aware URL**: features.md task — "Confirm policy URL is environment-aware (no prod URL in staging)." Today the URL is whatever lands in `ConfigCubit.appInfo.privacyUrl`; if staging/prod share the same Firestore project, the URL may not flip.
- **Payment-success interception running on a privacy URL**: harmless today (no privacy URL contains `payment/status/success`) but is a latent coupling — the screen serves two purposes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a `WebViewWidget` pointing at `Config.get.appInfo.privacyUrl`.
- **FR-002**: System MUST show a loading overlay (`Loading()`) while `onPageStarted` is active and hide it on `onPageFinished`.
- **FR-003**: System MUST surface a localized `privacy_policy` title in the app bar via [MyAppBar](../../lib/core/components/widgets/app_bar.dart).
- **FR-004**: System MUST intercept any navigation to a URL containing `payment/status/success` and pop the screen with `true`.
- **FR-005**: System SHOULD restrict in-WebView navigation to an allowlist of trusted hosts to prevent phishing. *Not implemented — P1 [features.md task](../features.md#privacy_policy--b).*
- **FR-006**: System SHOULD set `WebView.setBackgroundColor` to avoid the white flash on first paint. *Not implemented — P1 [features.md task](../features.md#privacy_policy--b).*
- **FR-007**: System SHOULD handle `onWebResourceError` with a user-visible message + retry. *Not implemented.*

### Localization Requirements

| Key | Use site |
|---|---|
| `privacy_policy` | app bar title ([privacy_policy_screen.dart:59](../../lib/features/privacy_policy/privacy_policy_screen.dart#L59)) |

No new keys required by this migration. The WebView content is fetched from the remote URL and is not localized client-side (the server returns the right language by setting `Accept-Language` if configured server-side — out of scope here).

### Backend Touchpoints

- **REST**: none directly from this feature. The URL itself is whatever the remote `config/*` Firestore document specifies for `appInfo.privacyUrl`.
- **Firestore**: indirect — `Config.get.appInfo.privacyUrl` reads from the hydrated `ConfigCubit` state.
- **FCM**: none.

### Permissions & Approval Gate

- Approval gate: **No** — privacy policy must be reachable pre-login (from login + register). Cannot gate on `isApproval`.
- Device permissions: none required.

### Key Entities

- **`PrivacyPolicy`** (the screen widget) — `StatefulWidget` owning a `WebViewController` and a single `bool isLoading` flag.
- **`Config.get.appInfo.privacyUrl`** — sourced from [ConfigCubit](../../lib/core/config/) hydrated from Firestore `config/*`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The privacy policy is reachable from both login and register without authentication.
- **SC-002**: First paint of the WebView completes within 5 s on a typical 4G connection.
- **SC-003**: An external link tapped inside the policy WebView is restricted to an allowlist of trusted hosts (currently violated — phishing vector).
- **SC-004**: Payment-success redirect is intercepted exactly when the URL contains `payment/status/success`, not otherwise.

## Assumptions

- `ConfigCubit` is hydrated before this screen mounts. If `Config.get.appInfo.privacyUrl` is empty, the screen crashes on `Uri.parse` — caller responsibility today.
- The privacy URL is environment-aware via the Firestore `config/*` document. Staging and production rely on the school's `config/*` doc holding the right URL.
- `JavaScriptMode.unrestricted` is required by the published privacy doc's analytics / accessibility scripts (assumed — not verified).
- The reuse of this screen for payment-success interception is intentional historical behavior. A future cleanup should split payment WebView from privacy-policy WebView.
