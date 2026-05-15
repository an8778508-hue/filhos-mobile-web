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

## Clarifications

### Session 2026-05-15 — competitive enhancement pass

> Pass focused on closing competitive gaps versus iCare Kids and InstaKidz (see [business.md §9](../business.md#9-competitive-landscape)) and on the diary value-add layer locked in [business.md §5.1.1](../business.md#511-diary-value-add-planned). New requirements flowing from each answer are appended to **Requirements → Functional Requirements** with the `FR-EN-NN` prefix (EN = "enhancement").

- Q: What goes on a diary entry on the parent-facing read side? → A: **Reactions + free-form comments, both**. Firestore-backed (mirroring [chat](../chat/) schema). Comment moderation in v1 is report-abuse-flag only; full moderation pipeline deferred to v2. Closes the InstaKidz social-feed gap.
- Q: How should "save as draft" for teachers persist? → A: **Hybrid — local-first with periodic server sync**. Drafts are kept in HydratedBloc/Hive for low-latency typing (≤ 200ms between keystroke and persisted-locally), then synced to the server every N seconds of idle (or on app background). Server is the source of truth for cross-device — a teacher who drafts on a tablet finishes on their phone. Sync conflicts resolved by last-write-wins with a soft warning ("Esta minuta foi atualizada em outro dispositivo às {time}. Substituir?"). Closes the iCare "draft over the day" gap.
- Q: How does edit-after-send work? → A: **Soft-delete + resend** with a server-side audit trail. There is no in-place edit. The teacher retracts the entry (it leaves the parent's active timeline) and submits a new entry. Parents see a small ghost-line "Atividade removida pelo professor às {time}" on the timeline for 24h after the retraction (then disappears entirely). Reactions and comments on the retracted entry are transferred to the replacement entry **if the same teacher resends within 24h for the same `(child, date, MainCategory)` triple**; otherwise dropped with a notice. Avoids "edited" badges (high-trust failure if a teacher edits maliciously) at the cost of a slightly louder UX moment.
- Q: What multimedia gets added to diary in v1.x? → A: **Voice + short video, both**. New question types `AudioQuestion` (≤ 60s clips, reusing the existing chat audio capture infrastructure — `flutter_sound` + `record`) and `VideoQuestion` (≤ 30s clips, server-side transcoded to a uniform mp4/h.264 profile for consistent parent-side playback). Voice unlocks teachers' "não tive tempo de digitar" moments at near-zero incremental cost; video is the visible InstaKidz-parity feature. Bandwidth: client compresses before upload (audio: AAC 64 kbps; video: 720p target before server re-encode).
- Q: Where do read receipts appear in v1.x? → A: **Teacher sees aggregate only; per-family detail in admin web** (admin web is out of mobile scope). Aggregate label on the teacher's view of each `Activity` card: "Visto por {X} de {Y} famílias" — where Y is the number of distinct parent accounts linked to the targeted children. No per-parent names in mobile. Avoids "Maria didn't read it" pressure on individual families while still proving engagement to the school. Parents do not see receipts back. Closes iCare's "engagement analytics" gap for procurement narratives.

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

#### Competitive Enhancements (v1.x — from 2026-05-15 clarification pass)

These requirements are NEW for the diary feature, not part of the migrated baseline. They close gaps versus iCare and InstaKidz (see [business.md §9](../business.md#9-competitive-landscape)).

##### Reactions & comments on diary entries (closes InstaKidz social-feed gap)

- **FR-EN-01 (P)**: System MUST allow a parent to react to a parent-side `Activity` card with one or more of a fixed reaction set: ❤️ `heart`, 👏 `clap`, 🥹 `saudades`, 😂 `laugh`, 🙏 `thanks`. One parent can leave at most one of each reaction per `Activity`.
- **FR-EN-02 (P)**: System MUST allow a parent to post a free-form text comment on a parent-side `Activity` card. Comments are visible to the authoring parent, the assigned teacher, and any other parent linked to the same child.
- **FR-EN-03 (T)**: System MUST surface reaction counts and comment threads on the teacher-side view of the entry (the same `Activity` they composed) so teachers can see how parents responded.
- **FR-EN-04**: Reactions and comments MUST be stored in Firestore mirroring the [chat](../chat/) schema. Path convention: `diary_reactions/{activity_id}/users/{user_id}` for reaction docs; `diary_comments/{activity_id}/comments/{auto_id}` for comment docs.
- **FR-EN-05**: Every comment MUST surface a "report abuse" affordance that flags the comment server-side. v1 moderation is **flag-and-review** only — the comment stays visible until a school admin reviews. Full moderation pipeline (word filter, auto-hide on N flags, mute-author) deferred to v2.
- **FR-EN-06**: Comments MUST honor the same approval gate as the rest of the app. A parent with `isApproval == false` cannot read or post comments on any `Activity`.
- **FR-EN-07**: Teachers MUST be able to delete any comment on an entry they authored; school admins MUST be able to delete any comment (admin scope is server-rule, not app UI).

##### Save-as-draft for teachers (closes iCare "draft over the day" gap)

- **FR-EN-08 (T)**: System MUST persist the teacher's in-progress `categoriesToSend` map to local storage (HydratedBloc or Hive) within 200 ms of every typed-question state change. Survives app kill on the same device.
- **FR-EN-09 (T)**: System MUST sync the local draft to a server-side endpoint (e.g., `PUT /teacher/questions/draft`) keyed by `(teacher_id, target_id, target_type, target_date)` after N seconds of typing idleness (default: 5 s) and on app background.
- **FR-EN-10 (T)**: On opening the diary editor for a `(target, date)` combination, system MUST `GET /teacher/questions/draft?target_id=&target_type=&date=` and merge the server draft into local state if the server draft's `updated_at` is newer than the local draft's.
- **FR-EN-11 (T)**: When the server draft's `updated_at` is newer than the local draft's, system MUST surface a soft warning to the teacher ("Esta minuta foi atualizada em outro dispositivo às {time}. Substituir?") before overwriting their local state. Default action is "Sim, substituir" (last-write-wins); the explicit confirmation prevents silent data loss.
- **FR-EN-12 (T)**: When the teacher submits via `sendQuestions`, the system MUST `DELETE /teacher/questions/draft?target_id=&target_type=&date=` server-side and clear the local draft, so the same `(teacher, target, date)` triple cannot be re-submitted by an offline replay.
- **FR-EN-13 (T)**: Drafts MUST inherit the same `idempotency_key` requirement as `sendQuestions` (see [FR-EN-14 / tasks.md T-fix-1](tasks.md)) — a draft synced and a final submit with the same idempotency_key MUST resolve to a single server-side write.

##### Soft-delete & resend (replaces in-place edit; high-trust recovery)

There is NO in-place edit of a submitted diary entry. To correct a sent entry, the teacher retracts it and resends.

- **FR-EN-14 (T)**: Teachers MUST be able to retract any `Activity` they authored. A retract action issues `DELETE /teacher/questions/answers/{activity_id}` which performs a server-side **soft-delete** (sets `retracted_at`, retains the row for audit/LGPD windows).
- **FR-EN-15 (P)**: A retracted `Activity` MUST disappear from the parent's active timeline immediately. For 24 hours after retraction the parent sees a small ghost-line in its place: "Atividade removida pelo professor às {time}". After 24 h the ghost-line is also removed.
- **FR-EN-16 (T)**: When the same teacher submits a new entry for the same `(child_id, date, MainCategory)` triple within 24 hours of retraction, the server MUST transfer existing reactions and comments from the retracted entry to the new entry, and parents who reacted/commented receive a soft push: "O professor atualizou a atividade. Sua reação foi mantida.". After the 24 h window, reactions and comments are dropped at retraction time with a separate "Atividade removida — sua reação foi excluída" push.
- **FR-EN-17 (T)**: System MUST surface a server-side audit log: every retraction, including who retracted, when, the original `Activity` payload, and (if any) the replacement `Activity` id. The audit log is not visible inside the app in v1 — school admins access it through the web admin.
- **FR-EN-18 (T)**: A teacher MUST NOT be able to retract an `Activity` authored by a different teacher (server enforces). Wrong-child mistakes that cross teacher accounts route to school-admin support — out of scope for the app.
- **FR-EN-19**: Server-side retention of soft-deleted entries MUST follow the project-wide LGPD retention defaults (90 days as established for AABAR — see [aabar/spec.md FR-021a](../aabar/spec.md)), unless legal review requires a longer term for child-safety records.
- **FR-EN-20 (P)**: A retracted entry that was the seed for an open AABAR "Pedir interpretação" conversation does NOT break the AABAR thread — the parent can keep chatting; the agent still has the snapshot it received at consent-tick time. The retraction does not retroactively revoke the AABAR consent token (consent tokens are inherently single-use per [aabar/spec.md FR-015](../aabar/spec.md)).

##### Multimedia in entries: voice + short video (closes InstaKidz richness gap)

- **FR-EN-21 (T)**: System MUST support a new `AudioQuestion` question type. The teacher records via the existing chat audio-capture stack (`flutter_sound` + `record`). Maximum length is **60 seconds** enforced client-side; the recorder shows a remaining-time countdown after 50 s.
- **FR-EN-22 (T)**: System MUST support a new `VideoQuestion` question type. The teacher records via the device's native camera at 720p target resolution; client-side compression caps the upload payload at ~25 MB. Maximum length is **30 seconds** enforced client-side.
- **FR-EN-23 (T)**: The audio capture pipeline MUST encode to AAC 64 kbps mono before upload (chat audio settings reuse). The video pipeline MUST emit `video/mp4` with h.264 baseline profile.
- **FR-EN-24 (T)**: Audio and video questions MUST follow the same multipart-upload contract as `ImageQuestion` (FR-005) — the local file path is converted to a `MultipartFile` and uploaded inline with `sendQuestions`. Out-of-band `/files/upload` is still not required.
- **FR-EN-25 (T)**: Each `AudioQuestion` and `VideoQuestion` slot in a category MUST allow at most one attachment per submit (no carousel). Re-recording REPLACES the local pending attachment before submit. Multiple voice notes per category require multiple `AudioQuestion`s in the template.
- **FR-EN-26 (P)**: Parent-side playback MUST use the existing `just_audio` player for audio (matches chat) and the stock `video_player` package for video (per [system.md §1](../system.md#1-stack-snapshot) — `appinio_video_player_plus` was removed 2026-05-14 due to Flutter 3.27+ break).
- **FR-EN-27 (P)**: Audio and video bubbles MUST show a duration label and (for video) a thumbnail-first state (poster frame). Tap to play. No autoplay.
- **FR-EN-28 (T)**: When the teacher's preview-before-submit screen shows a recorded audio or video, system MUST provide a "Regravar" CTA that discards the recording without uploading.
- **FR-EN-29**: Crashlytics redaction MUST treat audio/video file paths and binary buffers the same as medication payloads — never log the path or any binary fragment.
- **FR-EN-30**: Server-side storage and CDN paths MUST scope each upload to `diary_media/{school_id}/{teacher_id}/{activity_id}/{type}/{auto_id}` to maintain LGPD-friendly partitioning. The bucket lifecycle policy MUST mirror the soft-delete retention from FR-EN-19 (90 days post-retraction).

##### Read receipts on diary entries (closes iCare engagement-analytics gap)

- **FR-EN-31 (P)**: When a parent opens an `Activity` card and it remains on-screen for ≥ 2 seconds, the client MUST fire `POST /parent/timeline/read` with `{activity_id, read_at}`. The 2-second debounce prevents a fast scroll from over-counting.
- **FR-EN-32 (P)**: The read-receipt request MUST be fire-and-forget from the parent UI's perspective — the timeline never visibly waits on it; failure to record is silent (logged, not surfaced).
- **FR-EN-33 (T)**: The teacher-side `Activity` card MUST surface an aggregate label: "Visto por {seen_count} de {targeted_family_count} famílias" where `targeted_family_count` is the count of distinct parent accounts linked to the targeted child / class / level / all-children at the moment the entry was sent.
- **FR-EN-34 (T)**: The aggregate label MUST NOT expand to per-parent names inside the mobile app. Per-family detail is **only** available via the school's admin web tool, which is out of scope of this mobile spec.
- **FR-EN-35 (P)**: Parents MUST NOT see read receipts of any kind — neither their own ("você leu isso") nor anyone else's. Receipts are a teacher- / admin-facing signal only.
- **FR-EN-36 (T)**: When an `Activity` is retracted (FR-EN-14), the aggregate label MUST disappear from the teacher's view (the audit log on the retracted entry retains the receipt data server-side for admin retrieval).
- **FR-EN-37**: Server-side retention of read-receipt records MUST follow the same LGPD retention default (90 days) as soft-deleted entries — receipts older than 90 days drop out of the aggregate label, which means the label can decay over time for very old entries (acceptable; old entries no longer drive engagement procurement narratives anyway).

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

### Success Criteria for the 2026-05-15 competitive enhancements

- **SC-EN-01 (P)**: Within 30 days of launch, at least 60% of `Activity` cards with ≥ 1 parent reaction or comment also receive a teacher reply or a follow-up entry — proving the social loop is bidirectional, not just parents broadcasting.
- **SC-EN-02 (P)**: Comment-abuse-flag false-positive rate stays below 5% of flagged comments (validated by school admins in the manual review queue).
- **SC-EN-03 (T)**: Median teacher compose time across a school day drops by ≥ 20% versus baseline once drafts ship (drafts cut "lost progress" re-typing, not raw typing).
- **SC-EN-04 (T)**: Cross-device draft restoration is verified by ≥ 95% of teachers who switch between phone and tablet during a 30-day window.
- **SC-EN-05 (T)**: Retraction frequency stays below 2% of all submitted entries — if higher, that signals the teacher UX is letting wrong-target submissions slip through and the compose UX needs work.
- **SC-EN-06 (P)**: Parents who lose a reaction/comment when an entry retracts after the 24h window receive their notification within 10s of the retraction (so the disappearance is never silent).
- **SC-EN-07 (T)**: After 60 days, ≥ 30% of submitted diary entries include at least one `AudioQuestion` or `VideoQuestion` attachment — proves multimedia is being adopted, not just shipped.
- **SC-EN-08 (T)**: Average parent-side time-to-first-play of an audio/video bubble (FCM push → buffer ready) stays under 4 seconds on typical Brazilian 4G/5G.
- **SC-EN-09 (T)**: At least 50% of teachers check the read-receipt aggregate within 24h of sending an entry (proves the metric is actionable, not vanity).
- **SC-EN-10**: Zero LGPD audit findings related to read receipts exposing individual-parent data to other parents or to teachers' mobile UI.

## Assumptions

- The server's `teacher/questions/answers` endpoint accepts multipart form data with `fields[N][...]` nesting; arrays use `[]` suffix on the same key (`value[]` for image files).
- Image quality is enforced server-side; client does not compress before upload (same as chat — see [chat tasks T-fix-5](../chat/tasks.md)).
- `categoriesToSend` not persisting across cold start is acceptable — teachers complete a compose in one sitting.
- The `/files/upload` endpoint is reserved for a future flow (e.g., image-first then reference); not used today.
