---
status: migrated
feature: home
migrated_from: lib/features/home/
migrated_date: 2026-05-14
---

# Implementation Plan: Home

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/home/spec.md](spec.md) and code in [lib/features/home/](../../lib/features/home/) (16 .dart files).

## Summary

Home is the per-flavor dashboard rendered as the first tab of `MainScreen`. The bloc fans a single `HomeFetchDataEvent` out to the role-correct endpoint and emits a sealed state. The screen branches flavor-conditionally between a parent layout (child cards + menus + events + my-children) and a teacher layout (events + remote-config sections grid + search). The previously-tracked P0 constitution drift (`mainKey.currentContext` in the repo) is fixed; what remains is one post-await safety concern, a couple of code-hygiene items, and the [features.md](../features.md#home--b) UX backlog (active-child clarity, class summaries, pull-to-refresh — note pull-to-refresh is already implemented).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `HomeBloc` is a `Bloc<HomeEvent, HomeState>`
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart) — single `GET` endpoint per role
- `dartz` — `Either<Failure, HomeModel>`
- `equatable` 2.0 — used by both event and state sealed hierarchies
- `flutter_screenutil` 5.9 — 430×932 design size

**Storage**:

- `LocalDatabaseRepo` injected into `HomeBloc` but **not actively read** by the bloc — it's a constructor leftover.
- HydratedBloc not used.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Standard flavor-conditional dashboard. Composes shared components (`MyAppBar`, `EventItem`, `EmptyWidget`, `ErrorScreen`) and a remote-config grid driver.

**Performance Goals**:

- ≤ 2 s cold-start to interactive home (typical: 3 children, 5 events).
- 60 fps scroll across the long-form vertical content.

**Constraints**:

- The cross-feature reactive refresh from `eventBus` re-fetches with `silent: false`, blanking the screen briefly. UX-suboptimal but functional.
- `getAlarms(context)` is called from `initState` (synchronous) but the wrapper schedules an async `AlarmManager.getAlarms(context)` via a 500 ms `Debouncer`. The outer wrapper does not `if (!context.mounted) return;`.

**Scale/Scope**: 16 .dart files. 1 endpoint per role. 4 states. 3 events (1 unused).

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/home/` with `bloc/`, `data_source/`, `models/`, `widgets/`. ⚠️ Variant: `data_source/` (singular) instead of `data_sources/` (plural). Cosmetic; flagged for cleanup.
- [x] **II. Dependency Direction** — feature-root [home/data_source/home_di.dart](../../lib/features/home/data_source/home_di.dart) ✓ — registered through `init_dependencies.dart`. ⚠️ The DI file lives under `data_source/` rather than at the feature root (compare with [diary/diary_di.dart](../../lib/features/diary/diary_di.dart) at feature root). See [tasks.md T-cleanup-1](tasks.md).
- [x] **III. Networking Contract** — `HomeImpl.getHomeData()` goes through `NetworkClient.handleRequest` returning `Either<Failure, HomeModel>`. ✓
- [x] **IV. Persistence Discipline** — N/A (no Hive direct, no HydratedBloc). `LocalDatabaseRepo` injected but unused — could remove from constructor (T-cleanup-2).
- [x] **V. Flavor Branching** — ✓ `home_repo.dart:8` uses `isCurrentUserProfessor` (fixed 2026-05-14, replacing the previous `mainKey.currentContext` lookup per [features.md](../features.md#home--b)).
- [x] **VI. Localization** — every visible string routes through `LocalizationKeys.*.tr(context)`. ✓ One stray `print` at [home_bloc.dart:52](../../lib/features/home/bloc/home_bloc.dart#L52).
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reached only post-gate from `MainScreen`. ✓
- [x] **IX. Medicine Reminders** — partial: `getAlarms(context)` is invoked from the home lifecycle, then dispatches into `AlarmManager`. See [tasks.md T-fix-1](tasks.md).
- [x] **X. Theming & Sizing** — sizes use `.h`/`.w`/`.sp`/`.csh`/`.csw`; colors via `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/home/
├── spec.md              # User scenarios, requirements, success criteria
├── plan.md              # This file
└── tasks.md             # Migration tasks + gaps from features.md
```

### Source Code (existing)

```text
lib/features/home/
├── home_screen.dart                                # screen + lifecycle hooks
├── bloc/
│   ├── home_bloc.dart                              # Bloc<HomeEvent, HomeState> with EventBlocListener mixin
│   ├── home_event.dart                             # part-of — sealed hierarchy
│   └── home_state.dart                             # part-of — sealed hierarchy
├── data_source/                                    # ⚠️ singular; sibling features use 'data_sources/'
│   ├── home_repo.dart                              # abstract contract + endpoint resolver
│   ├── home_impl.dart                              # NetworkClient impl
│   └── home_di.dart                                # DependencyInjection — under data_source/, not feature root
├── models/
│   ├── home_model.dart                             # {events, children}; commented-out 'sections' field
│   ├── card_model.dart                             # parent-side child-summary card
│   └── section_model.dart                          # teacher-side homeSections grid item (driven by remote config)
└── widgets/
    ├── home_cards_list.dart                        # parents — child summary card list
    ├── home_card_item.dart                         # parents — single card
    ├── home_child_item.dart                        # parents — my-children list item; tap → DiaryScreen(child)
    ├── home_sections_item.dart                     # teachers — single home_section tile
    ├── children_menus.dart                         # parents — today's menu rendered via embedded DiaryBloc(GetMenus)
    └── event_item.dart                             # shared — events horizontal row card
