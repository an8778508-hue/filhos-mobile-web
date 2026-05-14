---
status: migrated
feature: diary
flavor_scope: both
migrated_from: specs/features.md#diary--b
migrated_date: 2026-05-14
---

# Feature Specification: Diary

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/diary/](../../lib/features/diary/) (68 .dart files) and [features.md#diary--b](../features.md#diary--b).

## Flavor Scope

- **Target flavor(s)**: both, with opposite roles:
  - **Teachers (write)** — compose typed-question reports per school day, addressed to a `SchoolItem` (one of: `allChild`, `level`, `classType`, `childType`). UI lives under [presentation/school_items_screen.dart](../../lib/features/diary/presentation/school_items_screen.dart) and [presentation/dairy_screen.dart](../../lib/features/diary/presentation/dairy_screen.dart) (typo'd filename — `dairy` not `diary`).
  - **Parents (read)** — read the same typed answers as a timeline of activities per child. UI lives under [presentation/parents_diary_screen.dart](../../lib/features/diary/presentation/parents_diary_screen.dart).
- **Flavor-conditional behavior**: separate top-level screens; bloc is shared. `_handleQuestionsTemplates` uses `getCategoryTemplats` (teacher-side schema) — parents call `getActivities` which returns *answered* questions. Different code paths, same `DiaryBloc`.
- **Server role implication**: endpoint paths differ by role:
  - Parents → `/parent/timeline/view`, `parent/children/menus`, `parent/children`
  - Teachers → `teacher/questions`, `teacher/questions/answers`, `/teacher/questions/data`
  - Shared → `/files/upload`

## User Scenarios & Testing

### User Story 1 — Teacher: compose and send a typed diary entry (Priority: P1) 🎯 MVP

A teacher opens the diary tab, picks a target (a child, class, level, or "all"), selects a category template, fills in typed questions (rating, checkbox, image, duration, number, select, free-text), and submits.

**Why this priority**: Core daily-use surface for teachers; every parent-side activity is downstream of this.

**Independent Test**: Open as `professores` flavor. `GetSchoolItems` fires → list of `SchoolItem`. Pick one → `GetQuestionTemplates` → templates render. Add answers → `AddQuetsion` updates the in-bloc `categoriesToSend` map. Submit → `SendQuestionsToApi` posts multipart to `teacher/questions/answers`.

**Acceptance Scenarios**:

1. **Given** a teacher opens the diary editor, **When** the screen mounts, **Then** `GetSchoolItems` and `GetQuestionTemplates` fire and the templates and roster render.
2. **Given** a teacher answers a `rating` question, **When** they tap a star, **Then** `AddQuetsion` updates `categoriesToSend[categoryId].questions` (insert if new, replace if same question id).
3. **Given** a teacher attaches images to an `image` question, **When** they submit, **Then** [_uploadImagesAndSetUrls](../../lib/features/diary/presentation/bloc/diary_bloc.dart#L170-L202) converts local paths to `MultipartFile`s in-place on the `ImagesQuestion.value` before `sendQuestions`.
4. **Given** the user removes a question, **When** `RemoveQuestion` fires, **Then** the question is dropped from `categoriesToSend[categoryId].questions`; if the category empties, it's removed from `categoriesToSend`.
5. **Given** submission succeeds, **When** the API returns `Right(void)`, **Then** `SendQuestionsSucceed` emits and the teacher is bounced out of the editor.
6. **Given** the teacher targets "all children" (`SchoolItemType.allChildType`), **When** the request is composed, **Then** `typeable_id` is omitted from the form data and `typeable_type` is also `null` (server interprets as broadcast).
7. **Given** the teacher filters templates for media-only or attendance-only, **When** `GetQuestionTemplates(filterAttendance: true)` or `(filterMedia: true)` fires, **Then** the returned templates are pre-filtered client-side by `type == 'attendence'` or by presence of `QuestionType.image`.

### User Story 2 — Parent: read the daily timeline (Priority: P1)

A parent opens the diary tab, picks one of their children, picks a date, and reads the typed answers as a structured activity timeline.

**Acceptance Scenarios**:

1. **Given** a parent opens the screen for child X on date D, **When** `GetDiaryActivities(date, childId)` fires, **Then** the bloc calls `parent/timeline/view?date=…&child_id=…` and renders `Activity` cards.
2. **Given** the parent scrolls activities, **When** the response arrives, **Then** activities are **sorted by date desc** before rendering. ⚠️ Sort runs inside the parse loop ([diary_impl.dart:42-45](../../lib/features/diary/data_sources/diary_impl.dart#L42-L45)) → O(n² log n). Bug — see [tasks.md T-cleanup-2](tasks.md).
3. **Given** a parent picks the menu tab, **When** `GetMenus(date, childId)` fires, **Then** the bloc calls `parent/children/menus` and renders per-child menus.

### User Story 3 — Tolerant question parsing (Priority: P1)

A single backend-added question type, malformed entry, or null answer must not blank the entire screen.

**Acceptance Scenarios**:

1. **Given** a response containing one question with an unknown `type`, **When** `Question.fromJson` parses, **Then** that single question is silently skipped (`return null`) and surrounding questions render — verified by `whereType<Question>()` filter in `QuestionCategory.fromJson`. *Fixed 2026-05-14, see [features.md#diary--b](../features.md#diary--b)*
2. **Given** the typo'd payload `json['age(']`, **When** the model parses, **Then** it correctly reads `json['age']`. *Fixed 2026-05-14*
3. **Given** a `QuestionCategory` with no `answers`, **When** parsing, **Then** `questions` defaults to `[]` instead of throwing.

### Edge Cases

- **Hardcoded `childId: 1` in `_handleQuestionsTemplates`** ([diary_bloc.dart:209](../../lib/features/diary/presentation/bloc/diary_bloc.dart#L209)) — the template fetch always queries for child id 1 regardless of which child the teacher is composing for. Hidden bug. See [tasks.md T-fix-2](tasks.md).
- **`getMessageContent` / `getSelectedItemValue` for images** is value-list-aware but for single-value questions returns `[getValue(value)]` (length-1 list) — the form data writer iterates this list as if it were a multi-image list. Works because non-image questions enter a different branch.
- **Idempotency** — `sendQuestions` has no `idempotency_key` / `request_id`. A retry after a network blip can double-write answers. [features.md (P1)](../features.md#diary--b).
- **Fresh `Dio()` in `share_button.dart`** ([presentation/widgets/gallery_media/share_button.dart](../../lib/features/diary/presentation/widgets/gallery_media/share_button.dart)) bypasses `NetworkClient` interceptors (auth, school headers, Crashlytics, 401 handler). [features.md P1](../features.md#diary--b).
- **`SchoolItemType.allChildType`** — string `null` vs missing `typeable_type` distinction; the helper returns `null` and the form data emits no key. Server side must treat absent as broadcast.
- **Two enum values `textarea` and `textfield`** both map to `QuestionType.textarea` in `StringExtension.toQuestionType()`. The `case 'textfield': return QuestionType.textarea;` line means `textfield` is effectively dead. See [tasks.md T-cleanup-1](tasks.md).
- **Approval gate**: diary is reached only from `MainScreen` (post-gate). ✓
- **`activities.sort` in loop**: see User Story 2.
- **Hardcoded `child_id: 1`**: see edge case above.

## Requirements

### Functional Requirements

- **FR-001 (T)**: System MUST list `SchoolItem` (level / class / child / all-children) options for the teacher's compose target.
- **FR-002 (T)**: System MUST fetch typed `QuestionCategoryTemplate`s with optional filters `filterAttendance` and `filterMedia` from `teacher/questions`.
- **FR-003 (T)**: System MUST support 7 question types: `checkbox`, `rating`, `textarea`/`textfield`/`text`/`email` (all map to `InfoQuestion`), `duration`, `image`, `number`, `select`.
- **FR-004 (T)**: System MUST submit answers as multipart form data to `teacher/questions/answers` with fields indexed `fields[N][...]`, including `timeline_category_id`, `id`, `type`, `is_image`, optional `type_status`, optional `metadata[*]`, and `value` (or `value[]` for images).
- **FR-005 (T)**: System MUST embed local image paths as `MultipartFile`s on the same `sendQuestions` request; the `/files/upload` endpoint is declared on the contract but **unused by the current send path**. See [tasks.md T-cleanup-3](tasks.md).
- **FR-006 (P)**: System MUST fetch `Activity` timeline from `parent/timeline/view` keyed by `{date, child_id}` and render sorted by `date` desc.
- **FR-007 (P)**: System MUST fetch per-child `ChildMenuModel` from `parent/children/menus`.
- **FR-008**: System MUST tolerate unknown / malformed question types — `Question.fromJson` returns `null`; the parent `QuestionCategory.fromJson` filters via `whereType<Question>()`.
- **FR-009**: System MUST persist `categoriesToSend` in-bloc state (`Map<int, QuestionCategory>`) across screen rebuilds inside the same teacher compose session. State is **not** persisted across cold start.

### Localization Requirements

Diary-specific keys live in `localization_keys.dart` + pt/en/ar JSONs. No new keys required by this migration. The 68 .dart files were not exhaustively read for hardcoded strings — assume some debug copy is hardcoded (raw `debugPrint`s, e.g., the `'===== SENDING QUESTIONS REQUEST ====='` cluster at [diary_impl.dart:290-301](../../lib/features/diary/data_sources/diary_impl.dart#L290-L301)).

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET /parent/timeline/view?date=&child_id=` — parents read
  - `GET parent/children/menus?date=&child_id=` — parents menus
  - `GET parent/children` — parents search (delegated to `SearchRepo`)
  - `GET teacher/questions` — teacher templates
  - `GET /teacher/questions/data` — teacher diaryItems (school levels, classes, children)
  - `POST teacher/questions/answers` — teacher submit (multipart)
  - `POST /files/upload` — declared, **unused** today
- **No Firestore**.
- **No FCM** directly (push deep-links of type `diary` / `FieldAnswer` route to `DiaryScreen` via `NotificationHelper`).

### Permissions & Approval Gate

- Reached only post-approval (from `MainScreen`). ✓
- Device permissions: **Camera / Photos / Storage** for image questions (flow through `lib/core/attachment_selection/`).

### Key Entities

- **`Activity`** ([activities.dart](../../lib/features/diary/models/activities.dart)) — a parent-side timeline item: child, professor, date, `MainCategory`, list of answered `QuestionCategory`.
- **`MainCategory`** ([main_category.dart](../../lib/features/diary/models/main_category.dart)) — top-level domain (e.g., "Food", "Mood"). `{id, name, image, type, value (attendance_type), statusType}`.
- **`QuestionCategory`** ([question_category.dart](../../lib/features/diary/models/question_category.dart)) — intermediate grouping holding typed `Question`s + reaction counts (`count_love`, `count_wow`, etc.) + `icon_value`. ⚠️ snake_case field names in Dart (`count_love`); should be camelCase.
- **`Question` (sealed-ish)** — abstract base + 7 concrete subclasses ([questions_models/](../../lib/features/diary/models/questions_models/)). Tolerant `fromJson` factory at [question.dart:32-133](../../lib/features/diary/models/questions_models/question.dart#L32-L133).
- **`SchoolItem`** ([school_item.dart](../../lib/features/diary/models/school_item.dart)) — `{id, type: level/classType/childType/allChildType, ...}` — the compose target.
- **`QuestionCategoryTemplate`** ([tamplets/question_category_template.dart](../../lib/features/diary/models/tamplets/question_category_template.dart)) — ⚠️ typo'd directory name: `tamplets` should be `templates`.
- **`ChildMenuModel`** ([child_menu_item.dart](../../lib/features/diary/models/child_menu_item.dart)) — menu items per child.

## Success Criteria

- **SC-001 (T)**: A teacher can compose and submit a diary entry covering 5 categories (mixed types) in under 3 minutes; the parent sees it within 5 seconds of the FCM push.
- **SC-002 (P)**: Parents can scroll a full day's timeline (typical 5–10 activities) at 60 fps.
- **SC-003**: A backend that adds a new `QuestionType` value not yet known to the client doesn't blank the diary screen — unknown questions are silently dropped.
- **SC-004**: A retried `sendQuestions` after a network blip does **not** double-write — currently violated; see [tasks.md T-fix-1](tasks.md).

## Assumptions

- The server's `teacher/questions/answers` endpoint accepts multipart form data with `fields[N][...]` nesting; arrays use `[]` suffix on the same key (`value[]` for image files).
- Image quality is enforced server-side; client does not compress before upload (same as chat — see [chat tasks T-fix-5](../chat/tasks.md)).
- `categoriesToSend` not persisting across cold start is acceptable — teachers complete a compose in one sitting.
- The `/files/upload` endpoint is reserved for a future flow (e.g., image-first then reference); not used today.
