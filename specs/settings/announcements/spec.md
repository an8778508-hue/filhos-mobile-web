---
status: migrated
feature: settings/announcements
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: Announcements

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/announcements/](../../../lib/features/settings/announcements/) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both. The screen has no flavor branching internally; it lives under `settings/` but **is not navigated to from the settings shell today** — the row is commented out at [settings_screen.dart:179-190](../../../lib/features/settings/settings_screen.dart#L179-L190). Reached from:
  - **Home** ([home_sections_item.dart:38](../../../lib/features/home/widgets/home_sections_item.dart#L38)) when an announcements section tile is tapped.
  - Push-notification deep-links (announcements push channel).
- **Flavor-conditional behavior**: none observed in the screen / bloc / repo. Both flavors hit the same endpoint, see the same UI.
- **Server role implication**: hits `/teacher/announcements` regardless of flavor ([announcements_repo.dart:6](../../../lib/features/settings/announcements/data_source/announcements_repo.dart#L6)). The path is named after the teacher API but evidently returns the right data for parents too. **[NEEDS CLARIFICATION]** is `/teacher/announcements` truly the right endpoint for parents, or is the URL misleading?

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse announcements (Priority: P1) 🎯 MVP

A user opens the Announcements screen (from Home or a push deep-link) and sees a list of announcements grouped by date.

**Why this priority**: Announcements are how the school broadcasts critical info (closures, schedule changes, events). Required for both flavors.

**Independent Test**:
1. From Home, tap an announcements tile → `AnnouncementsScreen` opens.
2. `AnnouncementsFetchDataEvent` fires → `AnnouncementsLoading` → `AnnouncementsFetchedSuccessfully(announcements)`.
3. Each announcement renders inside a per-date section with `EE dd MMM,yyyy` header (e.g. "Mon 12 May, 2026").
4. Pull-to-refresh re-fires the fetch.

**Acceptance Scenarios**:

1. **Given** a user opens the screen, **When** the BlocProvider is created with `lazy: false`, **Then** `AnnouncementsFetchDataEvent` is dispatched immediately.
2. **Given** the API returns a list, **When** `AnnouncementsFetchedSuccessfully(announcements)` emits, **Then** announcements are rendered grouped by `AnnouncementsWithDateModel.date` with the date header.
3. **Given** an empty list, **When** the response is `[]`, **Then** `EmptyAnnouncements` renders with the announcements icon + `no_announcements` localization.
4. **Given** an error, **When** `AnnouncementsError(failure)` emits, **Then** a centered `Text` shows `state.failure.toString()`. *(Plain text — no styled error widget.)*
5. **Given** the user pulls to refresh, **When** `RefreshIndicator.onRefresh` fires, **Then** `AnnouncementsFetchDataEvent` is dispatched again.

### Edge Cases

- **`/teacher/announcements` endpoint name** — used by both flavors. Likely a backend convention; not a bug per se.
- **Bundled `assets/json/announcements.json`** is loaded inside `AnnouncementsImpl.getAnnouncements` ([announcements_impl.dart:21-23](../../../lib/features/settings/announcements/data_source/announcements_impl.dart#L21-L23)) and then **discarded** — the file is loaded for testJson fallback but the `testJson` parameter is commented out. Dead I/O on every fetch.
- **Hardcoded 1-second `Future.delayed`** before the API call ([announcements_impl.dart:22](../../../lib/features/settings/announcements/data_source/announcements_impl.dart#L22)) — slows every fetch artificially. Bug — see [tasks.md T-fix-1](tasks.md).
- **Error rendering is unformatted** — `state.failure.toString()` is shown as-is.
- **Catch-all `on<AnnouncementsEvent>`** with an inner `if (event is AnnouncementsFetchDataEvent)` ([Announcements_bloc.dart:16](../../../lib/features/settings/announcements/bloc/Announcements_bloc.dart#L16)) — discouraged pattern; should use typed `on<AnnouncementsFetchDataEvent>`.
- **No "toggle per-category subscriptions"** — flagged in [features.md#settings--b](../../features.md#settings--b) as a feature gap.
- **No pagination** — the screen fetches once, no `?page=` query.
- **Folder casing inconsistency**: imports mix `'Announcements/'` (PascalCase) and `'announcements/'` (lowercase). The actual folder on disk is `announcements/` (lowercase per Glob). Case-sensitive filesystems (Linux CI) may break — see [tasks.md T-fix-3](tasks.md).
- **Approval gate**: implicit (downstream of Home / push).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch announcements via `GET /teacher/announcements` and decode them as `AnnouncementsWithDateModel` objects.
- **FR-002**: System MUST render announcements grouped by their `date` field with a localized `EE dd MMM,yyyy` header.
- **FR-003**: System MUST surface a "no announcements" empty state with the announcements icon when the list is empty.
- **FR-004**: System MUST allow pull-to-refresh to re-fetch.
- **FR-005**: System MUST render an error message when the repo returns `Left(Failure)`.

### Localization Requirements

| Key | Use site |
|---|---|
| `announcements` | app bar title |
| `no_announcements` | empty state |

`DateFormat('EE dd MMM,yyyy')` is **not** localized — see [tasks.md T-fix-2](tasks.md).

### Backend Touchpoints

- **REST endpoints**:
  - `GET /teacher/announcements` — list of announcements grouped by date. Response: `{data: [AnnouncementsWithDateModel]}`.
- **Headers**: standard.
- **Firebase**: not used by this screen, but announcements push notifications arrive via FCM and deep-link to this screen.
- **Firestore**: not used.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit).
- Push notification permission required to receive announcement pushes (configured in `lib/core/notifications_service/`).

### Key Entities

- **`AnnouncementsWithDateModel`** ([lib/core/models/announcements_with_date_model.dart](../../../lib/core/models/announcements_with_date_model.dart)) — `{date, List<Announcement>}` — shared core model.
- **`AnnouncementsRepo`** (abstract) + **`AnnouncementsImpl`** — repo split is unusual for the codebase (most features use a single concrete repo class).
- **`AnnouncementsBloc`** — `Bloc<AnnouncementsEvent, AnnouncementsState>` with `Initial / Loading / Error / FetchedSuccessfully` states.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Announcement list visible within 1 round-trip after open (~1-2s on a typical mobile network) **once the artificial 1s delay is removed (T-fix-1)**.
- **SC-002**: Pull-to-refresh consistently re-renders the latest server state.
- **SC-003**: Empty state renders correctly when zero announcements exist.

## Assumptions

- `/teacher/announcements` returns the right data for both flavors — confirm with backend.
- `AnnouncementsWithDateModel.date` is a parsed `DateTime`, not a string.
- Push deep-link to announcements lands on this screen via `WidgetFunctions.navigateTo(ctx, const AnnouncementsScreen())` from `notification_helper.dart`.
- Date header copy "EE dd MMM,yyyy" is acceptable across locales (English headers in a Portuguese app — known gap).
