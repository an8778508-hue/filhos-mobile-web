---
status: migrated
feature: main
flavor_scope: both
migrated_from: specs/features.md#main--b
migrated_date: 2026-05-14
---

# Feature Specification: Main (Tab Shell)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/main/](../../lib/features/main/) (6 .dart files) and the existing [features.md `## main · B`](../features.md#main--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**:
  - The tab list itself is **fully remote-config-driven** via `ConfigCubit.bottomBar`, which is `Config.get.bottomBar` (a `List<BottomBarItemModel>` parsed from the Firestore `config/*` document). There is no flavor-conditional Dart code that picks tabs; the flavor influence happens at the **config layer** (a teacher build's config document declares a different `bottomBar`).
  - The `BottomBarItemModel.id` strings are matched against the `PageID` enum `{home, diary, events, settings}` ([config.dart:160](../../lib/core/config/config.dart#L160)) in `MainScreen.getWidgetFromBottomBar(...)` ([main_screen.dart:121-138](../../lib/features/main/presentation/main_screen.dart#L121-L138)). Unknown ids render `Placeholder()`.
  - The settings tab carries a notification badge counting unread chat messages from `ChatBloc.unReadMessagesCount` ([custom_bottom_navigation.dart:53-55](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart#L53-L55)). Both flavors show this badge.
- **Server role implication**: None directly — the tab shell doesn't call REST. The bottom-bar config is fetched by `ConfigCubit` from Firestore at app boot.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Render the tab shell from remote config (Priority: P1) 🎯 MVP

A user lands on `MainScreen` after the approval gate. `ConfigCubit.bottomBar` is non-empty, so a `Scaffold` with `PageView` body + custom bottom navigation renders. The first tab is `home` (the initial `MainBloc.currentId`).

**Why this priority**: This is the post-login shell — every other feature is reached through it.

**Independent Test**:
1. Hydrate `ConfigCubit` with a `bottomBar` of `[home, diary, events, settings]`.
2. Push `MainScreen`.
3. `BackgroundServicesBloc.add(CallServices())` fires on init.
4. `PageView` shows the home page (index 0), `CustomBottomNavigation` highlights `home`.
5. Tap `diary` → `MainBloc.add(ChangePage(id: 'diary'))` → emits `ChangePageLading` then `ChangePageSucceed(selectedPage: 'diary')` → listener calls `_pageController.jumpToPage(1)` and the bottom-nav highlight moves.

**Acceptance Scenarios**:

1. **Given** `config.bottomBar` is non-empty, **When** `MainScreen` builds, **Then** the `PageView` renders one child per `BottomBarItemModel`, mapped through `getWidgetFromBottomBar(id)`.
2. **Given** `config.bottomBar` is empty, **When** `MainScreen` builds, **Then** the `PageView` falls back to `[HomeScreen()]` ([main_screen.dart:82](../../lib/features/main/presentation/main_screen.dart#L82)) and the `bottomNavigationBar` is `null` (no bar rendered).
3. **Given** the user taps a tab, **When** the bottom-nav `onTap` fires, **Then** `MainBloc.add(ChangePage(id))` runs. If `id == currentId`, the bloc no-ops (gated by `event.id != currentId` at [main_bloc.dart:12](../../lib/features/main/bloc/main_bloc.dart#L12)).
4. **Given** `ChangePage` is dispatched for a new id, **When** the bloc handles it, **Then** it emits `ChangePageLading`, waits 100 ms (`Future.delayed`), then emits `ChangePageSucceed(selectedPage: id)`.
5. **Given** `ChangePageSucceed` is emitted, **When** `_MainScreenState.handleListener` runs, **Then** `_bottomNavId` is updated and `_pageController.jumpToPage(index)` is called.
6. **Given** the user is on the settings tab and has 3 unread chat messages, **When** the bottom nav renders, **Then** the settings tab shows a red badge with "3" ([custom_bottom_navigation.dart:36](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart#L36)).
7. **Given** each tab's widget is kept alive across tab switches, **When** the user navigates `home → diary → home`, **Then** the home widget's scroll position is preserved (each page is wrapped in `TrueAutomaticKeepAlive` at [main_screen.dart:83](../../lib/features/main/presentation/main_screen.dart#L83)).

---

### User Story 2 - Featured events dialog on entry (Priority: P2)

When `MainScreen` mounts, `FeaturedEventsBloc.fetch()` runs. If the response contains featured events, a dialog opens on top of the shell.

**Why this priority**: This is a side-channel UX surface owned by `featured_events` but driven from `main`. The dialog interrupts the user immediately after login, so coordination lives here.

**Acceptance Scenarios**:

1. **Given** `FeaturedEventsBloc.fetch()` returns a non-empty list, **When** the listener at [main_screen.dart:50-64](../../lib/features/main/presentation/main_screen.dart#L50-L64) fires, **Then** `FeaturedEventsScreen.open(context)` is called and `featuredDialogOpened = true`.
2. **Given** the dialog is open and the featured-events list becomes empty (e.g., after the user dismisses each event), **When** the listener fires again, **Then** `Navigator.of(context).pop()` closes the dialog and `featuredDialogOpened = false`.
3. **Given** the dialog has already been opened in this session, **When** the listener fires with a non-empty list again, **Then** the dialog is **not** re-opened (`if (!featuredDialogOpened)` guard at [main_screen.dart:54](../../lib/features/main/presentation/main_screen.dart#L54)).

---

### User Story 3 - Side-effects on mount (Priority: P2)

`MainScreen` initiates several side-effects on first build: background services start, featured events fetch, and tracking permission is requested after first frame.

**Acceptance Scenarios**:

1. **Given** `MainScreen.initState` runs, **When** the frame begins, **Then** `BackgroundServicesBloc.add(CallServices())` fires (start FCM listeners, approval polling, etc.).
2. **Given** the first frame completes, **When** `addPostFrameCallback` runs, **Then** `ensureTrackingPermission()` is called — a no-op on non-iOS and idempotent when ATT has already been decided.
3. **Given** `BackgroundServicesBloc(CallServices)` is already running from a previous mount in this session, **When** the user reaches `MainScreen` again, **Then** the bloc's own re-entrancy handling determines behavior (out of scope for this feature).

---

### Edge Cases

- **Empty bottom bar from remote config**: `PageView` falls back to `[HomeScreen()]`, bottom navigation is `null`. The user is stranded on home with no navigation — survivable but degraded. See [tasks.md T-fix-3](tasks.md).
- **Unknown `BottomBarItemModel.id`**: `getWidgetFromBottomBar(id)` returns `Placeholder()` if `id` doesn't match any `PageID` value. This means a config that adds a new tab id (e.g., `chat`) without a matching client release shows a placeholder, not the intended screen. See [tasks.md T-fix-4](tasks.md).
- **`Future.delayed(Duration(milliseconds: 100))`** in `MainBloc` before emitting `ChangePageSucceed` ([main_bloc.dart:15](../../lib/features/main/bloc/main_bloc.dart#L15)) — intentional UX delay to let the loading state render briefly? Or a leftover from a previous implementation? See [tasks.md T-fix-5](tasks.md).
- **Tab order vs flavor**: features.md tasks "Document the tab order per flavor". Reality: the tab order is **identical in code** for both flavors (driven by config). The flavor differentiation is at the config layer, not the app. See [Functional Requirements](#functional-requirements). The default `PageID` ordering is `home, diary, events, settings` — same in both flavors as long as both config documents agree.
- **Background pushes switching tabs**: features.md tasks "Add a guard so background pushes don't switch tabs while the user is mid-flow." There is no current guard — any push deep-link that lands the user on `MainScreen` and then dispatches `ChangePage` will fire mid-typing / mid-form-edit. See [tasks.md T-fix-1](tasks.md).
- **`MainBloc.currentId` is instance state, not Equatable-tracked state**: the `String currentId` field on `MainBloc` lives outside the state object. `MainBloc.state` only carries the *transition* (`ChangePageLading` / `ChangePageSucceed`), so a consumer can't read "the currently selected id" from the state alone — they must read `bloc.currentId`. See [tasks.md T-fix-6](tasks.md).
- **Approval gate**: `MainScreen` is the destination after the approval gate. Users with `isApproval == false` are routed to `your_account_under_review` and never reach `MainScreen`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST own a `MainBloc` that tracks the currently selected tab via an instance field `currentId: String` (default `PageID.home.name`).
- **FR-002**: System MUST render a `Scaffold` with body = `PageView` (no scroll physics — programmatic navigation only) and `bottomNavigationBar = CustomBottomNavigation` when `config.bottomBar` is non-empty.
- **FR-003**: System MUST drive both the `PageView` children and the bottom-nav items from `ConfigSelector(selector: bottomBar)`. The two selectors observe the same config slice.
- **FR-004**: System MUST map each `BottomBarItemModel.id` to a Flutter widget via `getWidgetFromBottomBar(id)`:

  | `PageID` | Widget |
  |---|---|
  | `home` | [HomeScreen](../../lib/features/home/home_screen.dart) |
  | `diary` | [DiaryScreen](../../lib/features/diary/presentation/dairy_screen.dart) — note typo'd filename `dairy_screen.dart` |
  | `events` | [EventsScreen](../../lib/features/settings/events/event_screen.dart) — lives under `settings/events/` not at a feature root |
  | `settings` | [SettingsScreen](../../lib/features/settings/settings_screen.dart) |
  | _unknown_ | `Placeholder()` |

- **FR-005**: System MUST wrap every `PageView` child in `TrueAutomaticKeepAlive` ([core/components/true_automatic_keep_alive.dart](../../lib/core/components/true_automatic_keep_alive.dart)) so per-tab state (scroll position, in-page form fields) survives tab switches.
- **FR-006**: System MUST emit `ChangePageLading` → `ChangePageSucceed(selectedPage: id)` with a 100 ms delay between when `ChangePage(id)` is dispatched for a tab different from the current. Identical-id `ChangePage` is a no-op.
- **FR-007**: System MUST keep `_bottomNavId` (selected-tab state owned by `_MainScreenState`) in sync with `MainBloc.currentId` via the `BlocConsumer.listener` on `ChangePageSucceed`.
- **FR-008**: System MUST fire `BackgroundServicesBloc.add(CallServices())` on mount.
- **FR-009**: System MUST call `FeaturedEventsBloc.fetch()` on mount and open `FeaturedEventsScreen` as a dialog when the response is non-empty. Re-open is guarded by `featuredDialogOpened`.
- **FR-010**: System MUST request iOS App Tracking Transparency permission **after** the first frame via `addPostFrameCallback`, so the user has already seen the in-app surfaces before the OS dialog appears. No-op on non-iOS.
- **FR-011**: System MUST render a notification badge on the settings tab whose count is `ChatBloc.unReadMessagesCount` (via `context.watch<ChatBloc>()`). The badge is suppressed when the count is null or zero.
- **FR-012**: System MUST allow remote config to add new `BottomBarItemModel` entries without an app release — but only for entries whose `id` matches an existing `PageID` value. Unknown ids show `Placeholder()` (graceful degradation).

### Localization Requirements

| Key | Use site |
|---|---|
| (per-tab `translationKey`) | Bottom-nav label, resolved via `BottomBarItemModel.translationKey.tr(context)` when set; falls back to `BottomBarItemModel.title` (raw string from config) otherwise ([custom_bottom_navigation.dart:39](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart#L39)) |

No localization keys are owned by the `main` feature itself — every visible string is delegated to the per-tab feature or to remote-config-provided translation keys.

### Backend Touchpoints

- **No REST endpoints** owned by `main`.
- **Firestore**: indirectly — the bottom-bar config flows through `ConfigCubit` from Firestore `config/*`.
- **FCM**: indirectly — `BackgroundServicesBloc(CallServices)` wires the FCM token handlers; push handlers route through `NotificationHelper` which can navigate to specific tabs. No direct push handling in `main`.

### Permissions & Approval Gate

- Reached **only post-approval**. The approval gate lives in the login / OTP / your-account-under-review flow; `MainScreen` is the canonical "you're in" destination.
- Device permissions:
  - **App Tracking Transparency** (iOS) — requested after first frame via `ensureTrackingPermission()`.

### Key Entities

- **`MainBloc`** ([main_bloc.dart](../../lib/features/main/bloc/main_bloc.dart)) — `Bloc<MainEvent, MainState>` holding the current tab id as an instance field. Sealed events: `ChangePage(id)`. Sealed states: `MainInitial`, `ChangePageLading` (sic — typo: should be `Loading`), `ChangePageSucceed(selectedPage)`.
- **`BottomBarItemModel`** ([core/config/config.dart:162](../../lib/core/config/config.dart#L162)) — `{id, translationKey, title, activeIcon, inActiveIcon}` parsed from the remote `config/*` document.
- **`PageID`** ([core/config/config.dart:160](../../lib/core/config/config.dart#L160)) — enum `{home, diary, events, settings}`. Acts as the closed set of tab destinations the client knows about; unknown ids fall through to `Placeholder()`.
- **`BottomNavigationItem`** ([bottom_navigation_item.dart:100](../../lib/features/main/presentation/widgets/bottom_navigation_item.dart#L100)) — UI-side display model `{title, icon, id}`.
- **`BottomNavigationItemWidget`** ([bottom_navigation_item.dart:6](../../lib/features/main/presentation/widgets/bottom_navigation_item.dart#L6)) — renders a single tab tile with an optional notification badge.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tab switch tap → page settled animation completes in ≤ 200 ms on a typical Android device (100 ms intentional `Future.delayed` + < 100 ms `jumpToPage`).
- **SC-002**: Cold-start → home tab interactive in ≤ 2 s (gate: config hydrated + first frame + background services kick).
- **SC-003**: Tab switches preserve per-tab scroll position and in-page form input across at least 5 round-trips (parents flow: home → diary → settings → diary → home, in any order).
- **SC-004**: A background push that deep-links to a specific tab arrives in the user's view within 1 s, ⚠️ but currently **does not** guard against interrupting an in-progress flow (form input, chat composition). See [tasks.md T-fix-1](tasks.md).
- **SC-005**: The featured-events dialog opens at most **once** per cold-start session, even if `FeaturedEventsBloc` re-emits a non-empty list (guarded by `featuredDialogOpened`).

## Assumptions

- The bottom-bar config in Firestore declares ids that the client release knows about (`PageID` enum values). Adding a new tab requires a coordinated config + app release.
- Both flavors' `config/*` documents declare the same `PageID` set in the same canonical order (`home, diary, events, settings`) — verified empirically but not enforced in code.
- `BackgroundServicesBloc(CallServices)` is idempotent w.r.t. being dispatched once per cold-start (multiple dispatches would be a leak, but `MainScreen.initState` runs once per session).
- The 100 ms `Future.delayed` in `MainBloc` is intentional UX padding to surface the `ChangePageLading` state for screens that animate on it; not a bug, but not commented either.
- `bottom_navy_bar: ^6.1.0` is declared in [pubspec.yaml:52](../../pubspec.yaml#L52) **but is not actually used in the main feature today** — the bottom bar is a custom widget ([CustomBottomNavigation](../../lib/features/main/presentation/widgets/custom_bottom_navigation.dart)). The package is either reserved for future use or a dead dependency. ⚠️ Diverges from [features.md](../features.md#main--b) which describes the shell as "Tab shell with `bottom_navy_bar`".
