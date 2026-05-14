---
status: migrated
feature: main
migrated_from: lib/features/main/
migrated_date: 2026-05-14
---

# Implementation Plan: Main (Tab Shell)

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/main/spec.md](spec.md) and code in [lib/features/main/](../../lib/features/main/) (6 .dart files).

## Summary

`main` is the post-approval tab shell. It owns `MainBloc` (current tab id), wires the bottom-bar items + `PageView` children from remote config, and triggers three side-effects on mount: background-services kick, featured-events fetch (with one-shot dialog), and post-frame iOS App Tracking Transparency permission. The bar widget itself is custom (`CustomBottomNavigation`) — the `bottom_navy_bar` package is declared in pubspec but **not used here**; the [features.md](../features.md#main--b) description ("Tab shell with `bottom_navy_bar`") is inaccurate. Open work from features.md: tab-order-per-flavor doc (deferred — both flavors share order) and a mid-flow push-tab-switch guard.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `MainBloc` is a `Bloc<MainEvent, MainState>`; the screen also reads `FeaturedEventsBloc`, `BackgroundServicesBloc`, `ChatBloc` via `context.read` / `context.watch`
- `equatable` 2.0 — sealed events and states
- `flutter_screenutil` 5.9
- `provider` 6.1 — implicit through `BlocProvider`
- `bottom_navy_bar` 6.1.0 — **declared in [pubspec.yaml:52](../../pubspec.yaml#L52) but not imported anywhere under `lib/features/main/`** — see [tasks.md T-cleanup-3](tasks.md).

**Storage**: None directly. The bottom-bar configuration is read from `ConfigCubit` (hydrated from Firestore).

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Shell composition layer; very thin.

**Performance Goals**:

- Tab switch ≤ 200 ms.
- No rebuild storms on `ConfigCubit` change (currently re-renders the whole `Scaffold` when bottom bar changes; acceptable because config rarely changes mid-session).

**Constraints**:

- Tab id is held both in `MainBloc.currentId` (instance field) AND in `_MainScreenState._bottomNavId` (widget field). These are kept in sync manually via the bloc listener; a discrepancy would result in the bottom-nav highlight not matching the visible page.
- `PageView` is non-scrollable (`NeverScrollableScrollPhysics`) so tab switches are programmatic only — swipe between tabs is intentionally disabled.

**Scale/Scope**: 6 .dart files. ~200 LOC total.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/main/` with `bloc/` and `presentation/{widgets/}`. ⚠️ The presentation layer is `presentation/` (matches login + chat); other features mix variants. Acceptable.
- [x] **II. Dependency Direction** — `MainBloc` is registered via [main_di.dart](../../lib/features/main/main_di.dart) ... wait — there is no `main_di.dart`. Let me verify: it's registered centrally in [init_dependencies.dart](../../lib/init_dependencies.dart) via `di.registerFactory<MainBloc>(() => MainBloc())`. Constitution drift: no feature-root DI file. Same drift as `add_form`. See [tasks.md T-cleanup-2](tasks.md).
- [x] **III. Networking Contract** — N/A (no REST in this feature).
- [x] **IV. Persistence Discipline** — N/A.
- [x] **V. Flavor Branching** — no `mainKey.currentContext` usage. Flavor differentiation is via remote config, not Dart code. ✓
- [x] **VI. Localization** — bottom-nav titles use `translationKey.tr(context)` with fallback to the raw `title` from config ([custom_bottom_navigation.dart:39](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart#L39)). ✓
- [x] **VII. Chat Source of Truth** — N/A directly; `ChatBloc` is consumed for the unread-count badge only.
- [x] **VIII. Approval Gate** — `MainScreen` is the canonical post-gate destination. ✓
- [x] **IX. Medicine Reminders** — N/A directly.
- [x] **X. Theming & Sizing** — `.h` / `.w` / `.csh` / `.csw` everywhere; colors via `context.colors.*`. ✓ One hardcoded `Colors.white` at [main_screen.dart:68](../../lib/features/main/presentation/main_screen.dart#L68) and [:73](../../lib/features/main/presentation/main_screen.dart#L73) as a background — should route through `context.colors.background`. See [tasks.md T-cleanup-1](tasks.md).

## Project Structure

### Documentation (this feature)

```text
specs/main/
├── spec.md              # User scenarios, requirements, success criteria
├── plan.md              # This file
└── tasks.md             # Migration tasks + gaps from features.md
```

### Source Code (existing)

```text
lib/features/main/
├── bloc/
│   ├── main_bloc.dart                              # Bloc<MainEvent, MainState> + currentId instance field
│   ├── main_event.dart                             # part-of — ChangePage(id)
│   └── main_state.dart                             # part-of — MainInitial / ChangePageLading / ChangePageSucceed
└── presentation/
    ├── main_screen.dart                            # Scaffold + PageView + listeners + side-effects
    └── widgets/
        ├── custom_bottom_navigation.dart           # outer bar — drives items from ConfigSelector
        └── bottom_navigation_item.dart             # single tab tile + notification badge
```

### Cross-feature touch points

- [lib/core/config/config.dart](../../lib/core/config/config.dart) — `Config.get.bottomBar`, `PageID`, `BottomBarItemModel`.
- [lib/core/config/widgets/config_builder.dart](../../lib/core/config/widgets/config_builder.dart) — `ConfigSelector(selector: bottomBar)`.
- [lib/core/components/true_automatic_keep_alive.dart](../../lib/core/components/true_automatic_keep_alive.dart) — wraps every `PageView` child.
- [lib/core/utils/tracking_permission.dart](../../lib/core/utils/tracking_permission.dart) — `ensureTrackingPermission()` post-frame iOS ATT.
- [lib/features/background_services/bloc/background_services_bloc.dart](../../lib/features/background_services/bloc/background_services_bloc.dart) — `CallServices` event dispatched on mount.
- [lib/features/featured_events/bloc/featured_events_bloc.dart](../../lib/features/featured_events/bloc/featured_events_bloc.dart) — `.fetch()` dispatched on mount; listener opens the dialog.
- [lib/features/featured_events/featured_events_screen.dart](../../lib/features/featured_events/featured_events_screen.dart) — `FeaturedEventsScreen.open(context)`.
- [lib/features/chat/presentation/bloc/chat_bloc.dart](../../lib/features/chat/presentation/bloc/chat_bloc.dart) — `context.watch<ChatBloc>().unReadMessagesCount` for the settings-tab badge.
- [lib/features/home/home_screen.dart](../../lib/features/home/home_screen.dart) — `home` page destination.
- [lib/features/diary/presentation/dairy_screen.dart](../../lib/features/diary/presentation/dairy_screen.dart) — `diary` page destination (note typo'd filename).
- [lib/features/settings/events/event_screen.dart](../../lib/features/settings/events/event_screen.dart) — `events` page destination (lives under `settings/events/` — see [tasks.md T-cleanup-4](tasks.md)).
- [lib/features/settings/settings_screen.dart](../../lib/features/settings/settings_screen.dart) — `settings` page destination.

**Structure Decision**: Standard layout. No feature-root DI file (registered centrally) — same drift as `add_form` and worth aligning.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `MainBloc.currentId` instance field alongside `MainState` | Originally `MainState` was a sealed transition-only model; storing the current id in the state would have meant emitting on every read (no Equatable diff to suppress). | Move `currentId` into `MainInitial` / `ChangePageSucceed` as a single property; default state would always include the current id. Cleaner but requires updating every reader. See [tasks.md T-fix-6](tasks.md). |
| `_bottomNavId` field on `_MainScreenState` shadowing `MainBloc.currentId` | The widget needs to react locally (bottom-nav highlight) without rebuilding the whole `Scaffold`. | Use a `BlocSelector` against a richer `MainState` that includes `currentId`. Combined with the fix above. |
| Hardcoded `Colors.white` background at [main_screen.dart:68](../../lib/features/main/presentation/main_screen.dart#L68) and [:73](../../lib/features/main/presentation/main_screen.dart#L73) | Quick prototype default. | `context.colors.background`. See [tasks.md T-cleanup-1](tasks.md). |
| `bottom_navy_bar` package declared in pubspec but never imported | Possibly left over from an earlier prototype that used it; the current `CustomBottomNavigation` is hand-rolled. | Remove from pubspec OR adopt the package. See [tasks.md T-cleanup-3](tasks.md). |
| `Events` page lives at [lib/features/settings/events/event_screen.dart](../../lib/features/settings/events/event_screen.dart) — under `settings/`, not at feature root | Original organization treated events as a settings sub-feature; the bottom-nav promotion came later. | Promote `events/` to a feature root. See [tasks.md T-cleanup-4](tasks.md). |
| `Future.delayed(Duration(milliseconds: 100))` in `MainBloc` between `ChangePageLading` and `ChangePageSucceed` | Intentional UX padding (so a momentary loading indicator can render between taps). | Either document inline or remove if no downstream screen depends on the `ChangePageLading` state. See [tasks.md T-fix-5](tasks.md). |
| Sealed state with typo `ChangePageLading` (should be `ChangePageLoading`) | Typo at original implementation. | Rename — touches `main_state.dart` + `_MainScreenState.handleListener` + any third-party listeners (none today). See [tasks.md T-cleanup-5](tasks.md). |
| Bottom-bar config items drive `PageView` order **and** `BottomNavigation` order from the same `ConfigSelector`, but the two `ConfigSelector` widgets each re-resolve the list independently | Convenience — keeps the two render trees independent. | Lift the resolved list once with a `ConfigBuilder` at the top of `MainScreen`, pass down. Minor perf optimization. |
| No guard preventing a deep-link push from switching tabs mid-flow | [features.md task](../features.md#main--b) — open. | Inspect `Form.of(context).isDirty` (or a similar dirty-state flag from the active tab) before applying a programmatic `ChangePage`. Coordination cost across features. See [tasks.md T-fix-1](tasks.md). |
