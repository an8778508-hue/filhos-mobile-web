---
status: migrated
feature: settings
migrated_from: lib/features/settings/
migrated_date: 2026-05-14
---

# Implementation Plan: Settings (parent shell)

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/settings/spec.md](spec.md) and code in [lib/features/settings/settings_screen.dart](../../lib/features/settings/settings_screen.dart).

## Summary

The settings shell is a thin stateless screen that renders a list of `SettingsItem` rows. Each row is a navigation hop into a sub-feature (edit_profile, my_children, medicines, …). The shell itself owns no bloc / no repo / no network — it reads `UserBloc`, `ChatBloc`, and `Config.get` and dispatches `MainBloc` page changes on logout.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned).

**Primary Dependencies**:

- `flutter_bloc` — `UserListener`, `BlocProvider` of `ChatBloc`, `MainBloc`.
- `flutter_screenutil` — `.h` / `.w` / `.r` sizing.
- `flutter_svg` (transitively, via `SettingsItem`).

**Storage**: none directly. Reads `UserBloc` hydrated state.

**Testing**: none.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature, no bloc — pure navigation shell.

**Performance Goals**: First frame ≤ 200 ms; no network on mount.

**Constraints**: cannot import any sub-feature lazily — every sub-feature screen is referenced statically at the top of the file. This makes the shell a heavy fan-in compile-time hub but it has no runtime cost.

**Scale/Scope**: 1 screen file + 2 row widgets + 1 `goToContactsScreen` helper. ~270 LOC.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — code lives under `lib/features/settings/` with sub-features as siblings (`edit_profile/`, `my_children/`, `medicines/`, …). ✓
- [x] **II. Dependency Direction** — the shell imports many sub-feature screens directly; acceptable for a navigation hub. No reverse imports observed.
- [x] **III. Networking Contract** — N/A; the shell makes no REST calls.
- [x] **IV. Persistence Discipline** — N/A; the shell reads `UserBloc` hydrated state but doesn't write.
- [x] **V. Flavor Branching** — uses `context.isParents` / `context.isProfessors` correctly throughout. ✓
- [x] **VI. Localization** — all titles route through `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — implicit via `MainScreen` being upstream.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — all `.h` / `.w` / `.r` / `context.colors.*`. ⚠️ Minor: `Colors.white` and `Colors.red` are hardcoded for the chat badge ([settings_screen.dart:196-197](../../lib/features/settings/settings_screen.dart#L196-L197)) — see [tasks.md T-cleanup-1](tasks.md).

## Project Structure

### Documentation (this feature)

```text
specs/settings/
├── spec.md                # this shell
├── plan.md
├── tasks.md
├── edit_profile/          # sub-feature trio
├── my_children/           # sub-feature trio
├── medicines/             # sub-feature trio (parents + teachers)
├── announcements/         # sub-feature trio (not reachable from shell)
├── events/                # sub-feature trio (P0 EventBus leak)
└── about/                 # sub-feature trio
```

### Source Code (existing)

```text
lib/features/settings/
├── settings_screen.dart                    # this file — the shell
├── widgets/
│   ├── settings_item.dart                  # reusable row widget
│   └── complete_profile_card.dart          # top banner shown when profile incomplete
├── edit_profile/                           # see specs/settings/edit_profile/
├── my_children/                            # see specs/settings/my_children/
├── medicines/                              # parents-side medicines (see specs/settings/medicines/)
├── medicines_professors/                   # teachers-side medicines (same spec)
├── announcements/                          # see specs/settings/announcements/
├── events/                                 # see specs/settings/events/
├── about/                                  # see specs/settings/about/
└── accept_event/                           # event RSVP / approval screen (used from notification deep-link)
```

### Cross-feature touch points

- [lib/features/main/bloc/main_bloc.dart](../../lib/features/main/bloc/main_bloc.dart) — `ChangePage` dispatched on logout.
- [lib/features/chat/presentation/bloc/chat_bloc.dart](../../lib/features/chat/presentation/bloc/chat_bloc.dart) — `unReadMessagesCount` watched for badge.
- [lib/features/main/presentation/main_screen.dart](../../lib/features/main/presentation/main_screen.dart) — Settings tab is rendered inside main shell.
- [lib/features/choose_language/](../../lib/features/choose_language/) — pushed on logout.
- [lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart) — `loggedOut()` and `deleteAccount()` are the action verbs.
- [lib/features/all_children/](../../lib/features/all_children/), [lib/features/home/widgets/children_menus.dart](../../lib/features/home/widgets/children_menus.dart), [lib/features/gallery/](../../lib/features/gallery/), [lib/features/my_addresses/](../../lib/features/my_addresses/), [lib/features/chat/presentation/](../../lib/features/chat/presentation/), [lib/features/terms_and_condtions/](../../lib/features/terms_and_condtions/) — direct navigation targets.

**Structure Decision**: pure-navigation shell; no bloc layer. Acceptable per existing repo conventions (cf. `onboard/` which is also blocless).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Heavy compile-time fan-in of sub-feature screen imports | A navigation shell has to reference every destination. | A `Map<String, WidgetBuilder>` registry per-feature could decouple, but introduces a global navigation table inconsistent with the rest of the codebase. Defer. |
| `Colors.white` / `Colors.red` hardcoded for chat badge | Quick visual fix during development. | Should use `context.colors.secondaryTextColor` / `context.colors.alert`. **See tasks.md T-cleanup-1.** |
| Commented-out blocks for gallery row, events row, addresses-parents gate | Iteration history left in place. | Delete (preserved in git). **See tasks.md T-cleanup-2.** |
