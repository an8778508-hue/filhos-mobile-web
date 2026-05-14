---
status: migrated
feature: featured_events
flavor_scope: both
migrated_from: specs/features.md#featured_events--b
migrated_date: 2026-05-14
---

# Feature Specification: Featured Events

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/featured_events/](../../lib/features/featured_events/) and the [features.md `## featured_events · B`](../features.md#featured_events--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores).
- **Flavor-conditional behavior**: none observed in this feature. Both flavors fetch the featured events list from the same `events` REST endpoint, with the `getEventsEndpoint` resolver internally branching on `isCurrentUserProfessor` ([events_repo.dart:11-12](../../lib/features/settings/events/data_source/events_repo.dart#L11-L12)). The backend currently returns the same path for both roles (`"events"`).
- **Server role implication**: the `is_feature=1` query parameter ([events_impl.dart:26](../../lib/features/settings/events/data_source/events_impl.dart#L26)) selects featured events server-side; the server itself filters by token role.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See featured events on first reach of Main (Priority: P1) 🎯 MVP

When the user lands on the `MainScreen` shell, the app silently fetches featured (school-highlighted) events. If any have not yet been "seen" by the user on this device, a full-screen `Dialog` opens carrying the event(s) in a paged carousel.

**Why this priority**: Featured events are the school's primary push-style surface for time-sensitive announcements (school trips, parents' meetings, celebrations). If the carousel never opens, the school's primary callout channel is silent.

**Independent Test**:
1. Log in on a device with no `seen_featured_events` Hive entry.
2. Reach `MainScreen` (the bottom-nav shell).
3. Observe `FeaturedEventsBloc.fetch()` runs once via [main_screen.dart:38](../../lib/features/main/presentation/main_screen.dart#L38), the dialog appears with the first event, and the page indicator reflects total count.

**Acceptance Scenarios**:

1. **Given** a fresh install with zero seen IDs, **When** `MainScreen.initState` runs, **Then** `FeaturedEventsBloc.fetch()` calls `eventsRepo.getProfessorEvents(null, featured: true)` and `FeaturedEventsScreen.open(context)` is triggered by the `BlocListener` once the data list is non-empty ([main_screen.dart:50-56](../../lib/features/main/presentation/main_screen.dart#L50-L56)).
2. **Given** the user taps "skip" or "details" on an event, **When** `FeaturedEventsBloc.cache(id)` runs, **Then** the event's `id` is appended to the in-memory `seenIds` list **and** persisted to Hive under [LocalKeys.seenFeaturedEvents](../../lib/core/local_db/local_db_repo.dart#L55) (`"seen_featured_events"`).
3. **Given** all featured events have been seen, **When** `fetch()` filters the response, **Then** the result list is empty and the dialog does not open ([featured_events_bloc.dart:22](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L22)).
4. **Given** the user is on the last page of the carousel, **When** they tap "remind later" or finish "details", **Then** `nextPage()` calls `Navigator.of(context).pop()` to dismiss the dialog ([featured_events_screen.dart:99](../../lib/features/featured_events/featured_events_screen.dart#L99)).
5. **Given** the data list becomes empty after a refresh, **When** the `BlocListener` reacts to the state change, **Then** any open dialog is popped automatically ([main_screen.dart:58-62](../../lib/features/main/presentation/main_screen.dart#L58-L62)).

---

### User Story 2 - Navigate to event details from the carousel (Priority: P2)

A user taps the **Details** CTA on a featured event card and is taken to `AcceptEventScreen` to RSVP / read the full description.

**Why this priority**: The carousel is awareness; the RSVP / details screen is the action. Without the bridge, the surface is dead-ended.

**Independent Test**:
1. With at least one featured event loaded, tap **Details**.
2. Confirm: the event id is cached as seen, `AcceptEventScreen(eventId: currentId!)` pushes, and on return the carousel advances to the next event.

**Acceptance Scenarios**:

1. **Given** a non-null `currentId`, **When** the user taps **Details**, **Then** the bloc caches the id, the navigator pushes [AcceptEventScreen](../../lib/features/settings/accept_event/accept_events.dart), and on pop `nextPage()` is invoked ([featured_events_screen.dart:287-300](../../lib/features/featured_events/featured_events_screen.dart#L287-L300)).
2. **Given** an event has a non-empty `imageUrl`, **When** the user taps the image area, **Then** `PhotoViewer` opens full-screen with `photo_view` zoom ([featured_events_screen.dart:138-140](../../lib/features/featured_events/featured_events_screen.dart#L138-L140)).

---

### Edge Cases

- **Dialog re-entrancy**: `featuredDialogOpened` flag in `MainScreen` is the only guard against double-open. If `MainScreen` is rebuilt without disposing, this flag persists in the State object — acceptable.
- **Empty image URL**: the new screen layout (`featured_events_screen.dart`) displays a centered `default_logo` asset with `BoxFit.contain` when `imageUrl` is empty ([featured_events_screen.dart:147-153](../../lib/features/featured_events/featured_events_screen.dart#L147-L153)); the legacy `featured_events_screen_old.dart` simply hides the image block (`if (validString(item.imageUrl))`).
- **Single-event carousel**: when `data.length == 1`, the `DotsIndicator` is hidden ([featured_events_screen.dart:268](../../lib/features/featured_events/featured_events_screen.dart#L268)).
- **Cache miss after fresh install**: `LocalDatabaseRepo.read` returns `null` → defaults to empty `<String>[]` ([featured_events_bloc.dart:31](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L31)).
- **No expiry on seen IDs**: a featured event's id stays in Hive forever; if the school re-uses the same id for a new featured cycle, that event will be silently filtered. Not currently in scope — see [features.md `featured_events`](../features.md#featured_events--b).
- **Legacy screen file**: [featured_events_screen_old.dart](../../lib/features/featured_events/featured_events_screen_old.dart) is still present in the tree but unreferenced (cleanup task — see [tasks.md](tasks.md)).
- **Empty / error states**: the dialog only opens when the result list is non-empty. There is no in-carousel error state; on failure the dialog stays closed and nothing is surfaced to the user. Gap — see [features.md `featured_events` (B) "Add empty/error states"](../features.md#featured_events--b).
- **Stray `print` at [featured_events_screen.dart:130](../../lib/features/featured_events/featured_events_screen.dart#L130)** — image URL leaks into device logs. Cleanup.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch featured events on `MainScreen.initState` via `eventsRepo.getProfessorEvents(null, featured: true)`.
- **FR-002**: System MUST send `is_feature=1` as a query parameter on the `GET events` request to select the featured subset.
- **FR-003**: System MUST persist the IDs of events the user has acknowledged (via skip, details, or remind-later flows) into Hive under key `seen_featured_events` through [LocalDatabaseRepo](../../lib/core/local_db/local_db_repo.dart).
- **FR-004**: System MUST filter the server response by removing any event whose `id` is already in the persisted seen-IDs list **before** rendering the dialog ([featured_events_bloc.dart:21-22](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L21-L22)).
- **FR-005**: System MUST open `FeaturedEventsScreen` as a non-dismissible `Dialog` (`barrierDismissible: false`, `WillPopScope` returning `false`) so the user cannot back-out without an explicit action.
- **FR-006**: System MUST guard against re-opening the dialog while it is already on screen via the `featuredDialogOpened` flag in `MainScreen`.
- **FR-007**: System MUST close the dialog automatically when the filtered result list becomes empty.
- **FR-008**: System MUST allow the user to: (a) "remind later" → advance without caching, (b) "skip" → cache id and advance, (c) tap "details" → cache id, push `AcceptEventScreen`, on return advance.
- **FR-009**: System MUST render the event image full-screen via `PhotoViewer` (pinch-zoom) on tap.
- **FR-010**: System MUST swallow repository failures silently — no error surface today (see Gaps).

### Localization Requirements

| Key | Use site |
|---|---|
| `remind_later` | Top-left dismiss CTA on each card |
| `skip` | Top-right cache+advance CTA |
| `details` | Primary CTA → `AcceptEventScreen` |
| `from`, `to` | Date range labels (legacy screen only) |

All keys exist in `assets/langs/{en,pt}.json`; `ar.json` coverage is part of the [cross-feature i18n task](../features.md#cross-feature-tasks).

### Backend Touchpoints

- **REST**: `GET events?is_feature=1` via [NetworkClient.handleRequest](../../lib/core/network/network_client.dart). Response is the standard `{data: [EventGenericModel...]}` envelope. The response is flattened from `List<EventGenericModel>` into `List<EventModel>` by `events.fold((p,c) => [...p, ...c.events])` ([featured_events_bloc.dart:21](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L21)).
- No Firestore, FCM, or Firebase Storage usage.

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **Effectively yes** — `MainScreen` (the only mount point) is the post-approval shell. Pending users hit `YourAccountUnderReviewScreen` instead and never see the carousel.
- No device permissions.

### Key Entities

- **`FeaturedEventsState`** ([state](../../lib/features/featured_events/bloc/featured_events_state.dart)) — wraps a `GenericListState<EventModel>` for loading / data / error transitions.
- **`EventModel`** (shared [core/models/event_model.dart](../../lib/core/models/event_model.dart)) — id, title, description, imageUrl, startDate, endDate.
- **`EventGenericModel`** (shared) — a date-grouped wrapper containing `List<EventModel> events`. The backend returns groups; this feature flattens them.
- **Hive key** `seen_featured_events` — `List<String>` of event IDs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user who has not yet seen a given featured event sees the carousel within 2 seconds of reaching `MainScreen` on a typical 4G connection.
- **SC-002**: A user who skips, details, or remind-laters every featured event does **not** see the dialog reopen on subsequent app cold-starts (until the server returns new unseen events).
- **SC-003**: With zero unseen featured events, `MainScreen` mounts without showing the carousel and without flicker.
- **SC-004**: Tapping **Details** lands on `AcceptEventScreen` with the correct `eventId` and, on return, the carousel either advances to the next unseen event or closes.

## Assumptions

- The backend returns event ids as `String` (matched against the persisted `List<String>` seen-IDs). If the server ever returns numeric ids, the equality at [featured_events_bloc.dart:22](../../lib/features/featured_events/bloc/featured_events_bloc.dart#L22) would still hold via `==` on `String`/`String`, but a type drift would silently break dedupe.
- The school controls which events are flagged `is_feature` server-side; the client has no role in choosing what to surface.
- Featured event IDs are stable for the lifetime of a single "featured cycle" (i.e., the server does not recycle ids).
- The user reaches `MainScreen` shortly after login / cold-start in normal usage; deferred mounts (e.g., approval gate → main after admin approval) still fire `initState` and therefore still surface the carousel.
