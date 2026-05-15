# Phase 0 Research: Diary Competitive Enhancements (2026-05-15)

Resolves the unknowns surfaced by [plan.md → Enhancement Plan](plan.md#enhancement-plan-2026-05-15-competitive-pass-fr-en-01--fr-en-37). Each entry: **Decision / Rationale / Alternatives considered**.

## R1 — Draft persistence: HydratedBloc vs Hive box vs server-only

**Decision**: Local layer = a new `diary_drafts` Hive box accessed **only** through `LocalDatabaseRepo` (extend its schema). Remote layer = 3 REST endpoints. No HydratedBloc.

**Rationale**: Drafts are a *keyed collection* — one entry per `(target_id, target_type, target_date)` — not a single bloc-state blob. HydratedBloc serializes one state object per cubit; forcing the whole `DiaryState` (which holds the live in-memory `categoriesToSend` compose model, search results, timeline) to round-trip would collide with the existing compose flow and bloat every cold start. Constitution Principle IV mandates Hive-through-`LocalDatabaseRepo`; a new box key is the established extension pattern (cf. `seenFeaturedEvents`).

**Alternatives considered**:
- *HydratedBloc on DiaryBloc* — rejected: single-blob serialization, collides with in-memory compose state, cold-start cost.
- *Server-only (no local)* — rejected: violates the locked Q2 clarification (hybrid, ≤200 ms local write); offline typing would lose data.
- *Separate `sqflite` table* — rejected: introduces a new persistence engine the codebase doesn't use; Hive is the convention.

## R2 — Draft sync conflict resolution

**Decision**: Last-write-wins keyed on `updated_at`, with a blocking soft-confirm dialog (FR-EN-11) when the server draft is newer than the local draft on editor open. No operational transform, no CRDT, no field-level merge.

**Rationale**: A teacher rarely edits the same `(target,date)` draft on two devices simultaneously; the realistic conflict is "I drafted on the classroom tablet this morning, now I'm on my phone." LWW + an explicit "substituir?" prompt covers that without the complexity budget of OT/CRDT. The soft-confirm prevents *silent* loss, which is the actual risk.

**Alternatives considered**:
- *Field-level 3-way merge* — rejected: typed-question payloads aren't trivially mergeable; complexity unjustified for the conflict frequency.
- *Silent LWW* — rejected: silently discarding a tablet draft is the exact data-loss failure FR-EN-11 exists to prevent.

## R3 — Video capture pipeline: `image_picker.pickVideo` vs dedicated recorder

**Decision**: Use `image_picker.pickVideo(maxDuration: 30s)` for capture in v1; client-side compression to 720p h.264 via a lightweight transcode (evaluate `video_compress`); server re-encodes to the canonical profile.

**Rationale**: `image_picker` is already a dependency and already used for image questions; `pickVideo` gives native camera + gallery with a duration cap for near-zero new surface. A dedicated in-app recorder (custom `camera` plugin UI) is more control but a large new widget surface and battery/codec testing burden — not justified for a ≤30 s clip in v1.

**Alternatives considered**:
- *`camera` plugin custom recorder* — rejected for v1: large surface, device-matrix testing cost. Reconsider in v2 if teachers want in-app trim.
- *No client compression (server-only transcode)* — rejected: 4G upload of raw 1080p 30 s clips blows SC-EN-08 (4 s first-play) and parents' data plans.

## R4 — Audio capture reuse from chat

**Decision**: Reuse the chat audio stack (`record` for capture, `just_audio` for playback) wholesale. Wrap it in a diary-local `audio_question_widget.dart`; do not refactor chat's audio into `core/` as part of this work.

**Rationale**: Chat audio works in production. Extracting a shared `core/audio/` module is a tempting refactor but is scope creep against this enhancement and risks regressing chat. Compose the existing widgets; file a separate follow-up if duplication becomes painful.

**Alternatives considered**:
- *Promote chat audio to `core/`* — deferred: cross-cutting refactor, separate ticket, risks chat regression.
- *New audio dependency* — rejected: `record`/`just_audio` already vetted and shipping.

## R5 — Reactions/comments realtime store: Firestore vs REST

**Decision**: Firestore, mirroring chat's collection + optimistic-write pattern. New collections `diary_reactions/{activity_id}/users/{user_id}` (one doc per user; the doc holds a set of reaction types) and `diary_comments/{activity_id}/comments/{auto_id}`.

**Rationale**: Reaction counts and comment threads are inherently realtime/multi-party; Firestore gives live updates, offline queueing, and a battle-tested pattern already in the app. This expands Principle VII's Firestore scope beyond chat — flagged in the Constitution Check with a recommended amendment, not treated as a violation (no parallel REST *chat* path is created).

**Alternatives considered**:
- *REST polling* — rejected: worse UX (stale counts), heavier backend, no offline.
- *REST + websocket* — rejected: the app has no websocket infra; Firestore already fills this role.

**Reaction-doc shape decision**: one doc per `(activity, user)` holding a `Map<reactionType, serverTimestamp>` rather than one doc per reaction. Rationale: enforces "at most one of each reaction per parent per Activity" (FR-EN-01) with a single doc write and trivial idempotency; counts are derived via a Cloud Function aggregate or client `count()` query.

## R6 — Read-receipt write trigger & debounce

**Decision**: Fire `POST /parent/timeline/read` when an `Activity` card has been ≥ 50% visible for a continuous ≥ 2 s (visibility via `VisibilityDetector` or viewport math), fire-and-forget, deduped client-side per `activity_id` per app session.

**Rationale**: A 2 s continuous-visibility gate filters fast scrolls (SC-EN drives FR-EN-31). Session-dedup prevents re-posting the same receipt on every scroll-back. Fire-and-forget keeps the timeline at 60 fps (SC-002 must not regress).

**Alternatives considered**:
- *Mark-read on tap-to-expand only* — rejected: many parents read the card inline without expanding; under-counts engagement, weakening the iCare procurement narrative the feature exists for.
- *Mark-read on any pixel visible* — rejected: a flick-scroll would over-count, making "Visto por X de Y" meaningless.

## R7 — `idempotency_key` design (prereq T-fix-1, now load-bearing)

**Decision**: Client generates a UUID v4 `idempotency_key` per *compose session* (not per send attempt); it rides as a body field on `sendQuestions`, is reused across retries, and is the same key the draft lifecycle (FR-EN-13) carries so a draft-sync + final-submit collapse to one server write. Server dedupes on `(teacher_id, idempotency_key)` for 24 h.

**Rationale**: Per-session (not per-attempt) is the whole point — retries must collide. Tying the draft's key to the final submit's key closes the "offline draft replay double-writes" hole (FR-EN-13).

**Alternatives considered**:
- *Per-attempt key* — rejected: defeats dedupe.
- *Server-generated key* — rejected: the client must own it to make retries idempotent before the server ever sees the first attempt.

## R8 — Soft-delete carry-over of reactions/comments

**Decision**: Carry-over is **server-side**, triggered when the same teacher resubmits for the same `(child_id, date, MainCategory)` within 24 h of retraction. The server re-points the existing Firestore reaction/comment subcollections to the new `activity_id` (or, simpler, the new entry reuses the retracted entry's `activity_id` and only flips `retracted_at` back to null with a new `version`). Mobile does not orchestrate carry-over.

**Rationale**: Firestore docs are keyed by `activity_id`; re-using the id on a within-window resend makes carry-over a no-op for the social subcollections and avoids a client-side migration dance. The audit log (FR-EN-17) records the version bump.

**Alternatives considered**:
- *Client copies reactions to the new activity* — rejected: race-prone, requires the client to read+write another user's reaction docs (security-rule hostile).
- *Drop all reactions on any retract* — rejected: violates FR-EN-16's within-window carry-over promise; hurts the engagement loop.

## R9 — AABAR cross-feature interplay (FR-EN-20)

**Decision**: No coupling. The AABAR consent token is single-use and scoped to one message at tick-time ([aabar/spec.md FR-015](../aabar/spec.md)); a later diary retraction does not call back into AABAR. The AABAR thread keeps the snapshot it already received. Verified by a staging test (T-EN-20), not by code coupling.

**Rationale**: Honors the locked AABAR privacy model — consent is per-message and immutable once spent. Retroactively scrubbing AABAR would require AABAR to track diary entry lineage, which it deliberately does not (clean-UX, minimal-payload posture).

**Alternatives considered**:
- *Retraction revokes AABAR context* — rejected: contradicts AABAR's single-use-token design; would require AABAR to retain diary-entry provenance it intentionally doesn't keep.

## R10 — Enhancement rollout gating

**Decision**: A single `ConfigCubit` remote flag `diary_enhancements` (and optionally per-area sub-flags) gates the whole batch per school during pilot (T-EN-X2). Default OFF. Firestore `config/*` already overlays this with zero new infra.

**Rationale**: Lets the pilot school(s) get the batch without a binary release; matches the existing remote-config discipline (Principle VI). De-risks the Principle VII Firestore expansion by keeping it dark until validated.

**Alternatives considered**:
- *Build-flavor gate* — rejected: needs a release to toggle; defeats pilot agility.
- *No gate* — rejected: shipping a Firestore-schema expansion to all schools at once with no kill switch is reckless.

## Open items intentionally NOT resolved here (belong to /speckit-tasks or backend)

- Exact server dedupe TTL window beyond the 24 h floor (backend decision).
- Cloud Function vs client aggregate for reaction counts at scale (perf decision, revisit if a class has >100 parents).
- AR translations of the new keys (localization team; tracked, non-blocking).
- Admin-web per-family receipt UI (explicitly out of mobile scope per FR-EN-34).
