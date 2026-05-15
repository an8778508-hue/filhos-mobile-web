# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  Pre-filled for Criarte (Flutter mobile, two flavors from one codebase).
  Adjust per-feature only where the defaults don't apply.
-->

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**: `flutter_bloc` 9, `hydrated_bloc` 10, `get_it` 8, `dio` 5, `hive` 2, Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_crashlytics`, `firebase_app_check`), `flutter_screenutil`

**Storage**: Hive (via `LocalDatabaseRepo`) for local key-value; HydratedBloc for persisted Cubit state; Firestore for chat; Firebase Storage for media; REST API at `https://criarte.filhos.app/api/v1/`

**Testing**: `flutter_test`. Real coverage is minimal today — note in the plan whether this feature adds tests, and what's deferred.

**Target Platform**: iOS + Android, in **both flavors** (`parents` and `professores`). Design size 430×932 (`flutter_screenutil`).

**Project Type**: Flutter mobile app (single codebase, two product flavors)

**Performance Goals**: [Feature-specific — e.g., chat list scroll 60fps, image upload progress UX]

**Constraints**: [Feature-specific — e.g., offline behavior, large file uploads up to the 10h Dio timeout, alarm reliability]

**Scale/Scope**: [Feature-specific — number of screens added, number of new keys, number of new endpoints]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [ ] **I. Feature-First Layout** — new code lands under `lib/features/<feature>/` mirroring a sibling
- [ ] **II. Dependency Direction** — no feature-to-feature imports; shared code goes in `lib/core/`; DI wired in `lib/init_dependencies.dart`
- [ ] **III. Networking Contract** — all REST calls via `NetworkClient.handleRequest` returning `Either<Failure, T>`; no manual auth headers
- [ ] **IV. Persistence Discipline** — Hive only through `LocalDatabaseRepo`; HydratedBloc state round-trips `toJson`/`fromJson`
- [ ] **V. Flavor Branching** — `context.isParents` / `context.isProfessors`, no string compares; both flavors verified
- [ ] **VI. Localization** — every user-visible string added to `localization_keys.dart` + pt/en/ar JSONs
- [ ] **VII. Realtime Surfaces Source of Truth** — chat AND diary reactions/comments (and any new realtime social surface) use Firestore, not a parallel REST realtime path
- [ ] **VIII. Approval Gate** — any deep-link / push handler respects `isApproval == false`
- [ ] **IX. Medicine Reminders** — alarms use the native wrapper in `lib/core/custom_packages/`, not mixed with `flutter_local_notifications`
- [ ] **X. Theming & Sizing** — `flutter_screenutil` 430×932 design; theme pulled from `ConfigCubit.styling`
- [ ] **Quality Gates** — `flutter analyze` planned for both flavors; release build planned for both flavors before merge

Any "no" answer requires an entry in **Complexity Tracking** below.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/                                      # Shared infrastructure (unchanged unless feature adds shared widgets/utils)
│   ├── network/                               # NetworkClient + interceptors
│   ├── local_db/                              # LocalDatabaseRepo (Hive)
│   ├── localization/                          # localization_keys.dart  ← add new keys here
│   ├── components/                            # Shared widgets (add here only if reused across features)
│   ├── models/                                # Cross-feature domain models
│   ├── theme/                                 # ConfigCubit-driven theme
│   ├── notifications_service/                 # FCM + local notifications
│   ├── user/                                  # UserBloc (HydratedCubit)
│   ├── config/                                # ConfigCubit (HydratedCubit)
│   └── ...
│
├── features/
│   └── [feature_name]/                        # ← new feature lives here
│       ├── [feature]_di.dart                  # DependencyInjection at feature root, registered in lib/init_dependencies.dart
│       ├── presentation/
│       │   ├── bloc/                          # feature_bloc.dart, _event.dart, _state.dart
│       │   ├── widgets/
│       │   └── [feature]_screen.dart
│       ├── data_sources/
│       │   ├── [feature]_repository.dart      # abstract contract (or [feature]_repo.dart — both styles in use)
│       │   └── [feature]_impl.dart            # uses NetworkClient.handleRequest → Either<Failure, T>
│       └── models/
│
├── flavors/
│   └── app_flavors.dart                       # context.isParents / context.isProfessors
├── init_dependencies.dart                     # ← register new feature_di here
├── main.dart                                  # parents flavor entry
└── main_professores.dart                      # professores flavor entry

assets/langs/
├── pt.json                                    # ← add translations (primary)
├── en.json                                    # ← add translations
└── ar.json                                    # ← add translations

test/                                          # flutter_test (real coverage is minimal today)
```

**Structure Decision**: Document any deviations from the standard feature layout above (e.g., placing `bloc/` at the feature root like `onboard/`, or sharing widgets up into `lib/core/components/`).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation                               | Why Needed         | Simpler Alternative Rejected Because        |
| --------------------------------------- | ------------------ | ------------------------------------------- |
| [e.g., feature-to-feature import]       | [current need]     | [why moving to lib/core/ is insufficient]   |
| [e.g., REST call outside handleRequest] | [specific problem] | [why interceptor-based flow doesn't fit]    |
