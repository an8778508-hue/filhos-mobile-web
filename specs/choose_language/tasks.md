---
status: migrated
feature: choose_language
migrated_from: specs/features.md#choose_language--b
migrated_date: 2026-05-14
---

# Tasks: Choose Language

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#choose_language--b](../features.md#choose_language--b).

**Tests**: No `test/` directory; tests aspirational.

## Migration summary

Language picker (1 .dart file, ~180 LOC). Reached from splash on first install and from settings → change language. Writes `UserBloc.selectLang`; routes based on flavor + onBoards. The **P0 ATT prompt removal was closed 2026-05-14** — ATT now fires from `MainScreen.initState` via [core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart).

---

## Phase 1: Setup — Complete

- [x] T001 Create [lib/features/choose_language/presentation/](../../lib/features/choose_language/presentation/)
- [x] T002 No new localization keys required (language titles come from remote `Config.get.langs[*].title`)
- [x] T003 PT / EN translations rely on remote config; AR coverage tracked in [features.md cross-feature task](../features.md#cross-feature-tasks)

## Phase 2: Foundational — Complete

- [x] T010 No models / repo / bloc in the feature (intentional). Reads `ConfigCubit`, writes `UserBloc`.
- [x] T011 `UserBloc.selectLang(code, codeWithLocale)` at [user_bloc.dart:104](../../lib/core/user/bloc/user_bloc.dart#L104) — single mutation point.

## Phase 3: User Story 1 — First-run language pick (P1) MVP — Complete (P0 closed)

- [x] T020 [US1] Implement [`ChooseLanguageScreen`](../../lib/features/choose_language/presentation/choose_language_screen.dart) with vertical list of `ButtonWithIcon` rows from `Config.get.langs`
- [x] T021 [US1] Wire row `onPressed` → `UserBloc.selectLang(...)` → flavor/onBoards-aware routing
- [x] T022 [US1] Provide static `ChooseLanguageScreen.push(context)` helper used by splash/onboard
- [x] **T023** **(P0)** [US1] *(from [features.md](../features.md#choose_language--b))* **Remove the `requestTrackingAuthorization` call at `choose_language_screen.dart:63-72`.** *Fixed 2026-05-14: removed from `choose_language`; moved to `MainScreen.initState` via [core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart). Idempotent on `notDetermined` so returning users get prompted on first reach of main.*

## Phase 4: User Story 2 — Change language from settings (P2) — Complete

- [x] T030 [US2] Implement `fromSettings: true` constructor arg + transparent app bar
- [x] T031 [US2] Wire the `fromSettings` post-selection path: `MainBloc.add(ChangePage(home))` + `pushAndRemoveUntil(SplashScreen())`
- [x] T032 [US2] Settings entry point at [settings_screen.dart:212](../../lib/features/settings/settings_screen.dart#L212)

## Phase 5: User Story 3 — Single-language config (P3) — Complete

- [x] T040 [US3] `ChooseLanguageScreen.push` static helper detects `Config.get.langs.length == 1` and bypasses to `OnBoardScreen` / `LoginScreen` directly

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Constitution drift fixes

- [ ] **T-fix-1** **(P2)** [theming] Replace hardcoded `Color(0xff053E60)` at [choose_language_screen.dart:89](../../lib/features/choose_language/presentation/choose_language_screen.dart#L89) with a `context.colors.*` token. Same drift exists in [splash](../splash/tasks.md#bugs--drift) and [your_account_under_review](../your_account_under_review/tasks.md) — consolidate.

- [ ] **T-fix-2** **(P2)** Add `if (!mounted) return;` after `await UserBloc.get.selectLang(...)` in **both** the `fromSettings` branch ([line 124](../../lib/features/choose_language/presentation/choose_language_screen.dart#L124)) and the normal branch. Today only the normal branch has the guard at [line 136](../../lib/features/choose_language/presentation/choose_language_screen.dart#L136).

### Functional gaps (from features.md)

- [ ] **T-fix-3** *(from [features.md](../features.md#choose_language--b))* **Make the selected language sticky across logouts.** Verify `UserBloc._signOutCleanup` does not reset `state.language` / `state.languageWithCode`; if it does, exclude those two fields from the reset. Likely a one-line fix in [user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart).

- [ ] **T-fix-4** *(from [features.md](../features.md#choose_language--b))* **Verify RTL switch is instant** (no app restart). Confirm `MaterialApp.locale` driver in `MyApp` reacts to `UserBloc.state.languageWithCode` and rebuilds the directionality without a cold restart. Add a manual-test step to the migration checklist if confirmed; or wire `MaterialApp.locale` to the user bloc state if not.

- [ ] **T-fix-5** **(P2)** Add a "currently selected" visual on the row whose `code == UserBloc.state.language` — check icon, border, or background tint. Today no affordance.

### Code hygiene

- [ ] **T-cleanup-1** Dedupe imports at [choose_language_screen.dart:1-17](../../lib/features/choose_language/presentation/choose_language_screen.dart#L1-L17). `app_flavors.dart`, `config_builder.dart`, and `common_image.dart` are each imported twice.

- [ ] **T-cleanup-2** Extract the post-selection routing into a `_routeAfterSelection(BuildContext context, {required bool fromSettings})` method shared by both the static `push` helper and the row `onPressed`. Removes a 20-LOC duplication.

- [ ] **T-cleanup-3** Remove the obsolete `// Navigator.pop(context);` and `// Navigator.push(context, …SplashScreen)` comments at [lines 125-128](../../lib/features/choose_language/presentation/choose_language_screen.dart#L125-L128).

- [ ] **T-cleanup-4** Remove `// LogoBackGround(iconColor: Color(0xff053E60));` comment at [line 94](../../lib/features/choose_language/presentation/choose_language_screen.dart#L94) — the splash widget was inlined as a `CommonImage` decoration.

- [ ] **T-cleanup-5** Remove `with TickerProviderStateMixin` at [line 62](../../lib/features/choose_language/presentation/choose_language_screen.dart#L62) — unused (no animation). Same vestigial mixin as in `your_account_under_review`.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test: `ChooseLanguageScreen` renders N rows when `Config.get.langs.length == N`.
- [ ] **T-test-2** [P] [US1] Widget test: tap a row → `UserBloc.selectLang` called → push `LoginScreen` (professores) or `OnBoardScreen` (parents w/ onBoards) or `LoginScreen` (parents w/o onBoards).
- [ ] **T-test-3** [P] [US2] Widget test: `fromSettings: true` shows the transparent app bar; tap a row → `MainBloc.ChangePage(home)` fires; push `SplashScreen` with `pushAndRemoveUntil`.
- [ ] **T-test-4** [P] [US3] Widget test: `ChooseLanguageScreen.push` with `Config.get.langs.length == 1` bypasses this screen entirely.
- [ ] **T-test-5** [P] [X] Snapshot test: confirm **no** ATT/`requestTrackingAuthorization` call originates from this widget tree (regression guard for the 2026-05-14 P0 fix).

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-cleanup-1
- [ ] **TX02** [X] Verify on iOS: ATT prompt does **not** appear from this screen anywhere in the flow (regression guard)
- [ ] **TX03** [X] Verify on Android RTL: tapping `ar` immediately flips directionality on the next screen

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| ~~T023 (ATT in choose_language)~~ | ✅ **Fixed 2026-05-14** | — |
| T-fix-1 | Hardcoded `Color(0xff053E60)` | Low (P2) |
| T-fix-2 | Inconsistent `mounted` guard | Low |

## Gaps Found

- **No "currently selected" affordance** (T-fix-5) — rows render identically.
- **Routing duplication** (T-cleanup-2) between static `push` helper and row callback.
- **Sticky-across-logouts not verified** (T-fix-3).
- **RTL instant-switch not verified** (T-fix-4).
- **Duplicate imports + vestigial mixin** (T-cleanup-1, T-cleanup-5).

## Notes

- This is a **migration** — `[x]` items are inferred from existing code, [features.md](../features.md), and [review.md](../review.md).
- The P0 ATT fix is the largest historical event for this feature; the move to `MainScreen.initState` is documented in [features.md#choose_language--b](../features.md#choose_language--b) and the new helper at [core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart).
- Three colours (`Color(0xff053E60)`) drift across `splash`, `your_account_under_review`, and this feature — fix all three at once when introducing the `context.colors.*` token.
