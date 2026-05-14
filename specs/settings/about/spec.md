---
status: migrated
feature: settings/about
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: About

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/about/](../../../lib/features/settings/about/) and [features.md `## settings · B`](../../features.md#settings--b).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both. No flavor branching in the screen.
- **Flavor-conditional behavior**: app icon / brand fall back to `Assets.icons.defaultHorizontalLogo` via `CommonImage`'s `fallBackImagePath` ([about_screen.dart:111-118](../../../lib/features/settings/about/about_screen.dart#L111-L118)). Different flavors ship different assets at `assetsPath('filhos_logo_white')`.
- **Server role implication**: no role-specific endpoint. `AboutRepo.getAbout()` calls `schools/{schoolId}/pages/about` — same for both flavors. Note: today the bloc has the network call commented out and only reads `PackageInfo.fromPlatform()` ([about_bloc.dart:30-38](../../../lib/features/settings/about/bloc/about_bloc.dart#L30-L38)).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See app version + brand + contact (Priority: P1) 🎯 MVP

A user opens "About" from Settings, sees the app logo, the installed version (e.g. "V 1.2.3"), an "up to date" badge when `AppVersionChecker.canUpdate == false`, the About-Filhos copy, contact email + phone (when present), and Share / Rate-app buttons.

**Why this priority**: legal + LGPD requirement to expose version + contact + share + rate. Required for store-listing compliance.

**Independent Test**:
1. From Settings, tap `about`.
2. `FetchAbout` fires; `AboutBloc` reads `PackageInfo.fromPlatform()` and `AppVersionChecker.checkUpdate()`.
3. Logo, version, "up to date" badge (if applicable), about text, contact info, share + rate buttons render.
4. Tap **Share** → native share sheet opens with the platform-specific app URL.
5. Tap **Rate** → Play Store / App Store opens to the app listing.

**Acceptance Scenarios**:

1. **Given** the screen mounts, **When** `FetchAbout` fires, **Then** `PackageInfo.fromPlatform()` populates `state.version` and `AppVersionChecker().checkUpdate()` populates `state.canUpdate`.
2. **Given** the app is on the latest store version (`canUpdate == false`), **When** the screen renders, **Then** the `your_app_version_is_up_to_date` localization is shown beneath the version.
3. **Given** the user is on iOS, **When** they tap Share, **Then** `Config.get.appInfo.iosUrl` is shared via `share_plus`.
4. **Given** the user is on Android, **When** they tap Share, **Then** `Config.get.appInfo.androidUrl` is shared.
5. **Given** the user taps Rate on Android, **When** `launchStore()` runs, **Then** `market://details?id={packageName}` opens.
6. **Given** the user taps Rate on iOS, **When** `launchStore()` runs, **Then** `https://apps.apple.com/app/id{appStoreId}` opens.
7. **Given** the user taps the logo, **When** the `GestureDetector` fires, **Then** `launchUrl(Config.appUrl)` opens the marketing site.
8. **Given** the server returns `email` and `phone`, **When** the about state has data, **Then** the Contact block renders both rows.

### Edge Cases

- **`AboutRepo.getAbout()` is not called** — the network branch in `FetchAbout` is commented out at [about_bloc.dart:32-38](../../../lib/features/settings/about/bloc/about_bloc.dart#L32-L38). The `email` / `phone` rows in the screen are wrapped in `if (validString(about?.email) || validString(about?.phone))` ([about_screen.dart:195](../../../lib/features/settings/about/about_screen.dart#L195)) and will **never** render since `state.data` stays null. Bug — see [tasks.md T-fix-1](tasks.md).
- **`AppVersionChecker` throws on store errors** — caught generically with a `print('AboutBloc.AboutBloc Exception $e')` ([about_bloc.dart:29](../../../lib/features/settings/about/bloc/about_bloc.dart#L29)). The screen continues to render but without `canUpdate`.
- **Logo `launchUrl` failure** is swallowed with a `debugPrint` — user sees no feedback.
- **Hardcoded `Colors.transparent`** in the app bar ([about_screen.dart:54](../../../lib/features/settings/about/about_screen.dart#L54)) — intentional to let the primary header color show through `extendBodyBehindAppBar`.
- **`PoweredByWidget`** is pinned to the bottom safe area; useful for footer attribution.
- **Approval gate**: implicit (downstream of Settings).
- **`copyWith` on `AboutState`** is untyped (returns `dynamic`) — fragile.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display the installed app version via `PackageInfo.fromPlatform()`.
- **FR-002**: System MUST check the store for a newer version via `AppVersionChecker.checkUpdate()` and show `your_app_version_is_up_to_date` when none is available.
- **FR-003**: System MUST display localized about-app copy (`about_filhos_title` + `about_filhos_description`).
- **FR-004**: System MUST expose Share and Rate buttons.
- **FR-005**: System MUST link the Share button to `Config.get.appInfo.iosUrl` / `androidUrl` based on `Platform`.
- **FR-006**: System MUST link the Rate button to the platform's store listing.
- **FR-007**: System SHOULD fetch contact info (email + phone) from `GET schools/{schoolId}/pages/about` — **currently not called**; the wiring is in place but the bloc call is commented.
- **FR-008**: System MUST display the brand logo with a flavor-specific fallback (`Assets.icons.defaultHorizontalLogo`).
- **FR-009**: System MUST surface a `PoweredByWidget` at the bottom of the safe area.

### Localization Requirements

| Key | Use site |
|---|---|
| `about` | screen title |
| `your_app_version_is_up_to_date` | latest-version badge |
| `about_filhos_title`, `about_filhos_description` | about copy block |
| `contact_us` | contact block title |
| `email`, `phone` | contact row labels |
| `share` | Share button |
| `rate` | Rate button |

No new keys required.

### Backend Touchpoints

- **REST endpoints**:
  - `GET schools/{schoolId}/pages/about` — returns `{data: AboutModel}` with `content`, `email`, `phone`. **Not currently called.**
- **Headers**: standard.
- **Firebase**: not used.
- **Firestore**: not used.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit).
- No device permissions. `launchUrl` opens the system browser / store app.

### Key Entities

- **`AboutModel`** ([about_model.dart](../../../lib/features/settings/about/models/about_model.dart)) — `{content, email, phone}`.
- **`AboutState`** — `{data: AboutModel?, version: String?, loading: bool, canUpdate: bool, error: String?}`.
- **`Config.get.appInfo`** — `{appName, iosUrl, androidUrl, appStoreId, ...}` from `ConfigCubit`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user sees the installed version within 200ms of opening the screen.
- **SC-002**: Share button always shares the correct platform-specific URL.
- **SC-003**: Rate button always opens the platform store listing.
- **SC-004** (open): Contact email / phone surface correctly once the `getAbout()` call is re-enabled (T-fix-1).

## Assumptions

- `package_info_plus` returns valid `version` on both flavors.
- `flutter_app_version_checker` can reach the store metadata; if not, the bloc silently swallows the exception.
- `Config.appUrl` / `Config.get.appInfo.{iosUrl, androidUrl, appStoreId}` are set in the remote config.
- The bundled fallback logo at `Assets.icons.defaultHorizontalLogo` is current branding.
