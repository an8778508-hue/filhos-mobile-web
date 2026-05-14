---
status: migrated
feature: settings
migrated_from: specs/features.md#settings--b
migrated_date: 2026-05-14
---

# Tasks: Settings (parent shell)

**Input**: [spec.md](spec.md), [plan.md](plan.md), and [features.md#settings--b](../features.md#settings--b).

**Tests**: No `test/` directory exists. Test tasks are aspirational.

**Organization**: This is a **migration** of an existing shell. Most items are already done (`[x]`). Sub-feature work lives in their own trios under `specs/settings/<sub>/tasks.md`.

## Format: `[ID] [P?] [Story] Description`

- **[Story]**: US1 = navigation list, US2 = logout, US3 = delete account, X = cross-cutting

---

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/settings/](../../lib/features/settings/) with sub-feature folders (`edit_profile/`, `my_children/`, `medicines/`, `medicines_professors/`, `announcements/`, `events/`, `about/`, `accept_event/`) and a `widgets/` folder for shared row widgets.
- [x] T002 Add localization keys for settings rows in [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) (`settings`, `my_information`, `my_addresses`, `my_children`, `menus`, `all_children`, `medicines`, `my_conversations`, `about`, `change_language`, `terms_and_conditions`, `logout`, `delete_account`, `delete_account_confirm`).

## Phase 2: Foundational — ✅ Complete

- [x] T010 Implement reusable [SettingsItem](../../lib/features/settings/widgets/settings_item.dart) with icon + title + optional notification badge + tap callback.
- [x] T011 Implement [CompleteProfileCard](../../lib/features/settings/widgets/complete_profile_card.dart) (top banner for incomplete-profile state).

## Phase 3: User Story 1 — Navigate from Settings tab (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] Implement `SettingsScreen` shell in [settings_screen.dart](../../lib/features/settings/settings_screen.dart) with a `MyAppBar` + scrollable column of `SettingsItem` rows.
- [x] T021 [US1] Wire each row to its destination screen (push via `MaterialPageRoute`).
- [x] T022 [US1] Gate parents-only / teachers-only rows via `context.isParents` / `context.isProfessors`.
- [x] T023 [US1] Route `medicines` to `MedicinesScreen` (parents) vs `MedicinesProfessorsScreen` (teachers).
- [x] T024 [US1] Show `CompleteProfileCard` when `user?.completedProfile() == false`.
- [x] T025 [US1] Badge `my_conversations` row with `ChatBloc.unReadMessagesCount`.
- [x] T026 [US1] Conditionally render `change_language` only when `Config.get.langs.length > 1`.

## Phase 4: User Story 2 — Logout (P1) — ✅ Complete

