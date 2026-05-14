---
status: migrated
feature: choose_language
flavor_scope: both
migrated_from: specs/features.md#choose_language--b
migrated_date: 2026-05-14
---

# Feature Specification: Choose Language

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/choose_language/](../../lib/features/choose_language/) and [features.md `## choose_language · B`](../features.md#choose_language--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both — both flavors land here on first install (when `UserBloc.state.user == null`) and via settings → change language.
- **Flavor-conditional behavior**: the **post-selection routing** branches on flavor:
  - **Parents** flavor: if `validList(Config.get.onBoards)`, push `OnBoardScreen`; else push `LoginScreen`.
  - **Professores** flavor: always push `LoginScreen` (skip onboarding).
  - Logic appears twice: in the static `ChooseLanguageScreen.push` helper ([choose_language_screen.dart:29-56](../../lib/features/choose_language/presentation/choose_language_screen.dart#L29-L56)) and in the per-language `onPressed` callback ([line 137-154](../../lib/features/choose_language/presentation/choose_language_screen.dart#L137-L154)). Duplication.
- **Server role implication**: none. The selected language is persisted client-side in `UserBloc.state.language` / `languageWithCode` (HydratedCubit) and rides on the `lang` header to every subsequent request (set by [NetworkInterceptor](../../lib/core/network/network_interceptor.dart) from `UserBloc.state.language`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — First-run language pick (Priority: P1) MVP

A user on a fresh install lands here from splash. They see a vertical list of available languages (PT, EN, AR — from `Config.get.langs`). They tap one. `UserBloc.selectLang(code, codeWithLocale)` fires, and the app routes to onboarding (parents w/ onBoards) or login.

**Why this priority**: First-run pick determines the locale for every subsequent screen. Without it the app would default to device locale and never persist a user override.

**Independent Test**:
1. Clear app data; cold-start either flavor.
2. Splash routes to `ChooseLanguageScreen`.
3. Tap a language; verify `UserBloc.state.language` updates and routing matches the flavor + `onBoards` matrix.

**Acceptance Scenarios**:

1. **Given** `Config.get.langs` is `[pt, en, ar]`, **When** the screen builds, **Then** three `ButtonWithIcon` rows render in order, each with its own image (flag), title, color, and text color from the model.
2. **Given** the user taps the `en` row on the parents flavor with `validList(Config.get.onBoards) == true`, **When** the `onPressed` fires, **Then** `UserBloc.selectLang('en', 'en_US')` (or the model's `codeWithLocale`) is awaited, then `OnBoardScreen` is pushed.
3. **Given** the user taps a row on the professores flavor, **When** the `onPressed` fires, **Then** after `selectLang`, `LoginScreen` is pushed with `pushAndRemoveUntil`.
4. **Given** the user taps a row on the parents flavor with `validList(Config.get.onBoards) == false`, **When** `onPressed` fires, **Then** `LoginScreen` is pushed with `pushAndRemoveUntil` (skip onboarding).

---

### User Story 2 — Change language from settings (Priority: P2)

A signed-in user opens settings → change language. The screen pushes with `fromSettings: true`; an app bar is shown (close button); on tap the user re-enters the home tab and splash re-runs.

**Why this priority**: Quality-of-life. Users who picked the wrong language at install need a way to fix it.

**Acceptance Scenarios**:

1. **Given** the user is in settings, **When** they tap "Change language", **Then** `ChooseLanguageScreen(fromSettings: true)` is pushed ([settings_screen.dart:212](../../lib/features/settings/settings_screen.dart#L212)).
2. **Given** `fromSettings == true`, **When** the user taps a row, **Then**:
   - `UserBloc.selectLang(...)` is awaited
   - `MainBloc.add(ChangePage(id: PageID.home.name))` fires
   - The navigator pushes `SplashScreen` with `pushAndRemoveUntil`
   - Splash will then re-route to `MainScreen` since the user is still logged in.
3. **Given** `fromSettings == true`, **When** the screen builds, **Then** an empty-titled `MyAppBar(color: Colors.transparent)` is shown at the top.

---

### User Story 3 — Single-language config (Priority: P3)

The school's `config/*` document lists only one language. The screen should not appear at all.

**Acceptance Scenarios**:

1. **Given** `Config.get.langs.length == 1`, **When** `ChooseLanguageScreen.push` static helper is called, **Then** it bypasses this screen entirely and routes directly to `OnBoardScreen` (parents w/ onBoards) or `LoginScreen` ([choose_language_screen.dart:29-56](../../lib/features/choose_language/presentation/choose_language_screen.dart#L29-L56)).
2. **Given** `Config.get.langs.length == 1`, **When** the user is somehow inside `ChooseLanguageScreen` already (e.g. via direct push), **Then** the screen still renders the single row and the tap routes correctly.

---

### Edge Cases

- **`Config.get.langs` flips mid-screen**: there is a `ConfigSelector(selector: (config) => config.langs, ...)` at [line 95-97](../../lib/features/choose_language/presentation/choose_language_screen.dart#L95-L97) that rebuilds the column. New languages appear / disappear without exiting the screen. Good.
- **Routing duplication**: the **same** flavor/onBoards branch is reimplemented in the static `push` helper *and* in each row's `onPressed`. If the gating logic changes, both must be updated. Drift risk.
- **No "selected language" highlight**: rows render identically regardless of which language is currently active in `UserBloc.state.language`. A user re-entering from settings has no visual hint of their current choice.
- **`mounted` guard inconsistency**: the row `onPressed` guards `if (mounted)` *after* the `selectLang` await ([line 136](../../lib/features/choose_language/presentation/choose_language_screen.dart#L136)) but **not** in the `fromSettings` branch above it ([line 124-134](../../lib/features/choose_language/presentation/choose_language_screen.dart#L124-L134)). If the user navigates away mid-await, the `fromSettings` path would still try to read `context`.
- **ATT prompt previously fired here** ([line 63-72 comment](../../lib/features/choose_language/presentation/choose_language_screen.dart#L63-L72)): Apple Guideline 5.1.2 rejection vector — ATT must run *after* the user has privacy context. **P0 fixed 2026-05-14**: removed from this screen; moved to `MainScreen.initState` via [core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart). Idempotent on `notDetermined` so returning users get prompted on first reach of main.
- **RTL switch instant?**: features.md task — "Verify RTL switch is instant (no app restart needed)." Today `UserBloc.selectLang` updates state but the `MaterialApp.locale` driver in `MyApp` should auto-rebuild. Unverified.
- **Sticky across logouts**: features.md task — "Make the selected language sticky across logouts." Currently `UserBloc.state.language` is HydratedBloc-persisted with a default of device locale; on logout `_signOutCleanup` *may* reset language (depending on its current behavior). Needs verification.
- **Hardcoded `Color(0xff053E60)`** on the splash-background overlay at [line 89](../../lib/features/choose_language/presentation/choose_language_screen.dart#L89). Same drift as splash and your_account_under_review.
- **Duplicate imports**: [lines 1, 8 / 4, 7 / 14 imports `app_flavors.dart` twice and `config_builder.dart` twice / `common_image.dart` twice](../../lib/features/choose_language/presentation/choose_language_screen.dart#L1-L17). Cleanup item.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a vertical list of `ButtonWithIcon` rows, one per entry in `Config.get.langs`, each showing the language's image (flag), title, color, and text color.
- **FR-002**: Tapping a row MUST `await UserBloc.selectLang(lang.code, lang.codeWithLocale)`, which updates `UserBloc.state.language` + `languageWithCode` and triggers `ConfigCubit.init(lang: ...)` to fetch translations.
- **FR-003**: When `fromSettings == false`, post-selection routing branches on flavor:
  - **professores** → push `LoginScreen` (`pushAndRemoveUntil`)
  - **parents** + `validList(onBoards)` → push `OnBoardScreen`
  - **parents** + no onBoards → push `LoginScreen` (`pushAndRemoveUntil`)
- **FR-004**: When `fromSettings == true`, post-selection MUST:
  1. Dispatch `MainBloc.ChangePage(id: PageID.home.name)`
  2. Push `SplashScreen` with `pushAndRemoveUntil`
- **FR-005**: When `fromSettings == true`, MUST show a transparent `MyAppBar` at the top.
- **FR-006**: System MUST NOT call any ATT / tracking-authorization API from this screen. *Fixed 2026-05-14 — moved to `MainScreen.initState`.*
- **FR-007**: The static `ChooseLanguageScreen.push(context)` helper MUST be the canonical entry point when callers want the "open language picker, fall back to direct routing if only one lang is available" behavior. (Used by splash and settings.)
- **FR-008**: System SHOULD highlight the currently active language. *Not implemented today.*
- **FR-009**: System SHOULD ensure RTL switch is immediate (no restart). *Unverified — [features.md task](../features.md#choose_language--b).*
- **FR-010**: System SHOULD persist the selected language across logouts. *Unverified — [features.md task](../features.md#choose_language--b).*

### Localization Requirements

The screen itself has **no user-visible text strings of its own** — each row's label is `Config.get.langs[index].title` (a remote-driven string). The app bar is empty when `fromSettings == true`.

No new localization keys required.

### Backend Touchpoints

- **REST**: none directly. After `selectLang`, the `lang` header on subsequent requests changes (set by [NetworkInterceptor](../../lib/core/network/network_interceptor.dart)).
- **Firestore**: indirect — `ConfigCubit.init(lang: ...)` fetches the per-language translations / styling block from the school's `config/*` document.
- **FCM**: none.

### Permissions & Approval Gate

- Approval gate: **No** — language picker is pre-login on first install. (`fromSettings == true` path *is* post-login, but doesn't add an approval check — settings is only reachable when the user is authenticated and approved.)
- Device permissions: none required by this screen (ATT moved out).

### Key Entities

- **`LangModel`** ([lib/core/config/](../../lib/core/config/)) — `{code, codeWithLocale, image, title, color, textColor}`.
- **`UserBloc`** (HydratedCubit) — `selectLang(code, codeWithLocale)` mutates `state.language` and `state.languageWithCode`; persisted across restarts.
- **`ConfigCubit`** (HydratedCubit) — `init(lang: ...)` re-fetches translations + styling for the new locale.
- **`MainBloc.ChangePage`** — only used in the `fromSettings == true` branch to ensure the user lands on `home` after the splash re-run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-run user can select any of the configured languages with one tap and reach the next screen in ≤ 3 seconds (dominated by `ConfigCubit.init` translation fetch).
- **SC-002**: A user switching language from settings sees the new locale reflected immediately on `MainScreen` without an app restart.
- **SC-003**: Re-launching after picking a language preserves the choice (HydratedCubit round-trip).
- **SC-004**: No ATT prompt fires from this screen on any iOS version (P0 from [features.md](../features.md#choose_language--b) — closed 2026-05-14).
- **SC-005**: The screen renders identically on parents and professores flavors; the only difference is **what happens after selection**.

## Assumptions

- `ConfigCubit` is hydrated before this screen mounts, so `Config.get.langs` returns the school-configured list.
- `Config.get.langs` is non-empty in any well-configured school. An empty list would render no rows; the user is stranded — defensive empty-state UI is not implemented.
- `UserBloc.selectLang` is idempotent — tapping the currently active language causes a no-op route. (`_signOutCleanup` cleanup of `oldLang` is internal; behavior on re-tap is non-disruptive.)
- The "RTL is instant" assumption depends on `MaterialApp.locale` driver listening to `UserBloc.state.languageWithCode` — assumed but unverified.
