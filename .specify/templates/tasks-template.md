---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test tasks are OPTIONAL — the Criarte test suite is minimal today (`flutter_test` scaffolding only). Include tests where practical; don't block delivery on them unless the spec asks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions (Criarte)

- **Feature code**: `lib/features/<feature>/{presentation,data_sources,models}/`
- **Shared infrastructure**: `lib/core/...`
- **Localization keys**: `lib/core/localization/localization_keys.dart`
- **Translation JSONs**: `assets/langs/{pt,en,ar}.json`
- **DI registration**: `lib/init_dependencies.dart`
- **Flavor entry points**: `lib/main.dart` (parents), `lib/main_professores.dart` (professores)
- **Tests** (when added): `test/features/<feature>/`

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  The /speckit.tasks command MUST replace these with actual tasks derived from
  spec.md (user stories), plan.md (technical context), data-model.md, contracts/.
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold the feature directory and wire it into the app.

- [ ] T001 Create feature directory `lib/features/[feature]/{presentation/{bloc,widgets},data_sources,models}/` mirroring the closest sibling feature
- [ ] T002 Add new localization keys to `lib/core/localization/localization_keys.dart`
- [ ] T003 [P] Add Portuguese translations to `assets/langs/pt.json` (primary)
- [ ] T004 [P] Add English translations to `assets/langs/en.json`
- [ ] T005 [P] Add Arabic translations to `assets/langs/ar.json`
- [ ] T006 Create `lib/features/[feature]/[feature]_di.dart` (**at feature root**, not under `data_sources/`) implementing `DependencyInjection`
- [ ] T007 Register the new DI in `lib/init_dependencies.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Models, repository contract, and Bloc plumbing that user stories build on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T010 Define models in `lib/features/[feature]/models/` (or extend existing `lib/core/models/` if cross-feature)
- [ ] T011 Define repository contract `lib/features/[feature]/data_sources/[feature]_repository.dart` (or `[feature]_repo.dart` — both naming styles are in use; mirror the closest sibling)
- [ ] T012 Implement `[feature]_impl.dart` using `NetworkClient.handleRequest` returning `Either<Failure, T>` (no manual auth headers — interceptors handle them)
- [ ] T013 [P] Create Bloc/Cubit (`feature_bloc.dart`, `_event.dart`, `_state.dart`); use HydratedBloc with `toJson`/`fromJson` only if state must persist across cold starts
- [ ] T014 If feature talks to Firestore (chat/realtime), define the collection path conventions and listener lifecycle
- [ ] T015 If feature deep-links from a push notification, ensure the handler honors the `isApproval == false → your_account_under_review` gate

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own — name the flavor(s) to test in]

### Tests for User Story 1 (OPTIONAL)

- [ ] T020 [P] [US1] Widget test for [screen] in `test/features/[feature]/[screen]_test.dart`
- [ ] T021 [P] [US1] Unit test for [bloc/repo] in `test/features/[feature]/[unit]_test.dart`

### Implementation for User Story 1

- [ ] T022 [P] [US1] Implement screen `lib/features/[feature]/presentation/[screen]_screen.dart` (use `context.isParents` / `context.isProfessors` for any flavor-conditional UI)
- [ ] T023 [P] [US1] Implement supporting widgets in `lib/features/[feature]/presentation/widgets/`
- [ ] T024 [US1] Wire screen to Bloc events/states
- [ ] T025 [US1] Pull theme from `ConfigCubit.styling` (no hardcoded colors); size with `flutter_screenutil` against 430×932
- [ ] T026 [US1] Verify behavior in **both flavors** (parents and professores)
- [ ] T027 [US1] Verify behavior for a user with `isApproval == false` (should not reach this screen)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description]

**Independent Test**: [How to verify this story works on its own]

### Implementation for User Story 2

- [ ] T030 [P] [US2] [Task]
- [ ] T031 [US2] [Task]
- [ ] T032 [US2] Verify in both flavors

**Checkpoint**: User Stories 1 AND 2 both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description]

**Independent Test**: [How to verify this story works on its own]

### Implementation for User Story 3

- [ ] T040 [P] [US3] [Task]
- [ ] T041 [US3] [Task]
- [ ] T042 [US3] Verify in both flavors

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup that spans user stories.

- [ ] TX01 Run `flutter analyze` — must pass with no new warnings
- [ ] TX02 Build parents flavor: `flutter build apk --flavor parents -t lib/main.dart`
- [ ] TX03 Build professores flavor: `flutter build apk --flavor professores -t lib/main_professores.dart`
- [ ] TX04 Cold-start the app and verify any HydratedBloc state for this feature round-trips correctly (`toJson` → `fromJson`)
- [ ] TX05 Verify Firestore listeners (if any) are properly disposed and don't leak
- [ ] TX06 If new push-notification types were added, end-to-end test deep linking
- [ ] TX07 [P] If launcher icon / splash changed, regenerate per-flavor:
  - `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml`
  - `flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml`
- [ ] TX08 [P] Documentation updates (CLAUDE.md if invariants changed)
- [ ] TX09 Run `quickstart.md` validation if present

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational
  - Can proceed in parallel (if staffed) or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — no dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational — may integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational — may integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before repository contract before Bloc before screen
- Both flavors verified before the story is "done"
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] (translations across pt/en/ar) can run in parallel
- All Foundational tasks marked [P] can run in parallel within Phase 2
- Once Foundational completes, all user stories can start in parallel (if team capacity allows)
- Tests for a user story marked [P] can run in parallel
- Widgets within a screen marked [P] can run in parallel
- Different user stories can be worked on in parallel by different developers

---

## Parallel Example: User Story 1

```bash
# Translations across three languages can be added in parallel:
Task: "Add Portuguese translations to assets/langs/pt.json"
Task: "Add English translations to assets/langs/en.json"
Task: "Add Arabic translations to assets/langs/ar.json"

# Independent widgets for a screen can be built in parallel:
Task: "Implement [WidgetA] in lib/features/[feature]/presentation/widgets/[widget_a].dart"
Task: "Implement [WidgetB] in lib/features/[feature]/presentation/widgets/[widget_b].dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently in **both flavors**
5. `flutter analyze` + per-flavor build
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test in both flavors → Deploy/Demo (MVP!)
3. Add User Story 2 → Test in both flavors → Deploy/Demo
4. Add User Story 3 → Test in both flavors → Deploy/Demo

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently; each verifies both flavors before merging

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **Verify in both flavors** before marking a story done
- All user-visible strings must exist in pt/en/ar (constitution VI)
- Repos return `Either<Failure, T>` via `NetworkClient.handleRequest` (constitution III)
- Commit after each task or logical group
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence, hardcoded strings, hardcoded colors
