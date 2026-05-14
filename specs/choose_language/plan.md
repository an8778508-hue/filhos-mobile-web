---
status: migrated
feature: choose_language
migrated_from: lib/features/choose_language/
migrated_date: 2026-05-14
---

# Implementation Plan: Choose Language

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Language picker (EN / PT / AR by default; whatever the school's `config/*` declares). 1 .dart file, ~180 LOC. No bloc, no data layer, no models in the feature. Reads `Config.get.langs`; writes `UserBloc.selectLang(code, codeWithLocale)`; re-routes based on flavor + onBoards. Doubles as the settings → change-language picker via the `fromSettings` flag.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `ConfigSelector`, `BlocProvider`, plus reads `MainBloc` via `context.read`
- `flutter_screenutil` 5.9 — `.h`/`.w`/`.r`/`.sp`/`.csh`/`.csw`
- `ConfigCubit` (read) — `langs`
- `UserBloc` (write) — `selectLang(code, codeWithLocale)`

**Storage**: none directly. `UserBloc.state.language` is HydratedCubit-persisted.

**Testing**: none today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; `presentation/` only.

**Performance Goals**: One tap → next screen in ≤ 3 s (dominated by `ConfigCubit.init` re-fetch of translations).

**Constraints**:

- Flavor branching for post-selection routing is **duplicated** in the static `push` helper and in the row `onPressed` callback. Drift risk.
- No "currently selected" affordance.
- The `mounted` guard is inconsistent between the `fromSettings` and the normal branch.

**Scale/Scope**: 1 .dart file, ~180 LOC.

## Constitution Check

- [x] **I. Feature-First Layout** — `lib/features/choose_language/presentation/choose_language_screen.dart`. ✓
- [x] **II. Dependency Direction** — no bloc owned; no DI registration. ✓
- [x] **III. Networking Contract** — N/A (no HTTP).
- [x] **IV. Persistence Discipline** — writes via `UserBloc.selectLang` (HydratedCubit). ✓
- [x] **V. Flavor Branching** — uses `context.isProfessors` via the extension from [lib/flavors/app_flavors.dart](../../lib/flavors/app_flavors.dart). ✓ Pattern is correct; **duplication** (same branch in two places) is the cleanup item.
- [x] **VI. Localization** — no visible strings owned by this screen (language titles come from remote config). ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — N/A (pre-login path), and the `fromSettings` path is reached only by an authenticated user.
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — ⚠️ hardcoded `Color(0xff053E60)` on the background overlay at [line 89](../../lib/features/choose_language/presentation/choose_language_screen.dart#L89). Otherwise sizes use `.h`/`.w`/`.sp`/`.csh`/`.csw` correctly.

## Project Structure

### Documentation (this feature)

```text
specs/choose_language/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/choose_language/
└── presentation/
    └── choose_language_screen.dart   # single ~180-LOC screen
```

### Cross-feature touch points

- **[lib/features/splash/presentation/splash_screen.dart](../../lib/features/splash/presentation/splash_screen.dart)** — calls `ChooseLanguageScreen.push(context)` when `!hasUser`.
- **[lib/features/settings/settings_screen.dart:212](../../lib/features/settings/settings_screen.dart#L212)** — pushes `ChooseLanguageScreen(fromSettings: true)`.
- **[lib/features/onboard/presentation/onboard_screen.dart:226](../../lib/features/onboard/presentation/onboard_screen.dart#L226)** — pushes plain `ChooseLanguageScreen()` from the in-carousel language chip.
- **[lib/features/login/presentation/login_screen.dart](../../lib/features/login/presentation/login_screen.dart)** — destination after selection (both flavors, parents w/o onBoards).
- **[lib/features/onboard/presentation/onboard_screen.dart](../../lib/features/onboard/presentation/onboard_screen.dart)** — destination after selection (parents flavor w/ onBoards).
- **[lib/features/main/bloc/main_bloc.dart](../../lib/features/main/bloc/main_bloc.dart)** — `ChangePage(id: PageID.home.name)` dispatched in the `fromSettings` branch.
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — `selectLang(code, codeWithLocale)`.
- **[lib/core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart)** — new home of the ATT call after the P0 move (2026-05-14).

**Structure Decision**: Single-screen feature, no subdirs beyond `presentation/`. Adding a small `ChooseLanguageBloc` (or even a `Cubit`) would clean up the routing logic but is overkill for a 180-LOC screen.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Hardcoded `Color(0xff053E60)` overlay ([line 89](../../lib/features/choose_language/presentation/choose_language_screen.dart#L89)) | Background-decoration tint, matches splash and `your_account_under_review`. | Replace with a `context.colors.*` token; consolidate the same drift in three screens. [tasks.md T-fix-1](tasks.md). |
| Routing logic duplicated in static `push` helper and row `onPressed` | Static helper is used by splash/onboard; row callback is used by direct taps. | Extract a single `_routeAfterSelection(BuildContext, {bool fromSettings})` method. [tasks.md T-cleanup-2](tasks.md). |
| Duplicate imports ([lines 1, 4, 7, 8, 14, 16](../../lib/features/choose_language/presentation/choose_language_screen.dart#L1-L17)) | Slipped in over time. | Dedupe; `flutter analyze` should catch most. [tasks.md T-cleanup-1](tasks.md). |
| `mounted` guard only in one branch | `fromSettings` branch returns synchronously after the `await`; the original author may have assumed safety. | Add `if (!mounted) return;` after `await UserBloc.get.selectLang(...)` regardless of which branch is taken. [tasks.md T-fix-2](tasks.md). |
| No "selected language" indicator | Single-purpose first-run picker. | Add a check icon (or border) on the row whose `code == UserBloc.state.language`. [tasks.md T-fix-3](tasks.md). |
| ~~ATT prompt at line 63-72~~ | ✅ **Resolved 2026-05-14**. Moved to `MainScreen.initState` via [core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart). | — |
