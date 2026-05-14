---
status: migrated
feature: diary
migrated_from: lib/features/diary/
migrated_date: 2026-05-14
---

# Implementation Plan: Diary

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

68 .dart files — most complex domain in the codebase. Typed-question schema (`MainCategory` → `QuestionCategory` → 7 concrete `Question` subclasses), per-role read/write split (parents read activities; teachers compose), and multipart-form image uploads embedded in the same submit request. P0 hardening from [review.md](../review.md) (tolerant `fromJson`, null-filter, typo fix) already landed; remaining P1 work centers on idempotency, the catch-all event handler (same anti-pattern as chat), and several pieces of dead / commented-out code.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `flutter_bloc` 9.1 — `DiaryBloc` is a real `Bloc<DiaryEvent, DiaryState>` (catch-all dispatcher)
- `dio` 5.8 via [NetworkClient](../../lib/core/network/network_client.dart); `dio.FormData` + `MultipartFile` for multipart submits
- `equatable` 2.0
- `dartz` — `Either<Failure, T>`
- `flutter_screenutil` 5.9
- `image_picker` 1.1 (image questions) via `lib/core/attachment_selection/`
- `table_calendar` 3.1 — date picker on the parents-side timeline

**Storage**: `LocalDatabaseRepo` injected into `DiaryBloc` but **not actively read** from (the in-memory `categoriesToSend` map drives the compose session). HydratedBloc not used.

**Testing**: None.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Largest single-feature in the repo; clear `data_sources/`, `models/{models, questions_models, tamplets}/`, `presentation/{bloc, widgets/{gallery_media, professor_questions, questions, ...}}` split.

**Performance Goals**:

- Parents timeline scroll at 60 fps for typical day (~10 activities).
- Teacher submit ≤ 2 s for text-only categories; image uploads gated by network.

**Constraints**:

- Bloc keeps long-lived `categoriesToSend` state across rebuilds within a compose session.
- Image questions hold local file paths in `value` until submit, when they're swapped to `MultipartFile`s in-place by `_uploadImagesAndSetUrls`.
- `sendQuestions` is **not idempotent**.

**Scale/Scope**: 68 .dart files, ~2500 LOC across bloc/widgets. 7 REST endpoints. 7 question types.

## Constitution Check

