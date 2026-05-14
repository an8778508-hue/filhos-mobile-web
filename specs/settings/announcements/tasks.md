---
status: migrated
feature: settings/announcements
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: Announcements

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/announcements/](../../../lib/features/settings/announcements/) with `bloc/`, `data_source/`, `widgets/`.
- [x] T002 Add localization keys (`announcements`, `no_announcements`).
- [x] T003 Register `AnnouncementsInjection().init()` at [di.dart:116](../../../lib/core/dependency_injection/di.dart#L116).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `AnnouncementsState` (`Initial / Loading / Error / FetchedSuccessfully`) and `AnnouncementsEvent` (`AnnouncementsFetchDataEvent`).
- [x] T011 Define abstract `AnnouncementsRepo` + concrete `AnnouncementsImpl`.
- [x] T012 Implement `getAnnouncements()` calling `GET /teacher/announcements` and parsing `AnnouncementsWithDateModel` list.

## Phase 3: User Story 1 — Browse announcements (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement [announcements_screen.dart](../../../lib/features/settings/announcements/announcements_screen.dart) with `BlocProvider(lazy: false)` + immediate fetch.
- [x] T021 [US1] Render announcements grouped by date with `DateFormat('EE dd MMM,yyyy')` headers.
- [x] T022 [US1] Implement `EmptyAnnouncements` widget with `no_announcements` localization.
- [x] T023 [US1] Wire `RefreshIndicator` to re-fire `AnnouncementsFetchDataEvent`.

---

## Phase 4: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P1)** Remove the hardcoded `await Future.delayed(const Duration(seconds: 1))` in [announcements_impl.dart:22](../../../lib/features/settings/announcements/data_source/announcements_impl.dart#L22). Every fetch is artificially slowed.

- [ ] **T-fix-2** **(P2)** Localize the date header. `DateFormat('EE dd MMM,yyyy')` renders English copy in a Portuguese-primary app. Pass the current locale: `DateFormat('EE dd MMM, yyyy', Localizations.localeOf(context).toString())`.

- [ ] **T-fix-3** **(P2)** Normalize folder casing. The on-disk folder is `announcements/` (lowercase) but multiple imports reference `package:escola/features/settings/Announcements/...` (Title-Case). Linux/macOS case-sensitive filesystems can break the build. Rename `Announcements_bloc.dart` → `announcements_bloc.dart` and fix all importers.

- [ ] **T-fix-4** **(P2)** *(from [features.md#settings--b](../../features.md#settings--b))* Add **toggle per-category subscriptions**. Today every push reaches every user. Likely a server schema change + a settings sub-screen.

- [ ] **T-fix-5** **(P2)** Replace the unformatted error rendering (`Text(state.failure.toString())` at [announcements_screen.dart:54](../../../lib/features/settings/announcements/announcements_screen.dart#L54)) with the shared `ErrorScreen` widget used in [events/event_screen.dart](../../../lib/features/settings/events/event_screen.dart).

### Code hygiene

- [ ] **T-cleanup-1** Remove the `rootBundle.loadString('assets/json/announcements.json')` call in [announcements_impl.dart:23](../../../lib/features/settings/announcements/data_source/announcements_impl.dart#L23) — the result is loaded into `data` but never used (the `testJson: data` parameter is commented out on the next call).
- [ ] **T-cleanup-2** Drop the `LocalDatabaseRepo` dependency from `AnnouncementsBloc` — injected but never read.
- [ ] **T-cleanup-3** Replace the catch-all `on<AnnouncementsEvent>` + internal `is` check with `on<AnnouncementsFetchDataEvent>`.
- [ ] **T-cleanup-4** Delete the unused `_basicErrorHandling` extension at the bottom of [announcements_impl.dart](../../../lib/features/settings/announcements/data_source/announcements_impl.dart).
- [ ] **T-cleanup-5** Remove `print('announcement ...')` debug calls in `announcements_impl.dart` and `Announcements_bloc.dart`. Part of the repo-wide logger task.
- [ ] **T-cleanup-6** Delete commented-out add-button block in [announcements_screen.dart:35-43](../../../lib/features/settings/announcements/announcements_screen.dart#L35-L43).

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test: success path renders `AnnouncementsFetchedSuccessfully`.
- [ ] **T-test-2** [P] [US1] Widget test: empty list shows `EmptyAnnouncements`.

---

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze`.
- [ ] **TX02** Cold-start the app from a push deep-link and verify the screen renders without errors.

---

## Gaps Found

- **Artificial 1s delay** on every fetch.
- **Date header not localized.**
- **Per-category subscription toggling missing** (features.md P2).
- **Folder casing drift** — works on Windows / macOS-default but fails on case-sensitive filesystems.
- **`LocalDatabaseRepo` dead dependency.**
- **Error rendering is unstyled `Text`.**

## Notes

- The screen is **not reachable from the settings shell** today — only Home tiles and push deep-links. The folder lives under `settings/` for historical reasons.
- Both flavors hit `/teacher/announcements` — confirm with backend that this is correct for parents too.