```

### Cross-feature touch points

- [lib/core/user/current_role.dart](../../lib/core/user/current_role.dart) — `isCurrentUserProfessor` resolves the endpoint.
- [lib/core/event_bus.dart](../../lib/core/event_bus.dart) — `EventAcceptedOrRejected`, `EventAdded` fire reload.
- [lib/core/utils/alarm_manager/alarm_manager.dart](../../lib/core/utils/alarm_manager/alarm_manager.dart) — `getAlarms(context)` lifecycle hook (professor-only).
- [lib/features/diary/](../../lib/features/diary/) — `ChildModel`, `DiaryScreen` (navigation target), `DiaryBloc(GetMenus)` (embedded in `ChildrenMenus`).
- [lib/features/search/presentation/search_screen.dart](../../lib/features/search/presentation/search_screen.dart) — teacher search-icon destination.
- [lib/core/config/widgets/config_builder.dart](../../lib/core/config/widgets/config_builder.dart) — `ConfigSelector(selector: homeSections)` and `ConfigSelector(selector: styling)`.
- [lib/core/user/widgets/user_builder.dart](../../lib/core/user/widgets/user_builder.dart) — `UserSelector(selector: user)` for the app-bar greeting.

**Structure Decision**: Standard layout with a singular-vs-plural directory typo (`data_source/` vs `data_sources/`) and DI file placement under the data layer instead of feature root. Flagged in cleanup; not breaking.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| ~~`mainKey.currentContext?.isProfessors` in `home_repo.dart:8`~~ | ✅ **Resolved 2026-05-14** via the cross-feature `mainKey` sweep. Now uses `isCurrentUserProfessor`. | — |
| `getAlarms(context)` invoked from lifecycle hooks with no outer mounted check, but inner `context.mounted` guards in `AlarmManager.getAlarms` | The 500 ms `Debouncer.runLazy` window can outlast a navigation; the inner guards make most operations safe. | Add `if (!context.mounted) return;` immediately after the debouncer fires, before `di<AlarmManager>().getAlarms(context)` runs. See [tasks.md T-fix-1](tasks.md). |
| `ReloadHomeFetchDataEvent(silent: false)` from event-bus listener | Original implementation didn't distinguish between user-initiated and reactive refreshes. | The bloc listener should dispatch `silent: true` so the screen doesn't blank during a reactive refresh. See [tasks.md T-fix-2](tasks.md). |
| Unused `LocalDatabaseRepo` constructor parameter on `HomeBloc` | Possibly reserved for future local-cache work. | Remove from constructor + DI registration. Trivial cleanup. See [tasks.md T-cleanup-2](tasks.md). |
| Unused `HomeFetchedSuccessfullyEvent` sealed-event variant | Possibly reserved for future state-machine extension. | Remove. Or wire up. See [tasks.md T-cleanup-3](tasks.md). |
| Commented-out empty-state `else { EmptyWidget(no_events) }` at [home_screen.dart:176-179](../../lib/features/home/home_screen.dart#L176-L179) | A/B decision left in code. | Either restore or delete — the dangling comment misleads readers. See [tasks.md T-cleanup-4](tasks.md). |
| Commented-out `sections` field in `HomeModel` | Previous design had the API return sections; current design pulls from remote config. | Remove the field + the commented `validateDataList` + `'sections':` in `toJson`. See [tasks.md T-cleanup-5](tasks.md). |
| Shadowed `user` variable in app-bar builder ([home_screen.dart:98-104](../../lib/features/home/home_screen.dart#L98-L104)) | Refactor leftover — `UserSelector` provides one `user`, then a second `user = UserBloc.get.state.user` shadows it. | Drop the outer `UserSelector` (it's not adding anything since the body reads `UserBloc.get` directly) OR delete the inner re-read. See [tasks.md T-cleanup-6](tasks.md). |
| `print('HomeFetchDataEvent $homeModel')` at [home_bloc.dart:52](../../lib/features/home/bloc/home_bloc.dart#L52) | Development aid. | Drop. Part of cross-feature logger task. See [tasks.md T-cleanup-7](tasks.md). |
