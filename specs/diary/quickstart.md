# Quickstart: Diary Competitive Enhancements

How to pick up the FR-EN-01 … FR-EN-37 work. Read order: [spec.md](spec.md) (the *what*) → [plan.md Enhancement Plan](plan.md#enhancement-plan-2026-05-15-competitive-pass-fr-en-01--fr-en-37) (the *how/sequence*) → [research.md](research.md) (resolved unknowns) → [data-model.md](data-model.md) + [contracts/](contracts/) (the shapes) → [tasks.md Phase 8](tasks.md) (the checklist).

## Before you write any enhancement code — land the prereq wave

These three are no longer "P1 cleanup"; they are structural foundations (see plan.md dependency graph):

1. **T-fix-1** — add `idempotency_key` to `sendQuestions` ([research.md R7](research.md)). Drafts + resend both need it.
2. **T-fix-3** — kill the fresh `Dio()` in `share_button.dart`. Area D touches the same `gallery_media/` tree; don't propagate the anti-pattern.
3. **T-fix-4** — replace catch-all `on<DiaryEvent>` with typed handlers. Five areas add new events; the dispatcher must be typed first.

`flutter analyze` must stay green on **both** flavors after each (Quality Gate).

## Then ship in this order (validated by the dependency graph)

| Wave | Area | FR | Key tasks | Gate before next wave |
|---|---|---|---|---|
| 1 | D — voice/video | FR-EN-21…30 | T-EN-21…30 | New `Question` subtypes parse tolerantly; capture/playback work both flavors |
| 2 | B — save-as-draft | FR-EN-08…13 | T-EN-08…13 | Cross-device draft restore verified; final submit DELETEs both stores |
| 3 | C — soft-delete+resend | FR-EN-14…20 | T-EN-14…20 | Retract → ghost-line → resend carry-over verified within 24 h; AABAR thread unaffected (T-EN-20) |
| 4 | A — reactions/comments | FR-EN-01…07 | T-EN-01…07 | Firestore rules deployed; approval gate enforced; carry-over from Wave 3 intact |
| 5 | E — read receipts | FR-EN-31…37 | T-EN-31…37 | Aggregate label correct; parents never see receipts; label hides on retract |

Each wave ships behind the `diary_enhancements` remote flag (R10), default OFF, enabled per pilot school via Firestore `config/*`.

## Smoke test per wave (no `test/` dir exists — manual, both flavors)

- **D**: teacher records a 10 s voice note + a 15 s video in a category, submits; parent plays both; re-record discards correctly; >60 s audio / >30 s video are blocked client-side.
- **B**: teacher types half an entry, force-kills the app, reopens → draft restored ≤200 ms; edits on a 2nd device → soft-confirm shows; final submit clears both stores.
- **C**: teacher retracts an entry → parent sees ghost-line; teacher resends within 24 h → reactions/comments survive; resend after 24 h → parent gets "reação excluída" push; cannot retract another teacher's entry (403).
- **A**: parent reacts ❤️ then removes it; posts a comment; flags a comment; pending-approval parent cannot read/post; teacher deletes a comment on their own entry.
- **E**: teacher sees "Visto por X de Y"; X rises after a parent views ≥2 s; never expands to names in-app; parent never sees any receipt; label disappears when the entry is retracted.

## Known limitations carried into v1

- Firestore offline persistence is app-wide disabled → a reaction tapped offline won't queue until the chat-side offline task lands. Reactions are not critical-path; acceptable.
- AR translations of the new keys are TBD (localization team); PT primary + EN inline ship; AR follows the existing discipline.
- Reaction counts use a client `count()` aggregate; revisit with a Cloud Function if a class exceeds ~100 linked parents.
- Per-family read-receipt detail is **not** in the app — it lives in admin web (out of scope, FR-EN-34).

## Backend coordination (nothing here is mobile-only)

Open one umbrella ticket per area with the FR-EN range as the contract. Endpoints/collections to stand up: `PUT/GET/DELETE /teacher/questions/draft`, `DELETE /teacher/questions/answers/{id}` + 24 h carry-over job + audit log, `POST /parent/timeline/read` + `seen_count`/`targeted_family_count` on the teacher `Activity` payload, server-side media transcode + 90-day storage lifecycle, Firestore security rules for the two new collections, `(teacher_id, idempotency_key)` dedupe ≥24 h.