- [x] **I. Feature-First Layout** — code under `lib/features/diary/` with the standard split. ⚠️ Directory name typo: `models/tamplets/` should be `templates/`. Accepted as-is (rename is project-wide cost).
- [x] **II. Dependency Direction** — feature-root [diary_di.dart](../../lib/features/diary/diary_di.dart) ✓. Cross-feature import from `search` (`SearchRepo`) is acceptable per [constitution principle II](../../.specify/memory/constitution.md) as `search` is a shared service.
- [x] **III. Networking Contract** — all REST calls go through `NetworkClient.handleRequest` returning `Either<Failure, T>`. ⚠️ One known exception: [share_button.dart:87](../../lib/features/diary/presentation/widgets/gallery_media/share_button.dart#L87) constructs a fresh `Dio()` that bypasses interceptors. See [tasks.md T-fix-3](tasks.md).
- [x] **IV. Persistence Discipline** — N/A (no Hive direct, no HydratedBloc; compose state is in-memory). ✓
- [x] **V. Flavor Branching** — no `mainKey.currentContext` usage. Top-level screens split by flavor. ✓
- [x] **VI. Localization** — assumed compliant; not exhaustively verified across 68 files. ⚠️ Debug `debugPrint('===== SENDING QUESTIONS REQUEST =====')` cluster at [diary_impl.dart:290-301](../../lib/features/diary/data_sources/diary_impl.dart#L290-L301) is developer-only output, fine but noisy.
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — diary is post-gate. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — assumed compliant; not exhaustively verified across 68 files.

## Project Structure

```text
lib/features/diary/
├── diary_di.dart                              # feature-root DI
├── data_sources/
│   ├── diary_repo.dart                        # abstract contract + 7 endpoint constants
│   ├── diary_impl.dart                        # ⚠️ 200+ lines of commented-out sendQuestions implementations
│   └── static_data.dart                       # mostly commented-out reference data
├── models/
│   ├── activities.dart                        # parents-side timeline item
│   ├── main_category.dart                     # top-level domain
│   ├── question_category.dart                 # categories with typed questions
│   ├── school_item.dart                       # teacher compose target (level / class / child / all)
│   ├── child_model.dart                       # also referenced from chat — candidate to promote to core/models/
│   ├── child_menu_item.dart                   # ChildMenuModel
│   ├── category_menu_item.dart                # menu sub-item
│   ├── professor.dart                         # author of an Activity
│   ├── questions_models/                      # 7 Question subclasses
│   │   ├── question.dart                      # abstract base + tolerant fromJson factory + enum
│   │   ├── check_question.dart
│   │   ├── rating_question.dart
│   │   ├── duration_question.dart
│   │   ├── image_question.dart
│   │   ├── info_question.dart                 # used for textarea/textfield/text/email
│   │   ├── number_question.dart
│   │   └── select_question.dart
│   └── tamplets/                              # ⚠️ typo'd directory name (templates)
│       ├── question_category_template.dart
│       └── question_template.dart
└── presentation/
    ├── dairy_screen.dart                      # ⚠️ typo'd filename (diary)
    ├── parents_diary_screen.dart              # parents-side timeline
    ├── school_items_screen.dart               # teacher target picker
    ├── bloc/
    │   ├── diary_bloc.dart                    # Bloc<DiaryEvent, DiaryState> — catch-all dispatcher
    │   ├── diary_event.dart
    │   └── diary_state.dart
    └── widgets/                               # ~40 widgets
        ├── diary_activites.dart               # ⚠️ typo'd filename (activities)
        ├── diary_calendar.dart
        ├── gallery_media/                     # image questions render gallery
        ├── professor_questions/               # teacher compose UI
        │   └── items_to_send.dart/            # ⚠️ folder name with .dart extension
        ├── questions/                         # parent answer-display widgets
        ├── child_header.dart
        ├── diary_state_handler.dart
        ├── menu_button.dart
        ├── menu_screen.dart
        ├── professor_widget.dart
        ├── question_category_widget.dart
        └── time_range_widget.dart
```

### Cross-feature touch points

- **[lib/features/search/data_sources/search_dc.dart](../../lib/features/search/data_sources/search_dc.dart)** — `SearchRepo` injected into `DiaryBloc`.
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** — `UserBloc.get.state.user?.id` for `teacherId`.
- **[lib/core/utils/safe_x.dart](../../lib/core/utils/safe_x.dart)** — `safeFirstWhere` extension used in `_handleAddQuestion`.
- **[lib/features/chat/](../../lib/features/chat/)** — shares `ChildModel`.
- **[lib/features/notifications/](../../lib/features/notifications/)** — push types `diary` / `FieldAnswer` deep-link to `DiaryScreen`.

**Structure Decision**: Standard layout with several typo'd identifiers (filename `dairy_screen.dart`, directory `tamplets/`, folder `items_to_send.dart/`). Rename is project-wide cost; accepted for now and flagged in cleanup.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `on<DiaryEvent>` catch-all dispatcher in [diary_bloc.dart:37-53](../../lib/features/diary/presentation/bloc/diary_bloc.dart#L37-L53) | Same legacy as chat — predates ergonomic typed handlers. | Typed `on<Specific>` handlers with `droppable()` on `SendQuestionsToApi` would prevent double-submits. ([features.md P1](../features.md#diary--b)). See [tasks.md T-fix-4](tasks.md). |
| `sendQuestions` lacks `idempotency_key` / `request_id` | Original implementation didn't anticipate retries. | A `--retry-id` style header or body field would let the server dedupe. [features.md (P1)](../features.md#diary--b). See [tasks.md T-fix-1](tasks.md). |
| 200+ lines of commented-out `sendQuestions` implementations in [diary_impl.dart](../../lib/features/diary/data_sources/diary_impl.dart#L99-L208) | Three iterations of the same method left as history. | Delete; git log preserves the history. See [tasks.md T-cleanup-1](tasks.md). |
| Hardcoded `child_id: 1` in `_handleQuestionsTemplates` | Bug — templates fetched ignoring the actual child. | Pass the child from the calling screen through to `GetQuestionTemplates`. See [tasks.md T-fix-2](tasks.md). |
| `activities.sort` runs inside the per-activity loop | Accidental — sort was meant to run once after the loop. | Pull `sort` after the loop completes (O(n log n) instead of O(n² log n)). See [tasks.md T-cleanup-2](tasks.md). |
| `/files/upload` endpoint declared on contract but unused | Reserved for a future flow. | Either implement the upload-then-reference pattern (smaller submit body, retriable image uploads) or remove the contract method. See [tasks.md T-cleanup-3](tasks.md). |
| `QuestionType.textarea` and `QuestionType.textfield` both map to `textarea` in the extension | `textfield` was anticipated as a distinct UI but never wired. | Drop `textfield` from the enum — its `case` already returns `textarea`. See [tasks.md T-cleanup-4](tasks.md). |
| Verbose `debugPrint('===== SENDING QUESTIONS REQUEST =====')` cluster | Development aid. | Route through a structured logger that drops in release. Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about 146 print calls. See [tasks.md T-cleanup-5](tasks.md). |
