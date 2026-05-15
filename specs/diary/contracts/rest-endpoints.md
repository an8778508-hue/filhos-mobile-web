# REST Contracts — Diary Enhancements

Base: `https://criarte.filhos.app/api/v1/`. All calls MUST route through `NetworkClient.handleRequest` → `Either<Failure, T>` (Constitution III). Auth / `school` / `lang` headers added by the interceptor — never set manually. **Hard prereq: T-fix-3 (kill the fresh `Dio()` in `share_button.dart`) before any of these land.**

## Area B — Save-as-draft

### PUT /teacher/questions/draft

Upsert the teacher's draft for a `(target, date)`.

Request body:
```json
{
  "target_id": 42,
  "target_type": "class",
  "target_date": "2026-05-15",
  "idempotency_key": "9f1c…uuid-v4",
  "categories": { "<categoryId>": { /* same shape sendQuestions uses */ } },
  "updated_at": 1747300000000
}
```
`200` → `{ "updated_at": 1747300012345 }` (server's authoritative timestamp).
Errors: `400` malformed, `401` token.

### GET /teacher/questions/draft?target_id=&target_type=&date=

`200` → `{ "draft": { …same shape as PUT body… } | null }`.
Client merges using `updated_at` LWW + soft-confirm if server newer (FR-EN-11).

### DELETE /teacher/questions/draft?target_id=&target_type=&date=

Called after a successful `sendQuestions` (FR-EN-12). `200` → `{ "deleted": true }`. Idempotent (deleting an absent draft is `200`).

## Area C — Soft-delete + resend

### DELETE /teacher/questions/answers/{activity_id}

Soft-delete (sets `retracted_at`; retains row 90 days — FR-EN-19). Server enforces the requester authored the entry (FR-EN-18) → `403` otherwise.
`200` → `{ "retracted_at": "2026-05-15T13:04:22Z" }`.
Side effects (server): writes a `RetractionAuditEntry`; starts the 24 h carry-over window.

### Resend semantics

A normal `POST teacher/questions/answers` for the same `(child_id, date, MainCategory)` within 24 h of a retraction MUST (server-side) reuse the retracted `activity_id`, clear `retracted_at`, bump `version`, keep the Firestore reaction/comment subcollections intact (R8), and push affected parents "atividade atualizada" (FR-EN-16). Outside 24 h → a fresh `activity_id`; reactions/comments dropped with the "sua reação foi excluída" push.

The client carries the **same `idempotency_key`** discipline as a normal submit (R7); a resend is a normal submit from the client's perspective — the server decides reuse-vs-fresh from the retraction window.

## Area E — Read receipts

### POST /parent/timeline/read

Fire-and-forget from the parent UI (FR-EN-32). Body:
```json
{ "activity_id": 12345, "read_at": "2026-05-15T13:10:00Z" }
```
`202` accepted (body ignored by client). Failure is silent + logged, never surfaced (FR-EN-32). Client dedupes per `activity_id` per app session (R6).

### Aggregate read (teacher-side)

No new endpoint — the existing `Activity` payload from `GET /teacher/...` is extended server-side with:
```json
{ "seen_count": 18, "targeted_family_count": 22 }
```
Frozen `targeted_family_count` is computed at send-time. Receipts older than 90 days drop out → `seen_count` may decay for very old entries (FR-EN-37; acceptable).

## Cross-cutting

- **Idempotency** (R7): every `POST teacher/questions/answers` (incl. resend) carries `idempotency_key`; server dedupes on `(teacher_id, idempotency_key)` ≥ 24 h. This is the elevated **T-fix-1** prereq.
- **Media upload** (Area D): audio/video ride the existing multipart `sendQuestions` body as `MultipartFile` (FR-EN-24) — no new upload endpoint, `/files/upload` stays unused.
- All error envelopes follow the existing `{error, message, data}` convention mapped by `NetworkClient`.
