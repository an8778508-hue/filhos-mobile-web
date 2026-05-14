---
status: migrated
feature: diary
migrated_from: specs/features.md#diary--b
migrated_date: 2026-05-14
---

# Tasks: Diary

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#diary--b](../features.md#diary--b).

**Tests**: No `test/` directory.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/diary/](../../lib/features/diary/) with `data_sources/`, `models/{models, questions_models, tamplets}/`, `presentation/{bloc, widgets/{...}}/`
- [x] T002 Localization keys for diary surfaces (assumed; not exhaustively verified across 68 files)
- [x] T003 Feature-root [diary_di.dart](../../lib/features/diary/diary_di.dart) registering `DiaryRepo` / `DiaryImpl` / `DiaryBloc` (factories)

## Phase 2: Foundational — ✅ Complete

- [x] T010 Define typed `Question` hierarchy (7 subclasses) with abstract base
- [x] T011 Define `MainCategory`, `QuestionCategory`, `Activity`, `SchoolItem`, `ChildMenuModel`, `QuestionCategoryTemplate`
- [x] T012 Implement `DiaryRepo` with 7 endpoints
- [x] T013 Implement `DiaryImpl` using `NetworkClient.handleRequest` + `dio.FormData` for multipart submits

## Phase 3: User Story 1 — Teacher compose & send (P1) 🎯 MVP — ✅ Complete

- [x] T020 [US1] `GetSchoolItems` → `SchoolItemsSucceed` populates the target picker
- [x] T021 [US1] `GetQuestionTemplates` → `QuestionsTemplatesLoaded`
- [x] T022 [US1] `AddQuetsion` / `RemoveQuestion` mutate the in-bloc `categoriesToSend` map
- [x] T023 [US1] `_uploadImagesAndSetUrls` converts local image paths to `MultipartFile`s on `ImagesQuestion.value` in place
- [x] T024 [US1] `SendQuestionsToApi` builds a `FormData` body with `fields[N][...]` indexing and POSTs to `teacher/questions/answers`
- [x] T025 [US1] `_getTypeableType` maps `SchoolItemType` to backend string (`class` / `child` / `level` / null for all-children)

## Phase 4: User Story 2 — Parent read timeline (P1) — ✅ Complete

- [x] T030 [US2] `GetDiaryActivities(date, childId)` → `DiaryActivitiesLoaded(activities)`
- [x] T031 [US2] `GetMenus(date, childId)` → `MenusLoaded(menus)`
- [x] T032 [US2] Activities sorted by `date` desc before render

## Phase 5: User Story 3 — Tolerant parsing (P1) — ✅ Complete (P0 fixes)

