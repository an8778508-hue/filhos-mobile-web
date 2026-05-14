---
status: migrated
feature: onboard
migrated_from: specs/features.md#onboard--b
migrated_date: 2026-05-14
---

# Tasks: Onboard

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#onboard--b](../features.md#onboard--b).

**Tests**: No `test/` directory; tests aspirational.

## Migration summary

First-run carousel for the **parents** flavor only (teachers skip via `ChooseLanguageScreen`). 1 .dart file, ~310 LOC. No bloc / data layer / models. Three open follow-ups: Hive first-install gate, title localization, Skip-on-every-page.

---

## Phase 1: Setup — Complete

- [x] T001 Create [lib/features/onboard/presentation/](../../lib/features/onboard/presentation/)
- [x] T002 Reserve `start_now`, `next`, `skip` localization keys ([localization_keys.dart:57-59](../../lib/core/localization/localization_keys.dart#L57))
- [x] T003 PT / EN translations present
- [ ] T004 AR translation — verify per [features.md cross-feature task](../features.md#cross-feature-tasks)

## Phase 2: Foundational — Complete

- [x] T010 No models / repo / bloc in the feature itself (intentional — reads `ConfigCubit`)

## Phase 3: User Story 1 — Walk through the carousel (P1) MVP — Complete

- [x] T020 [US1] Implement [`OnBoardScreen`](../../lib/features/onboard/presentation/onboard_screen.dart): `PageView` over `Config.get.onBoards`, `DotsIndicator`, Next / Start now CTA
- [x] T021 [US1] On `Start now` (last page), push `LoginScreen` with `pushAndRemoveUntil`
- [x] T022 [US1] `ConfigListener` watching `onBoards`: route to `LoginScreen` if list becomes empty
- [x] T023 [US1] `safeElementAt(index)` guards against out-of-range reads on the model
- [x] T024 [US1] Push the carousel from `ChooseLanguageScreen` only when `parents` flavor + `validList(Config.get.onBoards)`

## Phase 4: User Story 2 — Skip (P2) — Complete (with gap)

- [x] T030 [US2] Skip CTA in the top-end SafeArea (intermediate pages only)
- [ ] **T-fix-4** **(P2)** [US2] *(from [features.md](../features.md#onboard--b))* **Add a "Skip" CTA on every page** including the last. Drop the `if (!end)` guard at [onboard_screen.dart:262](../../lib/features/onboard/presentation/onboard_screen.dart#L262), or — if product confirms "Start now" already covers this — close the features.md task with a comment.

## Phase 5: User Story 3 — Switch language mid-carousel (P3) — Complete

- [x] T040 [US3] Language chip in the top-start SafeArea; tap pushes `ChooseLanguageScreen` only when `Config.get.langs.length > 1`

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Constitution drift fixes

- [ ] **T-fix-1** **(P2)** [theming] Replace `Colors.black12` ([onboard_screen.dart:92](../../lib/features/onboard/presentation/onboard_screen.dart#L92)) and `Colors.black38` ([line 220](../../lib/features/onboard/presentation/onboard_screen.dart#L220)) with `context.colors.*` tokens.

### Functional gaps (from features.md)

- [ ] **T-fix-2** *(from [features.md](../features.md#onboard--b))* **Confirm onboarding appears only on first install (gate by Hive flag).** Restore the original behavior that was commented out at [onboard_screen.dart:172-173](../../lib/features/onboard/presentation/onboard_screen.dart#L172-L173) / [271-272](../../lib/features/onboard/presentation/onboard_screen.dart#L271-L272):
  - On reaching `OnBoardScreen` (or on tap of Start now / Skip), write `LocalKeys.seenOnboarding = true` via [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart).
  - In [ChooseLanguageScreen](../../lib/features/choose_language/presentation/choose_language_screen.dart), read the flag and skip `OnBoardScreen` if already seen.
  - Add `seenOnboarding` to [local_db_repo.dart](../../lib/core/local_db/local_db_repo.dart) box keys.

- [ ] **T-fix-3** *(from [features.md](../features.md#onboard--b))* **Localize illustration captions for AR / EN / PT.** Decide whether `OnBoardModel.title` is intended to be a translation key (run through `.tr()` like subtitle) or a per-school raw string. Current code is asymmetric: subtitle is `.tr()`-ed at [line 125](../../lib/features/onboard/presentation/onboard_screen.dart#L125), title is rendered raw at [line 107](../../lib/features/onboard/presentation/onboard_screen.dart#L107). Document the convention in [CLAUDE.md](../../CLAUDE.md) once decided.

- [ ] **T-fix-4** *(from [features.md](../features.md#onboard--b))* See Phase 4 above — Skip CTA on every page.

- [ ] **T-fix-5** **(P2)** [V. flavor] Add an explicit `if (context.isProfessors) Navigator.pushReplacement(...LoginScreen)` guard at the top of `build` so that even if upstream forgets to skip, this screen does not show to teachers. Defensive.

### Code hygiene

- [ ] **T-cleanup-1** Extract `OnBoardPage` widget for the per-page contents (image / title / subtitle); reduces the screen from ~310 LOC to ~150 LOC and makes each page testable.

- [ ] **T-cleanup-2** Remove the duplicate `ConfigSelector(selector: (config) => config.onBoards, ...)` nesting at lines 53, 62, 82, 104, 122 — they all listen to the same selector. One outer `ConfigBuilder` is enough.

- [ ] **T-cleanup-3** Remove commented-out `SharedPreferences` calls at [lines 172-173](../../lib/features/onboard/presentation/onboard_screen.dart#L172-L173) and [271-272](../../lib/features/onboard/presentation/onboard_screen.dart#L271-L272) when T-fix-2 lands (replaced by `LocalDatabaseRepo`).

- [ ] **T-cleanup-4** The two `Spacer()` widgets between title and subtitle (lines [101](../../lib/features/onboard/presentation/onboard_screen.dart#L101) and [136](../../lib/features/onboard/presentation/onboard_screen.dart#L136)) — verify intent; likely one is redundant.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test: `OnBoardScreen` renders N pages when `Config.get.onBoards.length == N`.
- [ ] **T-test-2** [P] [US1] Widget test: tap Next on intermediate page advances `PageController`; tap "Start now" on last page pushes `LoginScreen` with stack cleared.
- [ ] **T-test-3** [P] [US2] Widget test: Skip CTA is visible on intermediate pages, hidden on last page (gated on T-fix-4 outcome).
- [ ] **T-test-4** [P] [X] Widget test (post-T-fix-2): once `seenOnboarding` flag is set, splash → language picker → login skips this screen.

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-* / T-cleanup-*
- [ ] **TX02** [X] Build parents flavor and walk through the carousel end-to-end after any change
- [ ] **TX03** [X] Verify teachers flavor still skips this screen entirely (no regression)

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| T-fix-1 | `Colors.black12` / `Colors.black38` instead of theme tokens | Low (P2) |
| T-fix-2 | No first-install gate (commented out) | Medium |
| T-fix-3 | Title rendered raw, subtitle `.tr()`-ed (asymmetric localization) | Low-medium |
| T-fix-5 | No defensive flavor guard on this screen's entry | Low |

## Gaps Found

- **No first-install Hive flag** (T-fix-2) — the original implementation was commented out; today the gate is implicit (only reachable via cold-start from splash via choose-language).
- **Asymmetric localization** of title vs subtitle (T-fix-3).
- **Skip CTA missing on the last page** (T-fix-4) — features.md flags as a task; debatable whether "Start now" covers it.
- **Hardcoded overlay colors** (T-fix-1).
- **Vestigial scaffolding** — `SingleTickerProviderStateMixin` declared but unused; multiple `ConfigSelector` re-listens on the same selector.

## Notes

- This is a **migration** of an existing feature. `[x]` items are inferred from existing code and [features.md](../features.md).
- T-fix-2 is the highest-impact follow-up — restoring the first-install gate is a clear UX win and is technically straightforward given `LocalDatabaseRepo` already exists.