- [x] T030 [US2] Implement the `logout` row tap → `UserBloc.get.loggedOut()`.
- [x] T031 [US2] Wire `UserListener` (`compareStates([(s) => s.user != null])`) — when `state.user == null`, dispatch `MainBloc.ChangePage(home)` and push `ChooseLanguageScreen`.
- [x] T032 [US2] **(P0)** Ensure `_signOutCleanup` clears the FCM token + alarm state + emits a clean `UserState`. *Fixed 2026-05-14 per [features.md#settings--b](../features.md#settings--b).*

## Phase 5: User Story 3 — Delete account (P1) — ✅ Complete (with open caveat)

- [x] T040 [US3] Add the `delete_account` red-styled row to the shell.
- [x] T041 [US3] Show a `confirmDialog` (titleKey `delete_account`, bodyKey `delete_account_confirm`) before calling `UserBloc.get.deleteAccount()`.
- [ ] **T-fix-2** **(P1)** [US3] *(from [features.md#settings--b](../features.md#settings--b))* Verify `UserBloc.deleteAccount()` triggers actual server-side LGPD-Art.18 erasure, not just `_signOutCleanup()`. Today (`user_bloc.dart:102`) it aliases to logout. Coordinate with backend for the dedicated erasure endpoint and update.

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Bugs / open P0–P1 from features.md

- [ ] **T-fix-1** **(P0)** *(from [features.md#settings--b](../features.md#settings--b))* Add an "Export my data" path under settings (LGPD Art. 18, II). Not yet implemented.
- [ ] **T-fix-2** (see Phase 5 above) **(P1)** Verify `settings_screen.dart:240-254` `deleteAccount` triggers a real server-side erasure.
- [x] **(P0)** Logout: clears `FirebaseMessaging.deleteToken()` + alarm state + emits clean `UserState`. *Fixed 2026-05-14 in `UserBloc._signOutCleanup`. Server-side token revocation endpoint pending — coordinate with backend.*

### Constitution drift fixes

- [ ] **T-fix-3** **(P2)** [US1] Replace `Colors.white` and `Colors.red` on the chat badge ([settings_screen.dart:196-197](../../lib/features/settings/settings_screen.dart#L196-L197)) with `context.colors.secondaryTextColor` and `context.colors.alert` to honor `ConfigCubit.styling`.
- [ ] **T-fix-4** **(P2)** [US1] The `terms_and_conditions` row passes `notificationBackgroundColor: context.colors.alert` and a stray `notificationNumber: 12` even though `hasNotifications: false` ([settings_screen.dart:215-225](../../lib/features/settings/settings_screen.dart#L215-L225)). Either remove the no-op props or wire a real value.

### Code hygiene

- [ ] **T-cleanup-1** Replace `Colors.white` / `Colors.red` (T-fix-3 covers this).
- [ ] **T-cleanup-2** Delete commented-out branches inside `settings_screen.dart`:
  - lines 82-94 (commented `if (context.isParents)` gate on addresses)
  - lines 144-157 (`if(false) if (context.isParents) gallery row`)
  - lines 179-190 (commented events row)
  - line 144 lone `if(false)` orphan
  Git log preserves history.
- [ ] **T-cleanup-3** Remove `print('_EditProfileScreenState.initControllers ...')` and similar `print` calls present across settings sub-features. Tracked at repo level in [features.md cross-feature task](../features.md#cross-feature-tasks) "Route 146 print/debugPrint calls through a single logger."

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test asserting the parents-flavor row set vs the teachers-flavor row set.
- [ ] **T-test-2** [P] [US2] Widget test that tapping `logout` clears `UserBloc` and bounces the page to `home`.
- [ ] **T-test-3** [P] [US3] Widget test that `delete_account` requires confirmation before calling `UserBloc.deleteAccount()`.

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-3 / T-cleanup-* — no new warnings expected.
- [ ] **TX02** [X] Build both flavors and sanity-check the row order on each.

---

## Dependencies & Execution Order

- Phases 1–5 are complete except T-fix-2.
- Order for Phase 6: T-cleanup-2 (lowest risk) → T-fix-3 → T-fix-4 → T-fix-1 (LGPD export) → T-fix-2 (LGPD erasure; coordinate with backend).

## Gaps Found

- **LGPD export-my-data is missing** — Art. 18, II compliance gap. (T-fix-1)
- **`deleteAccount` is a local logout** today — Art. 18, II erasure gap. (T-fix-2)
- **Dead row scaffolding** for gallery / addresses-parents-gate / events row left commented in `settings_screen.dart`. (T-cleanup-2)
- **Hardcoded `Colors.white` / `Colors.red`** on the chat badge. (T-fix-3)
- **Many `print(...)` calls in sub-features** — repo-wide problem, tracked at the cross-feature task.

## Notes

- This shell never calls REST itself; all gaps about endpoints belong to the sub-feature trios.
- The events sub-feature has its own P0 EventBus subscription leak — see [specs/settings/events/tasks.md](events/tasks.md).
- `AnnouncementsScreen` is not reachable from this shell today; the row appears to have been moved to Home + push deep-links. See [specs/settings/announcements/tasks.md](announcements/tasks.md).
