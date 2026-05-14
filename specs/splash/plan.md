---
status: migrated
feature: splash
migrated_from: lib/features/splash/
migrated_date: 2026-05-14
---

# Implementation Plan: Splash

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

App-boot screen that decides the first real route: language picker (new user), main shell (returning approved user), or approval gate (returning pending user). 4 .dart files. The bloc is a real `Bloc<SplashEvent, SplashState>` (not a Cubit). Owns no REST or Firestore work of its own — delegates to `UserRepo`.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — only feature in the migration set so far that uses `Bloc` instead of `Cubit`
- `dio` 5.8 (via [NetworkClient](../../lib/core/network/network_client.dart) → [UserRepo](../../lib/core/user/data_source/user_repo.dart))
- `hydrated_bloc` 10 — `UserBloc` hydration is the load-bearing input
- `flutter_screenutil` 5.9

**Storage**: HydratedBloc-backed `UserBloc.state` (read). No Hive reads at splash time.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **`presentation/` only**.

**Performance Goals**: First-frame-to-navigation ≤ 5 seconds on a typical 4G connection (2 s branding delay + ≤ 3 s for `UserRepo.getUser`).

**Constraints**:

- The 2-second `Timer` is fixed; needs to become a *minimum* not a *fixed wait* (features.md P2 task).
- No bootstrap step ensures `UserBloc.fromJson` has completed before `FetchSplashEvent` fires — features.md (P0).

**Scale/Scope**: 4 .dart files, < 200 LOC.

## Constitution Check

- [x] **I. Feature-First Layout** — code under `lib/features/splash/presentation/bloc/`. No `data_sources/` because all data work delegates to `core/user/`. ✓
- [x] **II. Dependency Direction** — ✓ Splash uses the **central-registration** pattern per [constitution v1.2.0 principle II](../../.specify/memory/constitution.md). `SplashBloc` is registered at [core/dependency_injection/di.dart:85](../../lib/core/dependency_injection/di.dart#L85); splash owns no repo of its own (consumes `UserBloc` + `UserRepo`).
- [x] **III. Networking Contract** — N/A directly. `UserRepo` uses `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — reads `UserBloc.state.user` (HydratedBloc-backed). No direct Hive. ✓
- [ ] **V. Flavor Branching** — ⚠️ The only branch is a spacing tweak (`if (context.isProfessors) SizedBox(height: 50.h)`). Correct extension usage. ✓ on the rule, but worth a quick note.
- [x] **VI. Localization** — N/A (no user-visible text). ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — splash *is* the gate. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — ⚠️ `Color(0xffF2F2F2)` hardcoded at [splash_screen.dart:83](../../lib/features/splash/presentation/splash_screen.dart#L83). features.md (P2). See [tasks.md T-fix-3](tasks.md).

## Project Structure

### Source Code (existing)

```text
lib/features/splash/
└── presentation/
    ├── splash_screen.dart                # logo + powered-by + listener → router
    └── bloc/
        ├── splash_bloc.dart              # Bloc<SplashEvent, SplashState>
        ├── splash_events.dart            # FetchSplashEvent only
        └── splash_states.dart            # Initial / Loading (unused) / Success(hasUser) / Failure(Failure)
```

### Cross-feature touch points

- **[lib/core/user/](../../lib/core/user/)** — `UserBloc` (HydratedCubit) + `UserRepo`.
- **[lib/features/choose_language/](../../lib/features/choose_language/)** — destination when no user.
- **[lib/features/main/](../../lib/features/main/)** — destination when approved.
- **[lib/features/your_account_under_review/](../../lib/features/your_account_under_review/)** — destination when pending.

**Structure Decision**: Standard, except no `data_sources/` (intentional).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| ~~No feature-root `_di.dart`~~ | ✅ **Resolved 2026-05-14** by [constitution v1.2.0](../../.specify/memory/constitution.md#amendment-log). Splash's central registration is correct. | — |
| `Bloc<SplashEvent, SplashState>` instead of `Cubit` despite only one event | The original author may have anticipated more events; the `Bloc` pattern is harmless. | Refactoring to `Cubit` would be a cosmetic change. Not worth it. |
| 2-second fixed `Timer` for branding visibility | Product wants a moment of brand presence. | Should be a *minimum* (i.e., max of `2s` and "data ready"). See [tasks.md T-fix-1](tasks.md). |
| `SplashLoading` state declared but never emitted | Leftover from earlier iteration; not actively harmful. | Either start using it (during the `getUser` round-trip) or delete it. See [tasks.md T-cleanup-1](tasks.md). |