- [x] T040 **(P0)** [US3] *(from [features.md#diary--b](../features.md#diary--b))* `Question.fromJson` returns null on unknown / null / empty input. *Fixed 2026-05-14*
- [x] T041 **(P0)** [US3] *(from [features.md#diary--b](../features.md#diary--b))* `QuestionCategory.fromJson` filters nulls via `whereType<Question>()` and only parses `question` when the entry is `Map<String, dynamic>`. *Fixed 2026-05-14*
- [x] T042 **(P0)** [US3] *(from [features.md#diary--b](../features.md#diary--b))* Fixed typo `json['age(']` → `json['age']`. *Fixed 2026-05-14*

---

## Phase 6: Gaps & cleanups

### Bugs / open P0–P1 from features.md

- [ ] **T-fix-1** **(P1)** [US1] *(from [features.md#diary--b](../features.md#diary--b))* Add an `idempotency_key` / `request_id` to `sendQuestions` at [diary_impl.dart:209-310](../../lib/features/diary/data_sources/diary_impl.dart#L209-L310) to prevent duplicate answers on retry. Generate a UUID on the client; include as a body field. Server must dedupe by `(teacher_id, idempotency_key)`.

- [ ] **T-fix-2** **(P0)** [US1] Hardcoded `childId: 1` in [diary_bloc.dart:209](../../lib/features/diary/presentation/bloc/diary_bloc.dart#L209) — `_handleQuestionsTemplates` always queries for child id 1 regardless of compose target. Plumb the actual child id (or omit when targeting class / level / all) through `GetQuestionTemplates`.

- [ ] **T-fix-3** **(P1)** [theming] *(from [features.md#diary--b](../features.md#diary--b))* Use the shared `NetworkClient` in [share_button.dart:87](../../lib/features/diary/presentation/widgets/gallery_media/share_button.dart#L87) — currently constructs a fresh `Dio()` that bypasses auth header, school header, Crashlytics, and 401 interceptor.

- [ ] **T-fix-4** **(P1)** [bloc] *(from [features.md#diary--b](../features.md#diary--b))* Replace the catch-all `on<DiaryEvent>` in [diary_bloc.dart:37-53](../../lib/features/diary/presentation/bloc/diary_bloc.dart#L37-L53) with typed handlers. Use `droppable()` on `SendQuestionsToApi` to coalesce double-taps. Same pattern as [chat T-fix-2](../chat/tasks.md).

- [ ] **T-fix-5** **(P2)** [T] *(from [features.md#diary--b](../features.md#diary--b))* Add a "save as draft" path so partial entries don't lose data when the teacher navigates away. Today `categoriesToSend` is in-memory only.

- [ ] **T-fix-6** **(P2)** [T] *(from [features.md#diary--b](../features.md#diary--b))* Auto-populate the date with the current school day on the compose screen.

- [ ] **T-fix-7** **(P2)** [P] *(from [features.md#diary--b](../features.md#diary--b))* Add a weekly digest view (mood/sleep/food trends) — proposed feature.

- [ ] **T-fix-8** **(P2)** [B] *(from [features.md#diary--b](../features.md#diary--b))* Cache the question schema so the editor opens offline.

### Architecture

- [ ] **T-arch-1** **(P2)** [storage] Consider switching to the declared `/files/upload` flow: upload images first, get URLs, then submit `sendQuestions` with URL references instead of embedded multipart files. Pros: smaller submit body, retriable image uploads, queryable upload progress. Cons: two round-trips, partial-state on upload failure. Decision deferred until image-heavy entries become a UX issue.

### Code hygiene

- [ ] **T-cleanup-1** Delete the 200+ lines of commented-out `sendQuestions` implementations in [diary_impl.dart:99-208](../../lib/features/diary/data_sources/diary_impl.dart#L99-L208). Git log preserves the iteration history.

- [ ] **T-cleanup-2** [US2 bug] Move `activities.sort` out of the per-activity loop ([diary_impl.dart:42-45](../../lib/features/diary/data_sources/diary_impl.dart#L42-L45)). Currently O(n² log n); should be O(n log n). Sort once after the parse loop.

- [ ] **T-cleanup-3** Remove the unused `/files/upload` endpoint reference from `DiaryRepo` and `uploadAttachments` from `DiaryImpl` if T-arch-1 is rejected. Or implement T-arch-1 and delete the multipart-embedded path.

- [ ] **T-cleanup-4** Drop `QuestionType.textfield` from the enum — its only `case` ([question.dart:153-155](../../lib/features/diary/models/questions_models/question.dart#L153-L155)) returns `'textarea'`. Same for `StringExtension.toQuestionType()`'s `'textfield'` case which maps to `QuestionType.textarea`. Either it's a real distinct type that needs a separate widget, or it's dead.

- [ ] **T-cleanup-5** Remove the verbose `debugPrint('===== SENDING QUESTIONS REQUEST =====')` cluster at [diary_impl.dart:290-301](../../lib/features/diary/data_sources/diary_impl.dart#L290-L301). Route through a structured logger that drops in release builds. Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about 146 print calls.

- [ ] **T-cleanup-6** Snake-case-to-camelCase rename in `QuestionCategory`: `count_love` / `count_wow` / `count_sad` / `count_angry` / `count_like` / `count_haha` / `icon_value`. Field names in Dart should be camelCase; JSON keys stay snake_case in `fromJson`. Touches the model + every widget that reads the counts.

- [ ] **T-cleanup-7** Rename typo'd filesystem identifiers:
  - `lib/features/diary/models/tamplets/` → `templates/`
  - `lib/features/diary/presentation/dairy_screen.dart` → `diary_screen.dart`
  - `lib/features/diary/presentation/widgets/diary_activites.dart` → `diary_activities.dart`
  - `lib/features/diary/presentation/widgets/professor_questions/items_to_send.dart/` → `items_to_send/` (directory currently has `.dart` extension)

  Each is a project-wide grep-and-replace; coordinate timing.

- [ ] **T-cleanup-8** `class CheckQuestion`'s `icon_value` (and friends) — verify camelCase rename per T-cleanup-6 applies consistently across the 7 question subclasses.

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Cubit test: `AddQuetsion` then `RemoveQuestion` on same question id → category should be removed from `categoriesToSend` when empty.
- [ ] **T-test-2** [P] [US1] Repo test: `sendQuestions` builds the correct `fields[N][...]` form data for a mixed-type category (text + image + select).
- [ ] **T-test-3** [P] [US3] Defensive `Question.fromJson` test: unknown type → null; null `json` → null; missing `question_type` → null; well-formed → typed instance.
- [ ] **T-test-4** [P] [US2] Repo test: activities returned in date-desc order regardless of server order.

---

## Notes

- This migration **did not exhaustively read all 68 files** — widget-level details (e.g., per-widget hardcoded strings, theming drift) may surface in a follow-up audit. The bloc, repo, key models, and one screen are covered.
- The catch-all event handler pattern is shared with chat ([chat T-fix-2](../chat/tasks.md)) and is a candidate for a project-level refactor pass rather than per-feature.
- The typo'd filesystem identifiers (T-cleanup-7) accumulate cost over time; consider batching with the [features.md cross-feature task](../features.md#cross-feature-tasks) about renaming `terms_and_condtions/` and similar.
