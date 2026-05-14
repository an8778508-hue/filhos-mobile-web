---
status: migrated
feature: settings
flavor_scope: both
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Feature Specification: Settings (parent shell)

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/settings/settings_screen.dart](../../lib/features/settings/settings_screen.dart) + its sub-features under [lib/features/settings/](../../lib/features/settings/) (91 .dart files in total) and the existing [features.md `## settings · B`](../features.md#settings--b) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores). The shell is the same; rows are added/removed at runtime via `context.isParents` / `context.isProfessors`.
- **Flavor-conditional behavior**:
  - **Parents-only rows**: `my_children` ([settings_screen.dart:108-120](../../lib/features/settings/settings_screen.dart#L108-L120)), `menus` ([settings_screen.dart:121-133](../../lib/features/settings/settings_screen.dart#L121-L133)).
  - **Teachers-only rows**: `all_children` ([settings_screen.dart:134-143](../../lib/features/settings/settings_screen.dart#L134-L143)).
  - **Medicines** routes to two different screens by flavor: `MedicinesScreen` (parents) vs `MedicinesProfessorsScreen` (teachers) ([settings_screen.dart:158-178](../../lib/features/settings/settings_screen.dart#L158-L178)).
  - **Conversations** dispatch: `goToContactsScreen` chooses `ProfessorsContacts` vs `ContactsScreen` based on the current `ChatBloc.currentUser.type` *and* the flavor ([settings_screen.dart:268-275](../../lib/features/settings/settings_screen.dart#L268-L275)).
- **Server role implication**: the shell itself makes no REST calls, but each row's downstream screen calls a role-specific endpoint (e.g. `/parent/children`, `/parent/medicines` vs `teacher/medicines/*`, `/teacher/announcements`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate from the Settings tab (Priority: P1) 🎯 MVP

A signed-in user taps the Settings tab and sees a vertical list of rows (profile, addresses, children/menus or all-children, medicines, chat, about, change-language, terms, logout, delete-account). Tapping a row pushes its dedicated screen.

**Why this priority**: This is the navigation hub for nine separate user surfaces. If the shell breaks, every settings sub-feature becomes unreachable.

**Independent Test**:
1. Launch either flavor.
2. Open the Settings tab.
3. Confirm the rows render in the expected order with the correct localized labels and SVG icons.
4. Tap each row and confirm the right screen is pushed.

**Acceptance Scenarios**:

1. **Given** a parent flavor build, **When** the Settings tab renders, **Then** the rows are: `my_information`, `my_addresses`, `my_children`, `menus`, `medicines`, `my_conversations`, `about`, (optional `change_language` when `Config.get.langs.length > 1`), `terms_and_conditions`, `logout`, `delete_account`.
2. **Given** a teacher flavor build, **When** the Settings tab renders, **Then** `my_children` and `menus` are hidden and `all_children` is shown; the `medicines` row routes to `MedicinesProfessorsScreen`.
3. **Given** the user's profile is incomplete (`user.completedProfile() == false`), **When** the Settings tab renders, **Then** a `CompleteProfileCard` is shown at the top with `user.getPercentage()`.
4. **Given** the user has unread chat messages, **When** the Settings tab renders, **Then** the `my_conversations` row shows a red dot badge with the count from `ChatBloc.unReadMessagesCount`.
5. **Given** the `change_language` row is tapped, **When** the destination screen pops with a language change, **Then** the user re-renders against the new locale (handled by `ConfigCubit` rebuild upstream).

---

### User Story 2 - Logout (Priority: P1)

A user taps **Logout** at the bottom of the settings list and is signed out of the app.

**Why this priority**: Critical credential-revocation path. Required for LGPD compliance and account hand-off.

**Independent Test**:
1. From Settings, tap `logout`.
2. Confirm `UserBloc.get.loggedOut()` fires.
3. Confirm a `UserListener` re-route swaps the main tab back to `home` and pushes `ChooseLanguageScreen`.
4. Confirm the FCM token is deleted and persisted user state is wiped via `_signOutCleanup` (already fixed 2026-05-14 in `UserBloc`).

**Acceptance Scenarios**:

1. **Given** an authenticated user, **When** they tap `logout`, **Then** `UserBloc.get.loggedOut()` is called ([settings_screen.dart:229-231](../../lib/features/settings/settings_screen.dart#L229-L231)).
2. **Given** the user-state listener observes `state.user == null`, **When** logout finishes, **Then** the `MainBloc` switches to `PageID.home` and `ChooseLanguageScreen.push(context)` runs ([settings_screen.dart:44-49](../../lib/features/settings/settings_screen.dart#L44-L49)).
3. **Given** a successful sign-out, **When** the cleanup runs, **Then** Firebase Messaging token is deleted, alarm state is cleared, and a clean `UserState` is emitted (verified by `features.md` 2026-05-14 fix in `_signOutCleanup`).

---

### User Story 3 - Delete account (Priority: P1)

A user taps **Delete account** (red row), confirms in a modal, and the account is deleted.

**Why this priority**: LGPD Article 18, II requires a user-initiated erasure path. Today this routes through `UserBloc.deleteAccount()` which (per `user_bloc.dart:102`) simply aliases to `_signOutCleanup()` — i.e. **it currently behaves like a local logout, not a server-side erasure.** Flagged in [features.md#settings--b](../features.md#settings--b) (P1) and in [tasks.md T-fix-2](tasks.md).

**Independent Test**:
1. From Settings, tap `delete_account`.
2. Confirm a `confirmDialog` appears with `delete_account_confirm` body.
3. Confirm.
4. Verify the local logout runs.
5. **[NEEDS CLARIFICATION]** verify a server-side LGPD-Art.18 erasure is also triggered (today: not implemented).

**Acceptance Scenarios**:

1. **Given** the user taps Delete account, **When** they tap "confirm" on the modal, **Then** `UserBloc.get.deleteAccount()` is called.
2. **Given** they tap "cancel", **When** the modal dismisses, **Then** nothing happens.
3. **Given** the delete completes, **When** the user-state listener sees `state.user == null`, **Then** the user is bounced to the main shell home + language picker (same path as logout).

---

### Edge Cases

- **`MyAddressesScreen` is shown for both flavors today** ([settings_screen.dart:96-107](../../lib/features/settings/settings_screen.dart#L96-L107)). The commented-out code on lines 82-94 used to gate it to parents-only. **[NEEDS CLARIFICATION]** intent: does this row belong on the teacher flavor?
- **`Gallery` row is dead** — wrapped in `if(false)` ([settings_screen.dart:144-157](../../lib/features/settings/settings_screen.dart#L144-L157)). Gallery is reached via Home; this commented branch should be removed.
- **`Events` row is fully commented out** ([settings_screen.dart:179-190](../../lib/features/settings/settings_screen.dart#L179-L190)). Events live at the top of `MainScreen` (`PageID.events`), not under Settings — see [features.md cross-feature task](../features.md#cross-feature-tasks).
- **`terms_and_conditions` row has a stray `notificationBackgroundColor: context.colors.alert`** ([settings_screen.dart:220](../../lib/features/settings/settings_screen.dart#L220)) even though `hasNotifications: false`. Cosmetic.
- **`change_language` row is conditional on `Config.get.langs.length > 1`** — schools with one language won't see it. Hidden vs disabled is intentional.
- **Approval gate**: settings lives behind the main shell, so users with `isApproval == false` should never reach it. Not enforced inside this feature.
- **`Snack` / dialogs on logout failure** — `_signOutCleanup` swallows errors silently. If FCM token delete throws, the user still appears signed out. Worth noting; not surfaced to the user.
- **`Announcements` row not present in this shell** — `AnnouncementsScreen` is reached from `Home` and from push deep-links, not from Settings. Confirmed via grep on `AnnouncementsScreen` usage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render a vertical scrollable list of settings rows on the Settings tab.
- **FR-002**: System MUST gate `my_children`, `menus` to the `parents` flavor (`context.isParents`) and gate `all_children` to the `professores` flavor.
- **FR-003**: System MUST route the `medicines` row to `MedicinesScreen` on parents and to `MedicinesProfessorsScreen` on teachers.
- **FR-004**: System MUST show a `CompleteProfileCard` with the user's completion percentage when `user.completedProfile() == false`.
- **FR-005**: System MUST badge the `my_conversations` row with `ChatBloc.unReadMessagesCount` when non-zero.
- **FR-006**: System MUST surface the `change_language` row only when more than one language is configured in `Config.get.langs`.
- **FR-007**: System MUST call `UserBloc.get.loggedOut()` when the user taps `logout`.
- **FR-008**: System MUST present a confirmation modal (`confirmDialog` with `delete_account_confirm`) before triggering `UserBloc.get.deleteAccount()`.
- **FR-009**: System MUST listen for `UserState` transitions to `user == null` and, on logout, switch the `MainBloc` page to `home` and push `ChooseLanguageScreen`.
- **FR-010**: Each row MUST use a `SettingsItem` widget with an SVG icon from `assetsPath(...)`, localized title, and an `onTap` navigation callback.

### Localization Requirements

User-visible row titles route through `LocalizationKeys`. Keys actually referenced:

| Key | Use site |
|---|---|
| `settings` | app bar title |
| `my_information` | edit-profile row |
| `my_addresses` | addresses row |
| `my_children` | parents-only row |
| `menus` | parents-only row |
| `all_children` | teachers-only row |
| `gallery` | (dead) gallery row |
| `medicines` | medicines row |
| `my_conversations` | chat row |
| `about` | about row |
| `change_language` | language row |
| `terms_and_conditions` | terms row |
| `logout` | logout row |
| `delete_account`, `delete_account_confirm` | delete-account row + confirm modal |

No new keys required.

### Backend Touchpoints

- **REST endpoints**: none from the shell itself. Logout/delete go through `UserBloc` → `_signOutCleanup` which (today) only clears local state; the [features.md cross-feature task](../features.md#cross-feature-tasks) tracks the pending server-side `revoke_device_token` endpoint and the LGPD-Art.18 server-side erasure (open).
- **Firebase**: `FirebaseMessaging.deleteToken()` runs in `_signOutCleanup` (fixed 2026-05-14 per [features.md#settings--b](../features.md#settings--b)).
- **Firestore**: not used by the shell.

### Permissions & Approval Gate

- Requires `isApproval == true` (implicit — reached only via `MainScreen`).
- No device permissions for the shell. Sub-features (camera for profile photo, etc.) declare their own.

### Key Entities

- **`UserModel`** ([lib/core/models/user_model.dart](../../lib/core/models/user_model.dart)) — `completedProfile()` and `getPercentage()` drive the `CompleteProfileCard`.
- **`MainBloc.ChangePage`** ([lib/features/main/bloc/main_bloc.dart](../../lib/features/main/bloc/main_bloc.dart)) — routed to on logout.
- **`SettingsItem`** ([lib/features/settings/widgets/settings_item.dart](../../lib/features/settings/widgets/settings_item.dart)) — the reusable row widget.
- **`CompleteProfileCard`** ([lib/features/settings/widgets/complete_profile_card.dart](../../lib/features/settings/widgets/complete_profile_card.dart)) — completion-percentage banner.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Cold-open Settings tab → first frame ≤ 200 ms (no REST calls on the shell itself).
- **SC-002**: Tapping `logout` deletes the FCM token, clears alarm state, and emits `user == null` — verified 2026-05-14.
- **SC-003**: Both flavors render their respective row set without runtime branching errors; build the app twice to verify.
- **SC-004**: `delete_account` confirms with a modal before any destructive action.
- **SC-005**: `my_conversations` badge count matches `ChatBloc.unReadMessagesCount` within one frame of the underlying value changing.

## Assumptions

- The shell does not control the navigation target order; future re-orderings happen here directly.
- `MainScreen` is the only entry point — settings is not deep-linked from push.
- `UserBloc.deleteAccount()` will eventually call a server-side erasure endpoint; today it aliases to `_signOutCleanup()` and is therefore equivalent to logout.
- `ConfigCubit.langs` is hydrated before the Settings tab renders so the `change_language` row's visibility is stable.
