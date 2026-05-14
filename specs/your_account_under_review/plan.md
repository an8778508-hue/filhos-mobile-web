---
status: migrated
feature: your_account_under_review
migrated_from: lib/features/your_account_under_review/
migrated_date: 2026-05-14
---

# Implementation Plan: Your Account Under Review

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Single-screen approval gate displayed to any user whose `UserModel.isApproval == false`. Owns no data layer. Dispatches `BackgroundServicesBloc.CallServices` on entry to keep FCM token and user data fresh while the user waits for approval. **Approval-gate enforcement is cross-cutting**: 5 separate navigators must respect it (splash, OTP, login social, login email, register, plus push deep-link handler).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — reads `BackgroundServicesBloc` from context (does not own a bloc)
- `flutter_screenutil` 5.9 — `.h`/`.w`/`.sp` sizing
- No HTTP, no Firestore, no Hive direct access

**Storage**: none directly. `UserBloc.state.user` is HydratedBloc-backed and consulted by upstream routers.

**Testing**: None today. [features.md (P0)](../features.md#your_account_under_review--b): "Add an integration / widget test that proves the gate works from splash, OTP success, AND a push tap from terminated state." Still pending.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **`presentation/` only**.

**Performance Goals**: First-paint < 200 ms after mount. `CallServices` dispatch happens in `initState`; the network refresh it triggers does not block the UI.

**Constraints**:

- Cross-feature import of `LogoBackGround` from [splash_screen.dart:126](../../lib/features/splash/presentation/splash_screen.dart#L126). Cross-feature widget reuse is flagged at the [features.md cross-feature task](../features.md#cross-feature-tasks).
- Cross-feature import of `LoginScreen` from [features/login/](../../lib/features/login/) — acceptable navigation target but adds to the cross-feature import surface.
- `TickerProviderStateMixin` on the state class is unused (no animation). Inherited from a prior iteration.

**Scale/Scope**: 1 .dart file, ~105 LOC.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/your_account_under_review/presentation/`. No `data_sources/` (intentional — owns no data). No `models/`. ✓
- [x] **II. Dependency Direction** — no feature-root `_di.dart` needed; the screen owns no bloc. Consumes `BackgroundServicesBloc` from the surrounding tree (central registration). ✓ per [constitution v1.2.0 principle II](../../.specify/memory/constitution.md).
- [x] **III. Networking Contract** — N/A (no network calls here).
- [x] **IV. Persistence Discipline** — N/A.
- [x] **V. Flavor Branching** — no flavor branches present; correct (same gate for both flavors). ✓
- [x] **VI. Localization** — both visible strings are `LocalizationKeys.*.tr(context)`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — this *is* the gate. Cross-cutting enforcement points listed in [spec.md FR-005](spec.md#functional-requirements).
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — ⚠️ hardcoded `Color(0xff053E60)` at [your_account_under_review_screen.dart:36](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L36). See [tasks.md T-fix-1](tasks.md). Otherwise sizing uses `.h`/`.w`/`.sp`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/your_account_under_review/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/your_account_under_review/
└── presentation/
    └── your_account_under_review_screen.dart   # single screen
```

### Cross-feature touch points

- **[lib/features/background_services/](../../lib/features/background_services/)** — `CallServices` dispatched on mount.
- **[lib/features/login/presentation/login_screen.dart](../../lib/features/login/presentation/login_screen.dart)** — navigation target of "login with another account" CTA.
- **[lib/features/splash/presentation/splash_screen.dart](../../lib/features/splash/presentation/splash_screen.dart)** — `LogoBackGround` reused via cross-feature import.
- **[lib/core/notifications_service/notification_helper.dart](../../lib/core/notifications_service/notification_helper.dart)** — enforces the gate on push tap (post-2026-05-14 fix).

**Structure Decision**: Minimum viable layout. No bloc, no data sources, no models. Correct for a screen that observes a single boolean owned by `UserBloc`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Hardcoded `Color(0xff053E60)` ([line 36](../../lib/features/your_account_under_review/presentation/your_account_under_review_screen.dart#L36)) | None — drift. | Replace with a `context.colors.*` token. See [tasks.md T-fix-1](tasks.md). |
| Cross-feature import of `LogoBackGround` from splash | Avoids duplicating the widget. | Move `LogoBackGround` to `lib/core/components/`; both features consume it from core. Tracked at [features.md cross-feature task](../features.md#cross-feature-tasks). |
| `TickerProviderStateMixin` declared but unused | None — vestigial. | Remove; the screen has no animation. See [tasks.md T-cleanup-1](tasks.md). |
| Approval-gate enforcement scattered across 5 navigators | The flag is a property of the user, not a property of any one screen. | A central `RouteGuard` middleware would consolidate the check; not implemented today and would be a larger refactor. Tracked. |
