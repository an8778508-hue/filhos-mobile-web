---
status: migrated
feature: onboard
flavor_scope: both
migrated_from: specs/features.md#onboard--b
migrated_date: 2026-05-14
---

# Feature Specification: Onboard (First-Run Carousel)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/onboard/](../../lib/features/onboard/) and [features.md `## onboard · B`](../features.md#onboard--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both — same carousel for parents and teachers. However, the **gating logic** (whether onboarding is shown at all) **does branch on flavor**: teachers skip onboarding entirely.
- **Flavor-conditional behavior**:
  - In [choose_language_screen.dart:137-154](../../lib/features/choose_language/presentation/choose_language_screen.dart#L137-L154), after a language is picked: if `context.isProfessors`, the user goes straight to `LoginScreen`. Only `parents` flavor lands on `OnBoardScreen` (and only if `validList(Config.get.onBoards)`).
  - The same branch repeats in [`ChooseLanguageScreen.push` static helper:37-54](../../lib/features/choose_language/presentation/choose_language_screen.dart#L37-L54).
- **Server role implication**: none. The `onBoards` list comes from `ConfigCubit` (`config/*` Firestore doc), which is school-scoped, not role-scoped.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Parent walks through the carousel on first install (Priority: P1) MVP

A first-run parent picks a language, the app pushes the onboarding carousel, they swipe through the pages (or tap Next), and on the last page they tap "Start now" to reach the login screen.

**Why this priority**: First impression for new parents. Onboarding sets product expectations.

**Independent Test**:
1. Clear app data; cold-start the parents flavor.
2. Pick a language on `ChooseLanguageScreen`.
3. Verify `OnBoardScreen` pushes if `Config.get.onBoards` is non-empty.
4. Swipe through the pages; verify the `DotsIndicator` updates and the CTA text becomes "Start now" on the last page.
5. Tap "Start now"; verify `LoginScreen` is pushed and the stack is cleared.

**Acceptance Scenarios**:

1. **Given** a parent picks a language and `validList(Config.get.onBoards) == true`, **When** the language selection callback fires, **Then** `OnBoardScreen` is pushed ([choose_language_screen.dart:145-146](../../lib/features/choose_language/presentation/choose_language_screen.dart#L145-L146)).
2. **Given** the user is on page `i` of the carousel, **When** they tap the Next button, **Then** the `PageController.nextPage` animates to page `i+1` with `Curves.fastLinearToSlowEaseIn`.
3. **Given** the user is on the last page, **When** they tap "Start now", **Then** `LoginScreen` is pushed with `pushAndRemoveUntil` (stack cleared).
4. **Given** `Config.get.onBoards.length == 1`, **When** the screen builds, **Then** `end = true` and the CTA reads "Start now" immediately (single page is effectively the last page).
5. **Given** `validList(Config.get.onBoards) == false` (empty list arrives via `ConfigListener`), **When** the config flips, **Then** the screen routes directly to `LoginScreen` with `pushAndRemoveUntil`.

---

### User Story 2 — Skip the carousel (Priority: P2)

A returning or impatient parent taps the "Skip" link in the top-end SafeArea to leave the carousel before reaching the last page.

**Why this priority**: Quality-of-life. Onboarding can feel slow.

**Acceptance Scenarios**:

1. **Given** the user is on any page **except** the last, **When** they tap "Skip" ([onboard_screen.dart:263-296](../../lib/features/onboard/presentation/onboard_screen.dart#L263-L296)), **Then** `LoginScreen` is pushed with `pushAndRemoveUntil`.
2. **Given** the user is on the **last** page, **When** they look at the top-end SafeArea, **Then** the Skip CTA is hidden (`if (!end)` guard at [line 262](../../lib/features/onboard/presentation/onboard_screen.dart#L262)).

---

### User Story 3 — Switch language from the carousel (Priority: P3)

A parent realizes they picked the wrong language and wants to switch from the onboarding screen.

**Acceptance Scenarios**:

1. **Given** `Config.get.langs.length > 1`, **When** the user taps the language chip in the top-start SafeArea, **Then** `ChooseLanguageScreen` is pushed (not `pushAndRemoveUntil` — the carousel remains in the stack).
2. **Given** `Config.get.langs.length == 1`, **When** the user taps the language chip, **Then** nothing happens ([onboard_screen.dart:225-227](../../lib/features/onboard/presentation/onboard_screen.dart#L225-L227)).

---

### Edge Cases

- **First-install gate is not enforced**: features.md task — "Confirm onboarding appears only on first install (gate by Hive flag)." Today there is **no Hive flag**. The screen is reached only via `ChooseLanguageScreen`, which itself only runs on first install (splash routes to it when `UserBloc.state.user == null`). So onboarding effectively runs once **per uninstall**, but a logout-then-login flow does not re-trigger it (the user already has a hydrated `UserBloc.state.user` from a different session) — *unless* the user fully clears data. There's a commented-out `SharedPreferences.setBool('seen', true)` at [onboard_screen.dart:172-173](../../lib/features/onboard/presentation/onboard_screen.dart#L172-L173) and [271-272](../../lib/features/onboard/presentation/onboard_screen.dart#L271-L272) — the original implementation that was disabled.
- **`Config.get.onBoards` flips to empty while the user is mid-carousel**: a `ConfigListener` at [line 37-52](../../lib/features/onboard/presentation/onboard_screen.dart#L37-L52) navigates to `LoginScreen` if the list becomes empty. Good defensive behavior.
- **`safeElementAt(index)`** is used for `image`, `title`, `subTitle` reads — guards out-of-range without crashing.
- **`subTitle.tr(context)` on a remote string**: subtitle text is run through `LocalizationKeys.tr()` ([onboard_screen.dart:125](../../lib/features/onboard/presentation/onboard_screen.dart#L125)) but **`title` is not** ([line 107](../../lib/features/onboard/presentation/onboard_screen.dart#L107)). Asymmetry — confirm whether title is intentionally raw (per-school custom) and subtitle is intentionally translation-key (one of the bundled keys). features.md task: "Localize illustration captions for AR/EN/PT."
- **Skip CTA missing on the last page**: features.md task — "Add a 'skip' CTA on every page." Today the Skip is hidden on the last page; only the primary CTA ("Start now") is shown. Whether this is a bug or intentional depends on whether "Start now" itself should be a skip — usually they're treated as equivalent, so it's debatable.
- **Hardcoded `Colors.black12` / `Colors.black38`** on image dimmer / lang chip — minor theming drift.
- **Two `Spacer()` widgets** stacked vertically between title and subtitle ([onboard_screen.dart:101, 136](../../lib/features/onboard/presentation/onboard_screen.dart#L101)) — the design intent is unclear; both pages render identically regardless.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a horizontal `PageView` of onboarding pages from `Config.get.onBoards` (a `List<OnBoardModel>` provided by `ConfigCubit`).
- **FR-002**: Each page MUST show an image (top half), a bold title, and a subtitle. Image / title / subtitle come from the model. Subtitle text is run through `.tr(context)` so it can be a localization key.
- **FR-003**: System MUST render a `DotsIndicator` reflecting the current `index` and the total `onBoards.length`. Hide it when `onBoards.isEmpty`.
- **FR-004**: System MUST present a primary CTA whose text is "Next" while on intermediate pages and "Start now" on the last page.
- **FR-005**: Tapping the primary CTA on the last page (or when only one page exists) MUST push `LoginScreen` with `pushAndRemoveUntil` (stack cleared).
- **FR-006**: System MUST present a "Skip" CTA in the top-end SafeArea on every page **except** the last (today's behavior; [features.md task](../features.md#onboard--b) says skip should appear on every page).
- **FR-007**: System MUST present a language-switcher chip in the top-start SafeArea showing the currently selected language's flag + title. Tapping pushes `ChooseLanguageScreen` only when `Config.get.langs.length > 1`.
- **FR-008**: System MUST listen to `ConfigCubit.onBoards`; if it flips to an empty list mid-flow, route directly to `LoginScreen` with `pushAndRemoveUntil`.
- **FR-009**: System SHOULD gate onboarding on a first-install flag (Hive) so it doesn't re-appear after a re-login on the same install. *Not implemented today — [features.md task](../features.md#onboard--b).*
- **FR-010**: System SHOULD localize illustration captions in PT / EN / AR. *Partial — subtitle is run through `.tr()`, title is not. [features.md task](../features.md#onboard--b).*

### Localization Requirements

| Key | Use site |
|---|---|
| `start_now` | last-page primary CTA |
| `next` | intermediate-page primary CTA |
| `skip` | top-end skip CTA |

No new keys required by this migration. Per-page **subtitle** text comes from the remote `onBoards` model and is `.tr(context)`-ed at the call site, so subtitle keys must exist in `assets/langs/*.json` — coordinate with the school admin who manages `config/*`. **Title** is rendered raw and should likely also be `.tr()`-ed per [features.md](../features.md#onboard--b).

### Backend Touchpoints

- **REST**: none.
- **Firestore**: indirect — `Config.get.onBoards` and `Config.get.langs` are hydrated from `config/*` document via `ConfigCubit`.
- **FCM**: none.

### Permissions & Approval Gate

- Approval gate: **No** — onboarding is pre-login.
- Device permissions: none required.

### Key Entities

- **`OnBoardModel`** (in [lib/core/config/models/](../../lib/core/config/)) — `{image, title, subTitle, ...}`.
- **`LangModel`** (same area) — `{code, codeWithLocale, image, title, color, textColor}`. Used by the top-start language chip.
- **`Config.get.onBoards`** / **`Config.get.langs`** — read-only accessors against the hydrated `ConfigCubit`.
- **`PageController`** — local UI state for the carousel.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-run parent reaches `LoginScreen` after the carousel in ≤ 3 taps (or 1 tap if `onBoards.length == 1`).
- **SC-002**: A user who fully clears app data on a parents-flavor install sees the carousel exactly once before reaching login.
- **SC-003**: Skip CTA always reaches `LoginScreen` from any intermediate page.
- **SC-004**: Switching language mid-carousel does not leave the user with a mixed-language UI on the next page.
- **SC-005**: When `Config.get.onBoards` is empty, the carousel is bypassed entirely and the user lands on `LoginScreen` directly.

## Assumptions

- `ConfigCubit` is hydrated before this screen mounts. `Config.get` reads through the singleton accessor.
- The teacher flavor never reaches this screen (gated upstream in `ChooseLanguageScreen`). This is intentional — teachers are typically existing users invited by a school admin.
- The commented-out `SharedPreferences.setBool('seen', true)` calls represent the original first-install gate that was disabled. Restoring this via Hive (per [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart)) is the [features.md (P0?)](../features.md#onboard--b) follow-up.
- "Skip" is semantically the same as "Start now" — both go to `LoginScreen` with stack cleared. The visibility difference on the last page is a UX choice.
