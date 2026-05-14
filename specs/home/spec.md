---
status: migrated
feature: home
flavor_scope: both
migrated_from: specs/features.md#home--b
migrated_date: 2026-05-14
---

# Feature Specification: Home (Dashboard)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/home/](../../lib/features/home/) (16 .dart files) and the existing [features.md `## home · B`](../features.md#home--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores) — same screen, two distinct dashboards.
- **Flavor-conditional behavior**:
  - **Parents** see (in order): `HomeCardsList` (the per-child summary cards), `ChildrenMenus` (today's menu), an Events horizontal row, and a `my_children` horizontal list rendering [HomeChildItem](../../lib/features/home/widgets/home_child_item.dart) cards. Branching at [home_screen.dart:138-145](../../lib/features/home/home_screen.dart#L138-L145), [:180-206](../../lib/features/home/home_screen.dart#L180-L206).
  - **Teachers** see the Events row, plus a remote-config-driven `home_sections` grid ([home_screen.dart:207-246](../../lib/features/home/home_screen.dart#L207-L246)). They also get a search icon in the app bar that pushes [SearchScreen](../../lib/features/search/presentation/search_screen.dart) ([home_screen.dart:110-121](../../lib/features/home/home_screen.dart#L110-L121)).
  - `getAlarms(context)` is called on `initState` and on `AppLifecycleState.resumed`. Inside `getAlarms` the work is gated by `if (context.isProfessors)` ([alarm_manager.dart:21](../../lib/core/utils/alarm_manager/alarm_manager.dart#L21)) — so teacher dashboards refresh their medicine alarm list, parent dashboards no-op.
- **Server role implication**: endpoint differs by role — `teacher/home` for teachers, `parent/home` for parents. Resolved via `isCurrentUserProfessor` in [home_repo.dart:7](../../lib/features/home/data_source/home_repo.dart#L7) (was previously `mainKey.currentContext`-based; fixed).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Parent dashboard (Priority: P1) 🎯 MVP

A parent opens the app post-login, lands on the Home tab, and sees: their name in the app bar, a child-card row, today's menus for their children, upcoming events, and a "My Children" horizontal list to switch into a child's diary.

**Why this priority**: Home is the parent's daily entry point. If it doesn't render, the app is unusable.

**Independent Test**:
1. Cold-start the parents flavor with an approved logged-in account.
2. `HomeBloc.add(HomeFetchDataEvent())` fires from `BlocProvider.create` ([home_screen.dart:70](../../lib/features/home/home_screen.dart#L70)).
3. `HomeImpl.getHomeData()` calls `GET parent/home` and parses `{data: {events: [...], childs: [...]}}` into `HomeModel`.
4. The screen renders four sections: cards, menus, events, my-children.

**Acceptance Scenarios**:

1. **Given** a parent user is logged in, **When** `HomeScreen` mounts, **Then** `HomeBloc` fetches via `parent/home` and emits `HomeFetchedSuccessfully(homeModel)`.
2. **Given** a parent has 0 children registered, **When** the home loads, **Then** the `my_children` section renders [EmptyWidget](../../lib/core/components/empty/empty_widget.dart) with `LocalizationKeys.no_children` and the child-list ListView is suppressed ([home_screen.dart:202-205](../../lib/features/home/home_screen.dart#L202-L205)).
3. **Given** events for today are empty, **When** rendering, **Then** the Events header + horizontal row are suppressed (`if (events.isNotEmpty)` gate at [home_screen.dart:147](../../lib/features/home/home_screen.dart#L147)). ⚠️ The intended `else { EmptyWidget(no_events) }` branch is commented out at [home_screen.dart:176-179](../../lib/features/home/home_screen.dart#L176-L179) — see Edge Cases.
4. **Given** the user pulls down on the home, **When** the gesture completes, **Then** `ReloadHomeFetchDataEvent(completer)` fires, the loading-indicator stays up via the completer, and the bloc re-fetches.
5. **Given** the user taps a child card in the `my_children` list, **When** the tap fires, **Then** `Navigator.push(DiaryScreen(child: child))` is invoked ([home_child_item.dart:22-23](../../lib/features/home/widgets/home_child_item.dart#L22-L23)).
6. **Given** the user's `image` is set, **When** the app bar renders, **Then** the avatar is shown next to the greeting; falls back to a generic avatar otherwise.

---

### User Story 2 - Teacher dashboard (Priority: P1)

A teacher opens the app post-login, lands on the Home tab, and sees: their name in the app bar with a search button, an Events row of school-wide events, and a `home_sections` grid driven by remote config (e.g., shortcuts to common teacher flows).

**Why this priority**: Home is the teacher's daily entry point.

**Acceptance Scenarios**:

1. **Given** a teacher user is logged in, **When** `HomeScreen` mounts, **Then** `HomeBloc` fetches via `teacher/home`.
2. **Given** the teacher tap the search icon in the app bar, **When** the tap fires, **Then** `WidgetFunctions.navigateTo(SearchScreen)` is called ([home_screen.dart:112-114](../../lib/features/home/home_screen.dart#L112-L114)).
3. **Given** `config.homeSections` is non-empty, **When** rendering, **Then** a 2-column grid of `HomeSectionsItem` renders with aspect ratio 190:230 ([home_screen.dart:227-241](../../lib/features/home/home_screen.dart#L227-L241)).
4. **Given** `config.homeSections` is empty, **When** rendering, **Then** the entire sections block is suppressed (no empty-state copy).
5. **Given** the teacher resumes the app from background, **When** `AppLifecycleState.resumed` fires, **Then** `getAlarms(context)` runs — which, gated by `context.isProfessors`, re-syncs the medicine alarms via `AlarmManager.getAlarms(context)` ([alarm_manager.dart:18-27](../../lib/core/utils/alarm_manager/alarm_manager.dart#L18-L27)).

---

### User Story 3 - Cross-feature reactive refresh (Priority: P2)

When another feature mutates an entity that affects home (an event is added, an RSVP is accepted/rejected), the home should silently re-fetch without the user pulling to refresh.

**Why this priority**: UX polish; not core but expected.

**Acceptance Scenarios**:

1. **Given** the user creates an event via `add_form`, **When** `eventBus.fire(EventAdded())` fires on save success, **Then** `HomeBloc.listen` catches it and dispatches `ReloadHomeFetchDataEvent(silent: false, completer: null)` ([home_bloc.dart:22-26](../../lib/features/home/bloc/home_bloc.dart#L22-L26)).
2. **Given** the user accepts or rejects an event RSVP, **When** `EventAcceptedOrRejected` fires, **Then** home reloads via the same handler.

---

### Edge Cases

- **`getAlarms(context)` after `await`**: [features.md task](../features.md#home--b) flagged: `getAlarms(context)` is called from `initState` ([home_screen.dart:45](../../lib/features/home/home_screen.dart#L45)) and from `didChangeAppLifecycleState` ([home_screen.dart:59](../../lib/features/home/home_screen.dart#L59)). The function internally calls `di<AlarmManager>().getAlarms(context)` which `await`s an API call and then uses `context.mounted` on line 54 before each `setAlarm`. The top-level `getAlarms(context)` wrapper does **not** check `context.mounted` before invoking `di<AlarmManager>().getAlarms(context)` after the `Debouncer.runLazy(500)` delay. **Risk**: if the user navigates away in the 500ms debounce window, the AlarmManager call fires anyway, then the internal `if (context.mounted)` guards each subsequent `setAlarm` call. So the operation is **partially safe**; the outer call is not. See [tasks.md T-fix-1](tasks.md).
- **`ReloadHomeFetchDataEvent` with `silent: false`** during a refresh emits `HomeLoading()`, blanking the current screen. Pull-to-refresh callers pass `silent: false` (default) and rely on `RefreshIndicator` to surface the spinner — meaning the screen blanks briefly before the new data arrives. Less jarring than it sounds because the parent `RefreshIndicator` overlays the spinner. The cross-feature event-bus path also dispatches `silent: false` ([home_bloc.dart:24](../../lib/features/home/bloc/home_bloc.dart#L24)), so an `EventAdded` while the user is reading the home page **does** blank the screen — see [tasks.md T-fix-2](tasks.md).
- **Commented-out empty-state for events** at [home_screen.dart:176-179](../../lib/features/home/home_screen.dart#L176-L179) — intent was to show `no_events` empty state for parents. Currently the section is silently dropped when empty. Looks like an A/B decision left in code.
- **Commented-out `sections` field in HomeModel** ([home_model.dart:8](../../lib/features/home/models/home_model.dart#L8), [:21-22](../../lib/features/home/models/home_model.dart#L21-L22)) — sections come from `ConfigCubit.homeSections` (remote config), not from `parent/home` / `teacher/home`. The commented field suggests a previous design where sections came from the API. Either remove or wire up.
- **Nested `UserSelector` + `user = UserBloc.get.state.user`** at [home_screen.dart:98-104](../../lib/features/home/home_screen.dart#L98-L104) — the `UserSelector` selects `user`, then the builder fetches `UserBloc.get.state.user` directly (shadowing the captured `user`). The outer `user` is unused. Likely a refactor leftover; double-read is harmless but wasteful.
- **`print('HomeFetchDataEvent $homeModel')`** at [home_bloc.dart:52](../../lib/features/home/bloc/home_bloc.dart#L52) — debug noise. Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about 146 `print`/`debugPrint` calls.
- **Approval gate**: home is reached only post-gate from `MainScreen`. ✓

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch home data via `GET /parent/home` for parents and `GET /teacher/home` for teachers, selected at request time by `isCurrentUserProfessor` ([home_repo.dart:7](../../lib/features/home/data_source/home_repo.dart#L7)).
- **FR-002**: System MUST parse the response `data` envelope into `HomeModel(events: List<EventModel>, children: List<ChildModel>)`. The `childs` (sic — backend's snake-case-ish JSON) → `children` mapping happens in `HomeModel.fromJson`.
- **FR-003**: System MUST emit one of four `HomeState` types in the sealed hierarchy: `HomeInitial`, `HomeLoading`, `HomeError(Failure)`, `HomeFetchedSuccessfully(HomeModel)`.
- **FR-004**: System MUST react to `eventBus` events `EventAcceptedOrRejected` and `EventAdded` by re-fetching home data (silent fetch with completer omitted).
- **FR-005**: System MUST support pull-to-refresh via `RefreshIndicator` + a `Completer<void>` plumbed through `ReloadHomeFetchDataEvent.completer` so the spinner stays up until the bloc reports completion.
- **FR-006 (Parent)**: System MUST render the per-child cards row (`HomeCardsList`), the children's menus (`ChildrenMenus`), and the my-children horizontal list when the flavor is parents.
- **FR-007 (Parent)**: System MUST render the empty-state widget with `LocalizationKeys.no_children` when `homeModel.children` is empty.
- **FR-008 (Teacher)**: System MUST render the `home_sections` 2-column grid driven by `ConfigCubit.homeSections` when the flavor is professors and the list is non-empty.
- **FR-009 (Teacher)**: System MUST surface a search button in the app bar that navigates to [SearchScreen](../../lib/features/search/presentation/search_screen.dart).
- **FR-010**: System MUST render the Events horizontal list when `events.isNotEmpty`; suppress otherwise (no empty state today).
- **FR-011**: System MUST call `getAlarms(context)` on `initState` and on `AppLifecycleState.resumed`. The wrapper debounces by 500 ms and is a no-op for non-professor users.
- **FR-012**: System MUST display the user's name in the app bar greeting `LocalizationKeys.hello` + `\n` + `user.name` when name is non-empty; just `hello` otherwise.

### Localization Requirements

| Key | Use site |
|---|---|
| `hello` | app bar greeting |
| `events` | events section header |
| `my_children` | parents-only my-children section header |
| `no_children` | parents-only empty state |
| `sections` | teacher-only home_sections header |
| `no_events` | parents-only empty state — **referenced only by commented-out code** at [home_screen.dart:178](../../lib/features/home/home_screen.dart#L178) |

No new keys required by this migration.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET parent/home` — parents. Response: `{data: {events: EventModel[], childs: ChildModel[]}}`. Note `childs` (legacy spelling).
  - `GET teacher/home` — teachers. Same response shape.
- **No Firestore** use.
- **No FCM** direct use. FCM-driven refresh happens indirectly via the event bus (e.g., a notification handler firing `EventAdded` would trigger a home reload).
- **Remote config** ([ConfigCubit](../../lib/core/config/)):
  - `config.homeSections` — teacher-only sections grid items.
  - `config.styling` — colors, theming.

### Permissions & Approval Gate

- Home is reached only post-approval — entry from `MainScreen` which itself is post-gate.
- Device permissions:
  - **Notifications** — used indirectly via the medicine alarm system fired through `getAlarms`. Teacher-only.

### Key Entities

- **`HomeModel`** ([home_model.dart](../../lib/features/home/models/home_model.dart)) — `{events: List<EventModel>, children: List<ChildModel>}`. The commented `sections` field is unused.
- **`HomeBloc`** ([home_bloc.dart](../../lib/features/home/bloc/home_bloc.dart)) — `Bloc<HomeEvent, HomeState>` with `EventBlocListener` mixin for event-bus subscription.
- **`HomeEvent`** — sealed `{HomeFetchDataEvent, ReloadHomeFetchDataEvent(silent, completer?), HomeFetchedSuccessfullyEvent}`. The third variant is declared but **unused** in code — dead enum value.
- **`HomeState`** — sealed `{HomeInitial, HomeLoading, HomeFetchedSuccessfully(homeModel), HomeError(failure)}`.
- **`EventModel`** (shared, [core/models/event_model.dart](../../lib/core/models/event_model.dart)) — surfaced in the Events row.
- **`ChildModel`** (shared, [features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart)) — surfaced in my-children list and child cards.
- **`SectionModel`** ([home/models/section_model.dart](../../lib/features/home/models/section_model.dart)) — teacher-only section grid items. Driven by remote config, not the API.
- **`CardModel`** ([home/models/card_model.dart](../../lib/features/home/models/card_model.dart)) — parent-side child-summary cards. Driven by `HomeCardsList`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cold-start to interactive home: ≤ 2 s on a typical Android device (parents flavor, 3 children, 5 events, cached config).
- **SC-002**: Pull-to-refresh round-trip ≤ 1.5 s including network.
- **SC-003**: Switching flavors (re-installing the other flavor on the same device) renders the appropriate dashboard within the same cold-start budget — no shared UI state corruption.
- **SC-004**: An `EventAdded` event-bus signal during a foreground session triggers a re-fetch within 500 ms (debouncer-free; the listener fires synchronously). **Currently violated by UX**: the re-fetch passes `silent: false` and emits `HomeLoading()`, blanking the screen. See [tasks.md T-fix-2](tasks.md).
- **SC-005**: Background-to-foreground resume on a teacher device re-syncs the medicine alarms list within 500 ms (per-context debounce) without rebuilding the screen.

## Assumptions

- The backend's `parent/home` and `teacher/home` envelopes are stable — both return `data: {events, childs}`.
- `EventModel` and `ChildModel` are sourceable from the same JSON shapes the rest of the app expects; no home-specific overrides.
- `ConfigCubit.homeSections` is hydrated before the teacher dashboard renders (otherwise the sections grid is suppressed silently).
- `getAlarms`' internal `context.mounted` guards are sufficient for the lifecycle hooks — the outer wrapper's lack of a mounted check is acceptable risk for now (cancellation arrives via the `Debouncer` only if a new call is made).
- `HomeFetchedSuccessfullyEvent` is reserved future state-machine extension — safe to leave unused.
