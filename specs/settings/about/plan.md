---
status: migrated
feature: settings/about
migrated_from: lib/features/settings/about/
migrated_date: 2026-05-14
---

# Implementation Plan: About

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/about/spec.md](spec.md) and code in [lib/features/settings/about/](../../../lib/features/settings/about/).

## Summary

Static about screen showing app version + brand + about copy + contact info + Share / Rate CTAs. Most of the heavy lifting is `package_info_plus` + `flutter_app_version_checker` on the client; a server `getAbout()` endpoint exists for the contact block but the call is currently commented out.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0`.

**Primary Dependencies**:

- `flutter_bloc` — `AboutBloc extends Bloc<AboutEvents, AboutStates>`.
- `package_info_plus` 8.x — installed version.
- `flutter_app_version_checker` — `canUpdate` flag against store.
- `share_plus` — native share sheet.
- `url_launcher` — open store + marketing URL.
- `flutter_screenutil` — sizing.

**Storage**: none.

**Testing**: none.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature with bloc + repo + model.

**Performance Goals**: First paint ≤ 200ms; version display ≤ 200ms after `FetchAbout`.

**Constraints**:

- `AppVersionChecker.checkUpdate()` does network I/O against the relevant store — must tolerate failure (already wrapped in try/catch).
- The `getAbout()` REST call is **commented out** today; re-enabling it must not block the version + brand render path.

**Scale/Scope**: 6 files, ~400 LOC (mostly UI).

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/`, `repo/`, `models/`, screen at root. ✓
- [x] **II. Dependency Direction** — imports `lib/core/*` only. ✓
- [x] **III. Networking Contract** — `AboutRepo.getAbout()` uses `NetworkClient.handleRequest`. ⚠️ Currently not called.
- [x] **IV. Persistence Discipline** — N/A.
- [x] **V. Flavor Branching** — none observed in the screen; brand differences via `assetsPath()` (flavor-aware via asset substitution).
- [x] **VI. Localization** — all visible copy via `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit (downstream of Settings).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h/.w/.sp/.r` + `context.colors.*`. ⚠️ `Colors.transparent` for the app bar background — intentional for `extendBodyBehindAppBar`.

## Project Structure

### Documentation (this feature)

```text
specs/settings/about/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/about/
├── about_screen.dart                              # full screen with version + brand + contact + share + rate
├── bloc/
│   ├── about_bloc.dart                            # FetchAbout handler; REST call commented out
│   ├── about_events.dart
│   └── about_states.dart                          # AboutStates wrapper + AboutState
├── repo/
│   └── about_repo.dart                            # getAbout() — not called
└── models/
    └── about_model.dart
```

### Cross-feature touch points

- [lib/core/config/config.dart](../../../lib/core/config/config.dart) — `Config.appUrl`, `Config.get.appInfo.{iosUrl, androidUrl, appStoreId, appName}`.
- [lib/core/components/text/powered_by.dart](../../../lib/core/components/text/powered_by.dart) — `PoweredByWidget` footer.
- [lib/shared/assets/assets.gen.dart](../../../lib/shared/assets/assets.gen.dart) — generated asset references.
- [lib/core/utils/funuctions/global_functions.dart](../../../lib/core/utils/funuctions/global_functions.dart) — `assetsPath(...)`.

**Structure Decision**: standard layout (`bloc/`, `repo/`, `models/`).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `getAbout()` REST call commented out | Iteration state; product hadn't shipped contact-block content. | Re-enable and render. **See tasks.md T-fix-1.** |
| `AboutState.copyWith` returns `dynamic` | Quick implementation. | Fix the return type to `AboutState` so callers get type checking. **See tasks.md T-cleanup-1.** |
| `print('AboutBloc.AboutBloc Exception $e')` ([about_bloc.dart:29](../../../lib/features/settings/about/bloc/about_bloc.dart#L29)) and `print('_AboutScreenState.build error: $e')` ([about_screen.dart:326](../../../lib/features/settings/about/about_screen.dart#L326)) | Quick logging during development. | Route through a real logger. **See tasks.md T-cleanup-2.** |
