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

---

# Enhancement Plan: 2026-05-15 Competitive Pass (FR-EN-01 … FR-EN-37)

**Date**: 2026-05-15 | **Spec scope**: [spec.md Clarifications 2026-05-15](spec.md#clarifications) + FR-EN-01 … FR-EN-37 + SC-EN-01 … SC-EN-10 | **Phase 0/1 artifacts**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md)

## Summary

Five competitive-parity enhancement areas layered on the existing 68-file diary feature. The pre-spec-kit baseline (US1–US3, FR-001…FR-009) is **done** and treated as fixed context. This plan sequences only the new scope plus the three pre-existing P0/P1 fixes the new scope structurally depends on.

| Area | FR range | New surface | Backend? |
|---|---|---|---|
| A — Reactions & comments | FR-EN-01…07 | Firestore-backed social layer on `Activity` cards | Firestore rules + admin web |
| B — Save-as-draft (hybrid) | FR-EN-08…13 | HydratedBloc/Hive local + 3 REST endpoints | `PUT/GET/DELETE /teacher/questions/draft` |
| C — Soft-delete + resend | FR-EN-14…20 | Retract CTA + ghost-line + audit | `DELETE /teacher/questions/answers/{id}` + carry-over job |
| D — Voice + video question types | FR-EN-21…30 | `AudioQuestion` + `VideoQuestion` | Server transcode + storage lifecycle |
| E — Read receipts (aggregate) | FR-EN-31…37 | Aggregate label teacher-side | `POST /parent/timeline/read` + aggregate field |

## Dependency-ordered sequencing

The areas are **not** independent. This is the critical-path order:

```text
P0/P1 prereqs (must land first — they are structural foundations, not optional cleanup)
 ├─ T-fix-1  idempotency_key on sendQuestions ──────────────┐ (drafts + retract both need dedupe)
 ├─ T-fix-4  replace catch-all on<DiaryEvent> with typed ───┤ (new events would worsen the dispatcher)
 └─ T-fix-3  kill fresh Dio() in share_button ──────────────┘ (media area touches the same widget tree)
        │
        ▼
Wave 1  Area D (voice/video question types)   ── extends the Question hierarchy; lowest coupling to others
        │
        ▼
Wave 2  Area B (save-as-draft)                ── depends on T-fix-1 idempotency; touches compose state
        │
        ▼
Wave 3  Area C (soft-delete + resend)         ── depends on T-fix-1 + Area B (draft lifecycle interplay) + AABAR consent model
        │
        ▼
Wave 4  Area A (reactions + comments)         ── new Firestore surface; depends on Area C (carry-over on resend)
        │
        ▼
Wave 5  Area E (read receipts)                ── depends on Area C (label hides on retract) + Area A (Firestore patterns reused)
```

**Rationale**: D is the cleanest extension (just new `Question` subclasses + capture/playback reuse from chat) — ship it first to validate the enhancement-flag rollout machinery (T-EN-X2) on low-risk scope. B before C because C's resend must reconcile with B's draft lifecycle. A after C because reaction/comment carry-over (FR-EN-16) is defined relative to the retraction window. E last because its retraction-hide behavior (FR-EN-36) and Firestore patterns reuse A and C.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (unchanged)

**New/affected dependencies**:

- `cloud_firestore` — NEW for diary (Areas A; constitution tension, see Constitution Check). Already in the app for chat.
- `record` + `flutter_sound` + `just_audio` — reused from chat for `AudioQuestion` (Area D). No new dep.
- `video_player` (stock) — for `VideoQuestion` playback (Area D). Per [system.md §1](../system.md#1-stack-snapshot), `appinio_video_player_plus` is removed; use stock `video_player`. **Constitution drift**: [constitution.md Technology Stack line 96](../../.specify/memory/constitution.md) still lists `appinio_video_player_plus` — flag for amendment, not a blocker here.
- Native camera capture for video — `image_picker` already supports `pickVideo`; evaluate vs a dedicated recorder in [research.md](research.md).
- `hydrated_bloc` / `LocalDatabaseRepo` — Area B local draft persistence. Must go through `LocalDatabaseRepo` per Principle IV (new box key needed).

**Storage**:

- Area B introduces a new local persistence need. Decision in [research.md](research.md): new Hive box key `diary_drafts` via `LocalDatabaseRepo` (NOT HydratedBloc — drafts are keyed collections, not a single bloc state blob).
- Areas A: Firestore collections `diary_reactions/{activity_id}/users/{user_id}` and `diary_comments/{activity_id}/comments/{auto_id}`.
- Area D: Firebase Storage `diary_media/{school_id}/{teacher_id}/{activity_id}/{type}/{auto_id}` with a 90-day post-retraction lifecycle.

**Testing**: No `test/` dir today (Quality Gate exception still active). FR-EN test suite is aspirational (T-EN-X4); not a blocking gate.

**Performance Goals** (from SC-EN):

- Local draft write ≤ 200 ms keystroke→persisted (SC-EN drives FR-EN-08).
- Audio/video first-play under 4 s on BR 4G/5G (SC-EN-08).
- Reaction tap → optimistic UI < 100 ms; Firestore confirm async.

**Constraints**:

- Reaction/comment writes must be optimistic-UI + Firestore-confirmed (mirror chat's send pattern).
- Draft sync conflict = last-write-wins + soft warning (FR-EN-11) — no operational-transform / CRDT.
- Soft-delete retains rows 90 days (LGPD parity with [aabar/spec.md FR-021a](../aabar/spec.md)).

**Scale/Scope**: +~25-35 new .dart files estimated (2 question types + their widgets, reactions/comments widgets + Firestore service, draft repo + sync, retract flow, receipt instrumentation). Net new REST endpoints: 4. Net new Firestore collections: 2.

## Constitution Check (post-design)

- [x] **I. Feature-First Layout** — all new code under `lib/features/diary/`. New Firestore service goes in `lib/features/diary/data_sources/diary_social_service.dart` (feature-local, not core, since it's diary-specific). ✓
- [x] **II. Dependency Direction** — diary already has feature-root `diary_di.dart`; new repos/services register there. No new cross-feature imports beyond the already-accepted `search`/`chat`/`notifications` touchpoints. ✓
- [⚠️] **III. Networking Contract** — 4 new REST endpoints (`PUT/GET/DELETE /teacher/questions/draft`, `DELETE /teacher/questions/answers/{id}`, `POST /parent/timeline/read`) MUST route through `NetworkClient.handleRequest`. **Hard dependency on T-fix-3** (the fresh `Dio()` in `share_button.dart` must be killed first — Area D touches the same gallery_media widget tree and would otherwise propagate the anti-pattern). Gate passes **conditional on T-fix-3 landing in the P0/P1 prereq wave**.
- [x] **IV. Persistence Discipline** — Area B uses a NEW Hive box key `diary_drafts` accessed **only** through `LocalDatabaseRepo` (extend its schema; do not touch Hive directly). HydratedBloc explicitly rejected for drafts (keyed collection, not single-blob bloc state) — rationale in [research.md](research.md). ✓
- [⚠️] **VII. Chat Source of Truth** — Principle VII says Firestore is the chat source of truth and forbids a *parallel REST chat path*. Areas A add **non-chat** Firestore usage (reactions/comments on diary entries). This is not a violation of the letter (no parallel chat path; no REST chat) but it **expands Firestore's role beyond chat**. Recorded in Complexity Tracking as a deliberate, justified choice (real-time reaction counts + comment threads need a realtime store; REST polling would be strictly worse UX and load). **Recommend a constitution amendment** to generalize VII from "chat source of truth" to "realtime social surfaces (chat, diary reactions/comments) are Firestore-backed; no parallel REST realtime path." Flagged, not blocking.
- [x] **V. Flavor Branching** — reactions/comments/receipts have flavor-conditional behavior (teacher sees aggregate label + comment-delete; parent sees reaction picker). Use `context.isParents`/`context.isProfessors`. No string compares. ✓
- [x] **VI. Localization** — all new strings already enumerated in [spec.md Localization Requirements](spec.md). PT primary; EN inline; AR TBD (tracked, non-blocking per existing discipline). ✓
- [x] **VIII. Approval Gate** — FR-EN-06 explicitly gates comments on `isApproval`. Retract/receipt surfaces are post-gate (diary itself is post-gate). ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — new widgets MUST pull colors from `ConfigCubit.styling`; no hardcoded `Color(0xff…)`. Reaction emoji are unicode/asset, not themed. 430×932 screenutil. ✓

**Gate result**: PASS, conditional on the P0/P1 prereq wave (T-fix-1, T-fix-3, T-fix-4) landing before Wave 1. One recommended amendment (Principle VII generalization) flagged as non-blocking.

## Project Structure (new/changed files)

```text
lib/features/diary/
├── data_sources/
│   ├── diary_repo.dart                 # + 4 endpoint constants (draft x3, retract)
│   ├── diary_impl.dart                 # + draft sync, retract, read-receipt calls (via NetworkClient)
│   ├── diary_draft_repo.dart           # NEW — local+remote draft contract (Area B)
│   ├── diary_draft_impl.dart           # NEW — Hive-via-LocalDatabaseRepo + REST sync
│   └── diary_social_service.dart       # NEW — Firestore reactions/comments (Area A)
├── models/
│   ├── questions_models/
│   │   ├── audio_question.dart         # NEW (Area D)
│   │   └── video_question.dart         # NEW (Area D)
│   ├── diary_reaction.dart             # NEW (Area A)
│   ├── diary_comment.dart              # NEW (Area A)
│   ├── diary_draft.dart                # NEW (Area B)
│   └── diary_read_receipt.dart         # NEW (Area E — aggregate model)
└── presentation/
    ├── bloc/
    │   ├── diary_bloc.dart             # typed handlers (T-fix-4) + new events
    │   ├── diary_event.dart            # + React/Comment/SaveDraft/Retract/MarkRead events
    │   └── diary_state.dart            # + draft/reaction/comment/receipt slices
    └── widgets/
        ├── questions/
        │   ├── audio_question_widget.dart   # NEW capture+playback (Area D)
        │   └── video_question_widget.dart   # NEW capture+playback (Area D)
        ├── social/
        │   ├── reaction_bar.dart            # NEW (Area A)
        │   ├── comment_thread.dart          # NEW (Area A)
        │   └── report_abuse_sheet.dart      # NEW (Area A)
        ├── retract_action.dart              # NEW (Area C)
        ├── retracted_ghost_line.dart        # NEW (Area C)
        └── read_receipt_label.dart          # NEW (Area E)

lib/core/local_db/                            # extend schema with `diary_drafts` box key (Area B)
```

## Complexity Tracking (enhancement-specific)

| Decision | Why needed | Rejected alternative |
|---|---|---|
| Firestore for diary reactions/comments (expands Principle VII scope) | Real-time counts + threaded comments need a realtime store; mirrors the working chat pattern; offline queueing for free | REST polling — strictly worse UX, heavier backend load, no realtime. Rejected. |
| New `diary_drafts` Hive box (not HydratedBloc) | Drafts are a keyed collection per `(target,date)`, not a single bloc-state blob; HydratedBloc serializes one state object | HydratedBloc — would force the whole DiaryState to round-trip; collides with the in-memory compose model. Rejected. |
| Soft-delete + resend instead of in-place edit | Locked clarification Q3 — avoids malicious-edit trust failure; carry-over window keeps engagement | In-place edit with audit badge — rejected in clarification. |
| `idempotency_key` (T-fix-1) elevated from P1 cleanup to a **prereq** | Drafts (FR-EN-13) and retract/resend (FR-EN-14…17) both structurally need server-side dedupe; building them on a non-idempotent submit would bake in the double-write bug | Deferring T-fix-1 — rejected; it's load-bearing for two of the five areas. |
| Stock `video_player` over `appinio_video_player_plus` (constitution stack drift) | The constitution-listed package is removed (Flutter 3.27+ break, [system.md §1](../system.md#1-stack-snapshot)) | Re-adding the removed package — rejected; it doesn't build on web and is abandoned. Constitution amendment recommended. |
