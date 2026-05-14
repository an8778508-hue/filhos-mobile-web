---
status: migrated
feature: featured_events
migrated_from: lib/features/featured_events/
migrated_date: 2026-05-14
---

# Implementation Plan: Featured Events

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/featured_events/spec.md](spec.md) and code in [lib/features/featured_events/](../../lib/features/featured_events/).

## Summary

Featured Events is a small carousel surface that opens once on `MainScreen` mount when the server has flagged events as featured (`is_feature=1`) and the user has not yet seen them on this device. Dedupe is local-only via a `List<String>` stored in Hive under [LocalKeys.seenFeaturedEvents](../../lib/core/local_db/local_db_repo.dart#L55). The feature reuses [EventsRepo](../../lib/features/settings/events/data_source/events_repo.dart) from the settings/events sub-tree, [PhotoViewer](../../lib/core/components/image/photo_viewer.dart) for image zoom, and pushes navigation to [AcceptEventScreen](../../lib/features/settings/accept_event/accept_events.dart).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `FeaturedEventsBloc` is a `Cubit<FeaturedEventsState>`.
- `get_it` — registered in [lib/core/dependency_injection/di.dart:125](../../lib/core/dependency_injection/di.dart#L125): `di.registerFactory(() => FeaturedEventsBloc(di()));`. **Note**: no per-feature `featured_events_di.dart` exists — registration lives in `core/dependency_injection/di.dart` alongside `TermsRepo`/`TermsBloc`/`GalleryRepo`. Minor constitution drift — see [tasks.md](tasks.md).
- `dots_indicator` — page indicator at the bottom of the carousel.
- `photo_view` — through `PhotoViewer`.
- `hive` (via `LocalDatabaseRepo`) — `seen_featured_events` list.
- `flutter_screenutil` — `.h/.w/.sp/.r/.csh/.csw` everywhere.

**Storage**:

- Hive (via [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart)): `seen_featured_events` → `List<String>`.

**Testing**: None today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; non-standard layout — the bloc directory lives at the **feature root** (`featured_events/bloc/`) and the screen file is **also** at the feature root, with no `presentation/` wrapper. This matches the closest siblings (`gallery_images/`, `background_services/`) rather than the canonical `presentation/{bloc,widgets}` layout used by `login/`.

**Performance Goals**: Dialog open within 2 s of `MainScreen.initState` on 4G; subsequent page transitions are 250 ms `Curves.easeInOut`.

**Constraints**:

- Must not block `MainScreen.initState` — the fetch is fire-and-forget async; the dialog opens reactively via `BlocListener`.
- Must dedupe locally; the server returns the same featured list to all devices.
- Must not present an error UI today (silent on failure) — this is a gap, not a deliberate design choice.

**Scale/Scope**: 4 .dart files. The legacy `featured_events_screen_old.dart` is unreferenced and is a cleanup candidate.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code under `lib/features/featured_events/`. ⚠️ No `presentation/` subfolder (bloc + screen at feature root). Matches siblings `gallery_images/`, `background_services/`; treat as accepted variation. ⚠️ No `featured_events_di.dart`; DI registration lives in `core/dependency_injection/di.dart`.
- [x] **II. Dependency Direction** — imports only `core/*` and `features/settings/events/` (EventsRepo), `features/settings/accept_event/` (navigation target). Two cross-feature imports are acceptable per current code (navigation target + reused repo).
- [x] **III. Networking Contract** — calls flow through `NetworkClient.handleRequest` via `EventsImpl` returning `Either<Failure, List<EventGenericModel>>`. ✓
- [x] **IV. Persistence Discipline** — Hive access goes through `LocalDatabaseRepo`. ✓
- [x] **V. Flavor Branching** — no `mainKey.currentContext` use here. Server-side endpoint resolution uses `isCurrentUserProfessor` in [events_repo.dart:11-12](../../lib/features/settings/events/data_source/events_repo.dart#L11-L12). ✓
- [x] **VI. Localization** — all CTAs use `LocalizationKeys.*.tr(context)`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — N/A directly; mounted only inside `MainScreen` which is past the gate.
- [x] **IX. Medicine Reminders** — N/A.
- [⚠] **X. Theming & Sizing** — sizes use `.h/.w/.sp/.r/.csh/.csw`. Colors mostly via `context.colors.*` but a few `Colors.black12`, `Colors.black38` hardcodes at [featured_events_screen.dart:158, 170](../../lib/features/featured_events/featured_events_screen.dart#L158-L170). Tracked in cross-feature [hardcoded colors](../features.md#cross-feature-tasks) sweep.

## Project Structure

### Documentation (this feature)

```text
specs/featured_events/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/featured_events/
├── bloc/
│   ├── featured_events_bloc.dart           # Cubit<FeaturedEventsState>; fetch / cache / getCache
│   └── featured_events_state.dart          # GenericListState<EventModel> wrapper
├── featured_events_screen.dart             # Dialog + PageView carousel (active)
└── featured_events_screen_old.dart         # ⚠️ Unreferenced legacy variant (dead code)
```

### Cross-feature touch points

- [lib/features/main/presentation/main_screen.dart](../../lib/features/main/presentation/main_screen.dart) — sole mount/trigger site.
- [lib/features/settings/events/data_source/events_repo.dart](../../lib/features/settings/events/data_source/events_repo.dart) — REST contract reused.
- [lib/features/settings/accept_event/accept_events.dart](../../lib/features/settings/accept_event/accept_events.dart) — Details navigation target.
- [lib/core/components/image/photo_viewer.dart](../../lib/core/components/image/photo_viewer.dart) — full-screen zoom.
- [lib/core/local_db/local_db_repo.dart](../../lib/core/local_db/local_db_repo.dart) — seen-IDs persistence.

**Structure Decision**: Keep the feature-root bloc/screen layout (matches siblings). Move DI registration into a dedicated `featured_events_di.dart` as cleanup. Delete the `_old.dart` file.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| DI registration in `core/dependency_injection/di.dart` instead of a per-feature `featured_events_di.dart` | Historical — the feature was added inline alongside `TermsRepo`/`GalleryRepo` registrations. | Move to `featured_events_di.dart` as cleanup; mechanical change. |
| Two screen variants (`featured_events_screen.dart` + `_old.dart`) | The legacy variant retained while the new card-style was iterated on. | Delete `_old.dart`; no imports reference it. |
| In-memory `seenIds` list **and** Hive list are kept in lockstep manually | Avoids a Hive round-trip on every cache write. | Could read from Hive every time, but the dialog is short-lived and the list small (dozens at most). |
| Server returns `EventGenericModel` (date-grouped) but the carousel only needs flat events | Reuses the existing list endpoint instead of adding a dedicated `/featured` shape. | Add a server-side flat endpoint — coordinate with backend; not blocking. |
