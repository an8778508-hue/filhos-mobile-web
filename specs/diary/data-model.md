# Phase 1 Data Model: Diary Competitive Enhancements

Entities introduced by FR-EN-01 … FR-EN-37. Existing baseline entities (`Activity`, `MainCategory`, `QuestionCategory`, `Question` hierarchy, `SchoolItem`, `ChildMenuModel`) are unchanged and documented in [spec.md → Key Entities](spec.md).

## New question subclasses (Area D — extends the existing `Question` hierarchy)

### AudioQuestion `extends Question`

| Field | Type | Notes |
|---|---|---|
| `id` | int | inherited |
| `questionType` | enum | `QuestionType.audio` (NEW enum value) |
| `value` | String? | local file path pre-submit; remote URL post-submit (same in-place swap pattern as `ImageQuestion`) |
| `durationSeconds` | int | ≤ 60 enforced client-side (FR-EN-21) |
| `mimeType` | String | `audio/aac` after client encode (FR-EN-23) |

State transition: `null` → `local-path (recorded)` → `MultipartFile (submitting)` → `remote-url (sent)`. Re-record before submit replaces `value` in place (FR-EN-25).

### VideoQuestion `extends Question`

| Field | Type | Notes |
|---|---|---|
| `id` | int | inherited |
| `questionType` | enum | `QuestionType.video` (NEW enum value) |
| `value` | String? | local path → remote URL (same pattern) |
| `durationSeconds` | int | ≤ 30 enforced client-side (FR-EN-22) |
| `posterUrl` | String? | server-generated thumbnail; null until server transcode completes |
| `mimeType` | String | `video/mp4` h.264 baseline (FR-EN-23) |

`Question.fromJson` factory MUST tolerantly parse both new types and `return null` for still-unknown types (existing FR-008 contract preserved).

## Area A — Reactions & comments (Firestore)

### DiaryReaction (Firestore: `diary_reactions/{activityId}/users/{userId}`)

One document per `(activity, user)`. Holds the set of reactions that user left on that activity.

| Field | Type | Notes |
|---|---|---|
| `userId` | string (doc id) | the reacting parent |
| `activityId` | string (path) | the target `Activity` |
| `reactions` | map<string, Timestamp> | key ∈ {`heart`,`clap`,`saudades`,`laugh`,`thanks`}; value = serverTimestamp when set. Absent key = not reacted |
| `childId` | int | denormalized for security-rule scoping |
| `updatedAt` | Timestamp | serverTimestamp |

Invariant (FR-EN-01): at most one of each reaction type per parent per activity → enforced structurally by the map keys (set/unset, not append).

### DiaryComment (Firestore: `diary_comments/{activityId}/comments/{autoId}`)

| Field | Type | Notes |
|---|---|---|
| `id` | string (auto doc id) | |
| `activityId` | string (path) | |
| `authorId` | int | parent or teacher user id |
| `authorRole` | string | `parent` \| `teacher` (drives UI affordances) |
| `authorName` | string | denormalized for render without a join |
| `text` | string | free-form; trimmed; non-empty |
| `createdAt` | Timestamp | serverTimestamp |
| `deletedAt` | Timestamp? | soft-delete (teacher-own / admin) FR-EN-07 |
| `flagged` | bool | set by report-abuse (FR-EN-05); v1 = flag only |
| `flagCount` | int | increments per distinct reporter |
| `childId` | int | denormalized for security-rule scoping |

Visibility rule (FR-EN-02): readable by author, the assigned teacher, and any parent linked to `childId`. Enforced in Firestore security rules (T-EN-07), not client-side.

## Area B — Save-as-draft

### DiaryDraft (local: Hive box `diary_drafts` via `LocalDatabaseRepo`; remote: REST)

Composite key: `{targetId}:{targetType}:{targetDate}` (e.g., `42:class:2026-05-15`).

| Field | Type | Notes |
|---|---|---|
| `targetId` | int | child / class / level id; null for all-children |
| `targetType` | enum | `child`\|`class`\|`level`\|`all` |
| `targetDate` | String (ISO date) | the school day being drafted |
| `categoriesToSend` | Map<int, QuestionCategory> | the in-progress compose payload (same shape as the live bloc field) |
| `idempotencyKey` | String (uuid v4) | generated once per compose session; carried into final submit (R7 / FR-EN-13) |
| `updatedAt` | int (epoch ms) | drives LWW conflict resolution (FR-EN-11) |
| `dirty` | bool | local-only; true when local has unsynced changes |

State machine: `absent` → `local-dirty` (typing) → `synced` (server ack) → `local-dirty` (more typing) → … → `consumed` (final submit DELETEs both local + remote, FR-EN-12).

## Area C — Soft-delete + resend

No new client model — extends `Activity` (server-side fields the client reads):

| Field added to `Activity` | Type | Notes |
|---|---|---|
| `retractedAt` | DateTime? | non-null = soft-deleted; client renders ghost-line for 24 h then hides (FR-EN-15) |
| `version` | int | bumped on within-window resend that reuses the `activityId` (R8) |

### RetractionAuditEntry (server-owned; not rendered in mobile v1, FR-EN-17)

`{activityId, retractedBy, retractedAt, originalPayloadSnapshot, replacementActivityId?}` — surfaced only via admin web.

## Area E — Read receipts

### DiaryReadReceipt (server-owned aggregate; client reads aggregate only)

Per `Activity`, the client teacher-side reads:

| Field | Type | Notes |
|---|---|---|
| `seenCount` | int | distinct parent accounts that posted a read (FR-EN-33) |
| `targetedFamilyCount` | int | distinct parent accounts linked to the targeted children **at send time** (frozen on the entry) |

Parent-side write payload (FR-EN-31): `POST /parent/timeline/read` body `{activity_id, read_at}`. No per-parent list ever reaches the mobile client (FR-EN-34); parents never read any receipt data (FR-EN-35).

## Enum additions

```text
QuestionType { ...existing 7..., audio, video }   // Area D
DiaryReactionType { heart, clap, saudades, laugh, thanks }  // Area A
DraftTargetType { child, class, level, all }      // Area B (mirrors SchoolItemType)
```

`StringExtension.toQuestionType()` MUST map `'audio' → QuestionType.audio`, `'video' → QuestionType.video`, and still fall through to the tolerant-null path for unknowns (preserves FR-008 / SC-003).
