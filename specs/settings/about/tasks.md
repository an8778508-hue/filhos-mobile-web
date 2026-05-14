---
status: migrated
feature: settings/about
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: About

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#settings--b](../../features.md#settings--b).

**Tests**: No `test/` directory exists.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/about/](../../../lib/features/settings/about/) with `bloc/`, `repo/`, `models/`, screen at root.
- [x] T002 Add localization keys (`about`, `about_filhos_title`, `about_filhos_description`, `contact_us`, `email`, `phone`, `share`, `rate`, `your_app_version_is_up_to_date`).
- [x] T003 Register `AboutRepo` + `AboutBloc` in [di.dart:72, 105](../../../lib/core/dependency_injection/di.dart#L72).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define `AboutModel` (`content`, `email`, `phone`).
- [x] T011 Define `AboutEvents` (`FetchAbout`) + `AboutStates` wrapper + `AboutState` (data/version/loading/canUpdate/error).
- [x] T012 Implement `AboutRepo.getAbout()` calling `GET schools/{schoolId}/pages/about`.

## Phase 3: User Story 1 — Version + brand + contact + share + rate (P1) 🎯 MVP — ✅ Complete (with one open gap)

- [x] T020 [US1] Implement `AboutBloc.FetchAbout` reading `PackageInfo.fromPlatform()` + `AppVersionChecker.checkUpdate()`.
- [x] T021 [US1] Implement [about_screen.dart](../../../lib/features/settings/about/about_screen.dart) with logo, version, up-to-date badge, about copy, contact block (gated by `validString(email/phone)`), Share + Rate buttons.
- [x] T022 [US1] Wire Share button to `Config.get.appInfo.iosUrl` / `androidUrl` based on `Platform`.
- [x] T023 [US1] Wire Rate button to platform-specific store URLs (`market://` / `apps.apple.com/...`).
- [x] T024 [US1] Wire logo tap to `launchUrl(Config.appUrl)` (try/catch for failure).
- [x] T025 [US1] Anchor `PoweredByWidget` at the bottom of the safe area.

---

## Phase 4: Gaps & cleanups

### Bugs / open from features.md

- [ ] **T-fix-1** **(P1)** *(from [features.md#settings--b](../../features.md#settings--b))* Re-enable the `getAbout()` REST call in [about_bloc.dart:32-38](../../../lib/features/settings/about/bloc/about_bloc.dart#L32-L38) so contact email / phone actually render. Today the rows are gated by `validString(about?.email)` but `about` is always null because the network branch is commented out.

- [x] **(P0 closed?)** *(from [features.md#settings--b](../../features.md#settings--b))* `about`: show app version (`package_info_plus`), contact, terms, privacy. Version is implemented; terms/privacy live as separate Settings rows; contact pending T-fix-1. Marking the item itself as no longer fully open — split into T-fix-1.

### Constitution drift fixes

- [ ] **T-fix-2** **(P2)** `AboutState.copyWith` returns `dynamic` ([about_states.dart:37-52](../../../lib/features/settings/about/bloc/about_states.dart#L37-L52)). Type the return as `AboutState` so callers get static checking.

### Code hygiene

- [ ] **T-cleanup-1** Replace `print('AboutBloc.AboutBloc Exception $e')` ([about_bloc.dart:29](../../../lib/features/settings/about/bloc/about_bloc.dart#L29)) and `print('_AboutScreenState.build error: $e')` ([about_screen.dart:326](../../../lib/features/settings/about/about_screen.dart#L326)) with a real logger (repo-wide task).
- [ ] **T-cleanup-2** Remove the dead `SubmitAboutEvent` event in [about_events.dart:12](../../../lib/features/settings/about/bloc/about_events.dart#L12) — never dispatched.
- [ ] **T-cleanup-3** Decide on the `AboutBloc.myAboutRepo` field name — singular `aboutRepo` would be cleaner; current name reads oddly.

### Tests (aspirational)

- [ ] **T-test-1** [P] Bloc test: `FetchAbout` populates `version` from a fake `PackageInfo`.
- [ ] **T-test-2** [P] Widget test: `canUpdate == false` renders the "up to date" string.
- [ ] **T-test-3** [P] Widget test: Share button on iOS shares `iosUrl`; on Android shares `androidUrl`.

---

## Phase 5: Polish & Cross-Cutting

- [ ] **TX01** Run `flutter analyze`.
- [ ] **TX02** Manual test on both flavors: verify the right logo asset loads + the right store URL opens.

---

## Gaps Found

- **Contact info never renders** — `getAbout()` REST call commented out.
- **`copyWith` is untyped** — type-safety regression risk.
- **`SubmitAboutEvent`** dead event.
- **Two `print` statements** in the feature.

## Notes

- This is one of the simpler sub-features; most logic is asset / URL launching.
- Terms / privacy / change-language are separate Settings rows, not part of About.
- `AppVersionChecker` is a small package; failures are tolerated silently.
