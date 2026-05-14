---
status: migrated
feature: onboard
migrated_from: lib/features/onboard/
migrated_date: 2026-05-14
---

# Implementation Plan: Onboard

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

First-run carousel of branded onboarding pages. 1 .dart file, ~310 LOC. No bloc, no data layer, no models in the feature. Reads `Config.get.onBoards` and `Config.get.langs` from `ConfigCubit`; renders a `PageView` with a primary CTA, a `DotsIndicator`, a top-start language chip, and a top-end Skip CTA. Pushes `LoginScreen` on completion. **Only the `parents` flavor reaches this screen.**

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `dots_indicator` 4.x — carousel dot indicator
- `flutter_screenutil` 5.9 — `.h`/`.w`/`.sp`/`.csh`/`.csw` sizing
- `ConfigCubit` (read-only) — `onBoards` + `langs`
- `UserBloc` (read-only) — `state.language` for the chip
- `flutter/material.dart` — `PageView`, `PageController`

**Storage**: none directly today. **Should** persist a first-install Hive flag via [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart) — [features.md task](../features.md#onboard--b), not yet implemented.

**Testing**: none today.

**Target Platform**: iOS + Android, **parents flavor only** (teachers skip via `ChooseLanguageScreen`).

**Project Type**: Flutter mobile feature; `presentation/` only.

**Performance Goals**: Carousel swipe at 60 fps. Image load is the dominant cost — comes from `CommonImage` which uses `cached_network_image` under the hood.

**Constraints**:

- Title strings are rendered raw; subtitle strings are `.tr(context)`-ed. Asymmetry is a documented gap.
- Two `Spacer()` widgets between title and subtitle ([onboard_screen.dart:101, 136](../../lib/features/onboard/presentation/onboard_screen.dart#L101)) — vestigial.
- Skip CTA hidden on the last page — debatable UX choice.

**Scale/Scope**: 1 .dart file, ~310 LOC. The file is long mostly because every text/button block is configured inline; a small `OnBoardPage` extracted widget would shrink it considerably (refactor opportunity, see [tasks.md T-cleanup-1](tasks.md)).

## Constitution Check

- [x] **I. Feature-First Layout** — `lib/features/onboard/presentation/onboard_screen.dart`. No `data_sources/` (correct — no data layer). ✓
- [x] **II. Dependency Direction** — no DI registration; the screen owns no bloc.
- [x] **III. Networking Contract** — N/A.
- [x] **IV. Persistence Discipline** — N/A today. Future Hive flag should go through `LocalDatabaseRepo`.
- [ ] **V. Flavor Branching** — ⚠️ flavor branching happens **upstream** in `ChooseLanguageScreen.push` / language selection callback, not inside this screen. Acceptable but worth noting that an explicit `context.isProfessors` guard at this screen's entry would be safer if the upstream is ever bypassed.
- [ ] **VI. Localization** — ⚠️ subtitle is `.tr()`-ed; title is rendered raw. Asymmetry flagged at [features.md (onboard)](../features.md#onboard--b).
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — N/A (pre-login).
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — ⚠️ `Colors.black12` ([onboard_screen.dart:92](../../lib/features/onboard/presentation/onboard_screen.dart#L92)) and `Colors.black38` ([line 220](../../lib/features/onboard/presentation/onboard_screen.dart#L220)) hardcoded. Otherwise sizes use `.h`/`.w`/`.sp`/`.csh`/`.csw`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/onboard/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/onboard/
└── presentation/
    └── onboard_screen.dart   # single ~310-LOC screen
```

### Cross-feature touch points

- **[lib/features/choose_language/presentation/choose_language_screen.dart:137-154](../../lib/features/choose_language/presentation/choose_language_screen.dart#L137-L154)** — pushes `OnBoardScreen` for `parents` flavor when `validList(Config.get.onBoards)`.
- **[lib/features/login/presentation/login_screen.dart](../../lib/features/login/presentation/login_screen.dart)** — navigation target on completion / skip.
- **[lib/core/config/](../../lib/core/config/)** — `ConfigCubit`, `ConfigSelector`, `ConfigListener`, `Config.get`.
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — read `state.language` for the language chip.

**Structure Decision**: Standard single-screen feature with `presentation/`. No bloc needed (the carousel's local state is `PageController` + `index` + `end`, all StatefulWidget state). When the first-install Hive gate is added, a tiny `OnBoardSeenRepo` may be useful — but a single key-value read in `splash` or `choose_language` is also acceptable without a new repo.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Hardcoded `Colors.black12` / `Colors.black38` overlays | Quick dimmer over images / lang chip background. | Replace with `context.colors.scrim` (or equivalent token). [tasks.md T-fix-1](tasks.md). |
| Title rendered raw, subtitle `.tr()`-ed | Original author may have intended titles to be per-school custom (configurable from `config/*`) and subtitles to be product-defined keys. | Resolve the convention and apply consistently. [tasks.md T-fix-3](tasks.md). |
| No first-install Hive flag | Was originally implemented via `SharedPreferences` (commented out) — disabled at some point. | Restore via `LocalDatabaseRepo`. [tasks.md T-fix-2](tasks.md). |
| 310 LOC single file with all inline | Single screen; refactor pressure low. | Extract `OnBoardPage` widget for the per-page contents. [tasks.md T-cleanup-1](tasks.md). |
| Skip CTA hidden on the last page | Original author treated "Start now" as the skip equivalent. | If product wants explicit Skip on every page (per [features.md task](../features.md#onboard--b)), drop the `if (!end)` guard at [line 262](../../lib/features/onboard/presentation/onboard_screen.dart#L262). [tasks.md T-fix-4](tasks.md). |
