---
status: migrated
feature: settings/announcements
migrated_from: lib/features/settings/announcements/
migrated_date: 2026-05-14
---

# Implementation Plan: Announcements

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/announcements/spec.md](spec.md) and code in [lib/features/settings/announcements/](../../../lib/features/settings/announcements/).

## Summary

Simple list screen showing dated announcements from the school. Lives under `settings/` for historical reasons but is not reached from the settings shell — instead via Home tiles and push deep-links. The repo/impl split mirrors the `events/` sub-feature's pattern (`Repo` abstract + `Impl` concrete + `Injection` class).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0`.

**Primary Dependencies**:

- `flutter_bloc` — `AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState>`.
- `dartz` — `Either<Failure, List<AnnouncementsWithDateModel>>`.
- `intl` — `DateFormat('EE dd MMM,yyyy')` for date section headers.
- `flutter_screenutil` — sizing.
- `get_it` — `di<AnnouncementsBloc>` factory via `AnnouncementsInjection`.

**Storage**: none.

**Testing**: none.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature with abstract repo + concrete impl + DI injection class.

**Performance Goals**: List interactive within 1-2s (once the artificial 1s delay in `AnnouncementsImpl` is removed).

**Constraints**: pushes via FCM deep-link to this screen — the screen must work when pushed cold-start.

**Scale/Scope**: 8 files, ~250 LOC.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/`, `data_source/`, `widgets/`, screen at root, plus a feature-scoped `AnnouncementsInjection`. ⚠️ Folder is lowercase `announcements/` on disk; some imports use PascalCase `Announcements/` which is filesystem-case-dependent.
- [x] **II. Dependency Direction** — imports `lib/core/*` (announcements model + local db). ✓
- [x] **III. Networking Contract** — `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — `LocalDatabaseRepo` is injected into the bloc but **never used**. Dead dependency.
- [x] **V. Flavor Branching** — none observed (same code path both flavors).
- [x] **VI. Localization** — `announcements`, `no_announcements`. Date header copy is hardcoded `EE dd MMM,yyyy`. ⚠️ Not locale-aware.
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit (downstream of Home / push deep-link).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h/.w/.csw/.csh/.sp` + `context.colors.*`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/settings/announcements/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/settings/announcements/
├── announcements_screen.dart                       # list + empty state
├── bloc/
│   ├── Announcements_bloc.dart                     # ⚠️ filename Title-Case
│   ├── announcements_event.dart
│   └── announcements_state.dart
├── data_source/
│   ├── announcements_di.dart                       # AnnouncementsInjection
│   ├── announcements_impl.dart                     # concrete; uses test JSON path (disabled)
│   └── announcements_repo.dart                     # abstract contract
└── widgets/
    ├── announcements_container_widget.dart
    └── announcements_item.dart
```

### Cross-feature touch points

- [lib/core/models/announcements_with_date_model.dart](../../../lib/core/models/announcements_with_date_model.dart) — shared model.
- [lib/core/local_db/local_db_repo.dart](../../../lib/core/local_db/local_db_repo.dart) — injected but unused.
- [lib/features/home/widgets/home_sections_item.dart:38](../../../lib/features/home/widgets/home_sections_item.dart#L38) — Home tile route in.
- [lib/core/notifications_service/notification_helper.dart](../../../lib/core/notifications_service/notification_helper.dart) — push deep-link target.

**Structure Decision**: matches the `events/` sub-feature's pattern (abstract Repo + Impl + Injection).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Filename `Announcements_bloc.dart` (Title-Case) + import paths varying between `Announcements/` and `announcements/` | Historical drift. | Rename file + normalize imports. Touches all importers. **See tasks.md T-fix-3.** |
| Hardcoded `Future.delayed(Duration(seconds: 1))` before the network call | Looks like a leftover skeleton-loader probe. | Delete. **See tasks.md T-fix-1.** |
| Asset JSON load on every fetch ([announcements_impl.dart:23](../../../lib/features/settings/announcements/data_source/announcements_impl.dart#L23)) | Was used for `testJson` fallback before that param was commented. | Delete unused read. **See tasks.md T-cleanup-1.** |
| `LocalDatabaseRepo` injected but never used | Boilerplate from sibling features. | Drop the constructor parameter. **See tasks.md T-cleanup-2.** |
| Catch-all `on<AnnouncementsEvent>` with internal `is` check | Pattern used in some other features. | Use typed `on<AnnouncementsFetchDataEvent>`. **See tasks.md T-cleanup-3.** |
| `_basicErrorHandling` extension never called | Dead. | Delete. **See tasks.md T-cleanup-4.** |
