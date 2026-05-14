---
status: migrated
feature: terms_and_condtions
flavor_scope: both
migrated_from: specs/features.md#terms_and_condtions--b
migrated_date: 2026-05-14
---

# Feature Specification: Terms and Conditions

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/terms_and_condtions/](../../lib/features/terms_and_condtions/) and the [features.md `## terms_and_condtions · B`](../features.md#terms_and_condtions--b) entry.

> ℹ️ **Folder name typo** is intentional in this migration — the directory is `terms_and_condtions/` (missing `i`), and the spec lives at `specs/terms_and_condtions/` to match. Rename is tracked at [features.md cross-feature P2 task](../features.md#cross-feature-tasks) and at [tasks.md T-fix-1](tasks.md).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**: none in this screen. Content is server-driven and identical for both roles via `pages/terms-conditions`.
- **Server role implication**: none — the endpoint is public-ish (no role gating in the body) and routed identically for both flavors.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the Terms & Conditions (Priority: P1) 🎯 MVP

A user opens **Settings → Terms and Conditions** (or taps the inline T&C link on the **Login** / **Register** screens) and reads the school's terms of service rendered from HTML.

**Why this priority**: LGPD (Brazilian data-protection law) requires the school to display its terms before consent. Without this screen, sign-up consent is questionable.

**Independent Test**:
1. Tap **Terms and Conditions** from Settings.
2. Confirm: `TermsBloc` dispatches `FetchTerms` on mount; the loading overlay briefly appears; the HTML body renders inside a scrollable view; the app-bar title is localized ("Termos e Condições" / "Terms and Conditions" / "الشروط والأحكام").

**Acceptance Scenarios**:

1. **Given** a user opens the screen, **When** the `BlocProvider` builds, **Then** `di<TermsBloc>()..add(const FetchTerms())` runs immediately ([terms_and_conditions_screen.dart:20](../../lib/features/terms_and_condtions/terms_and_conditions_screen.dart#L20)).
2. **Given** the fetch is in-flight, **When** `state.aboutState.loading == true`, **Then** `LoadingOverlay` covers the (still-empty) body ([terms_and_conditions_screen.dart:37](../../lib/features/terms_and_condtions/terms_and_conditions_screen.dart#L37)).
3. **Given** the server returns `{data: {content: "<html>..."}}`, **When** the bloc emits `s.success(r)`, **Then** `TextHtml(state.aboutState.data ?? '')` renders the markup ([terms_and_conditions_screen.dart:31-33](../../lib/features/terms_and_condtions/terms_and_conditions_screen.dart#L31-L33)).
4. **Given** the server returns `{data: {content: null}}`, **When** `validateString(...)` resolves to `""`, **Then** `TextHtml` renders an empty body without crashing ([terms_repo.dart:33](../../lib/features/terms_and_condtions/repo/terms_repo.dart#L33)).
5. **Given** the request fails, **When** the bloc emits `s.failed(message)`, **Then** the loading overlay clears but no error UI is shown — the body simply stays empty. **Gap**: no error surface.

---

### User Story 2 - Read the Privacy Policy via the same bloc (Priority: P1, latent)

The `TermsBloc` also handles a `FetchPrivacy` event that hits `pages/privacy-policy` and writes into the same `TermsState`. The bloc is **prepared** to serve both screens, but `terms_and_conditions_screen.dart` only ever fires `FetchTerms` — and the dedicated `privacy_policy/` feature has its **own** screen using a WebView ([privacy_policy_screen.dart](../../lib/features/privacy_policy/privacy_policy_screen.dart)) rather than this bloc.

**Why noted here**: this is a structural ambiguity. The `FetchPrivacy` branch in `TermsBloc` is dead code today — see [tasks.md T-fix-2](tasks.md). Either delete it or migrate `privacy_policy/` onto this bloc for consistency.

**Acceptance Scenarios**:

1. **Given** the codebase, **When** an engineer greps for `FetchPrivacy`, **Then** the only references are in this feature's bloc / events. No screen dispatches it.

---

### Edge Cases

- **Server returns no `content` field**: `validateString(null)` returns `""`; `TextHtml` renders empty. No crash, no error.
- **Server returns malformed HTML**: `TextHtml` (which wraps `flutter_html`) renders best-effort; unknown tags are stripped silently.
- **Offline**: the bloc dispatches `FetchTerms` on every screen open with no cache. Repeat opens require a network round-trip. Gap — see [tasks.md T-fix-3](tasks.md).
- **No "I agree" CTA**: this screen is read-only. Consent capture (where required) happens inline on Login / Register via separate copy + checkbox per [login/spec.md FR-012](../login/spec.md).
- **Folder typo** (`terms_and_condtions/`) — discussed at top.
- **`features.md` mis-characterizes this as a "WebView wrapper"** — the actual implementation is a REST-driven `TextHtml`. The features.md note also says "Server-driven URL via `Config.get.appInfo.termsUrl`" — that URL field exists, but **this screen does not use it**. The WebView path is `privacy_policy/`, not this feature.
- **No retry on failure**: the bloc emits `failed(...)` but nothing in the screen consumes `state.aboutState.error`. The user sees a blank page.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the terms HTML from `GET pages/terms-conditions` via [NetworkClient.handleRequest](../../lib/core/network/network_client.dart) returning `Either<Failure, String>`.
- **FR-002**: System MUST extract the body from `json?['data']?['content']` and run `validateString(...)` so a null content does not crash rendering ([terms_repo.dart:33](../../lib/features/terms_and_condtions/repo/terms_repo.dart#L33)).
- **FR-003**: System MUST emit a three-state machine on `TermsState`: fetching, success(data), failed(error).
- **FR-004**: System MUST render the response with the shared [TextHtml](../../lib/core/components/text/text_html.dart) widget inside a `SingleChildScrollView`.
- **FR-005**: System MUST show `LoadingOverlay` while loading.
- **FR-006**: System MUST use the localized app-bar title `LocalizationKeys.terms_and_conditions.tr(context)`.
- **FR-007**: System SHOULD surface a retry / error UI when the fetch fails — *currently not implemented*.
- **FR-008**: System MUST be reachable from at minimum: Settings → Terms list item ([settings_screen.dart:222](../../lib/features/settings/settings_screen.dart#L222)), Login screen inline link, Register screen inline link.

### Localization Requirements

| Key | Use site |
|---|---|
| `terms_and_conditions` | App-bar title |

Body content is served from the backend; the server is expected to localize per `Accept-Language` (or per user settings). Today the client doesn't pass language hints to this endpoint — verify whether the server reads `lang` from the standard headers added by [NetworkInterceptor](../../lib/core/network/network_interceptor.dart).

### Backend Touchpoints

- **REST**:
  - `GET pages/terms-conditions` → `{data: {content: "<html string>"}}`.
  - `GET pages/privacy-policy` → same shape (used by `FetchPrivacy` — dead in this screen).
- **No Firestore, no FCM, no Storage usage.**

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **No** — the screen is reachable pre-login (via the Login screen's inline link), so it must work without `Authorization`. The standard headers are added by the interceptor regardless of auth state.
- Device permissions: none.

### Key Entities

- **`TermsBloc`** ([bloc](../../lib/features/terms_and_condtions/bloc/terms_bloc.dart)) — `Bloc<TermsEvents, TermsStates>` with two event handlers: `FetchTerms`, `FetchPrivacy`.
- **`TermsEvents`** ([events](../../lib/features/terms_and_condtions/bloc/terms_events.dart)) — sealed abstract; `FetchTerms`, `FetchPrivacy`.
- **`TermsStates`** ([states](../../lib/features/terms_and_condtions/bloc/terms_states.dart)) — wraps a single `TermsState` (`{data, loading, error}`).
- **`TermsRepo`** ([repo](../../lib/features/terms_and_condtions/repo/terms_repo.dart)) — `getTerms()`, `getPrivacy()` returning `Either<Failure, String>` from `NetworkClient.handleRequest`.
- **`TermsAndConditions`** ([screen](../../lib/features/terms_and_condtions/terms_and_conditions_screen.dart)) — `StatelessWidget` providing the bloc, rendering `TextHtml`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Terms screen content renders within 1 second of opening on a typical 4G connection.
- **SC-002**: Opening the screen on a fresh install (no auth token) succeeds — `Authorization` is not required by the server contract.
- **SC-003**: A user can scroll the full document without text being clipped, on a 360-dp-wide device.
- **SC-004**: The screen renders the document in the user's chosen language (subject to server-side localization).

## Assumptions

- The server returns valid `flutter_html`-compatible HTML (no JS, no external CSS that affects layout, no remote font imports). If the server ever embeds `<script>` tags, `TextHtml` will silently drop them — safer than the [privacy_policy WebView path](../../lib/features/privacy_policy/privacy_policy_screen.dart) which executes JS.
- The terms document is small enough (< 50 kB) that no pagination / streaming is required.
- The server localizes content based on the `lang` header injected by `NetworkInterceptor` — verify; if it doesn't, all users see the same language.
- The `config.appInfo.termsUrl` field is unused by this screen. If the team wants per-school terms, the WebView path (`privacy_policy/`) is the model to copy, not this REST path.
- This feature does **not** capture explicit consent — the Login / Register inline checkboxes do.
