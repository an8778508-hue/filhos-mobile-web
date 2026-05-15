# Firestore Contract — Diary Reactions & Comments (Area A)

> **Constitution note**: this introduces non-chat Firestore usage (Principle VII tension — see [plan.md Constitution Check](plan.md#constitution-check-post-design)). Recommended amendment: generalize VII to "realtime social surfaces are Firestore-backed; no parallel REST realtime path". Not blocking; gated dark behind the `diary_enhancements` flag (R10) until validated.

## Collections

### `diary_reactions/{activityId}/users/{userId}`

One doc per (activity, parent). See [data-model.md → DiaryReaction](../data-model.md).

```
{
  reactions: { heart: <ts>, clap: <ts> },   // map; key set/unset, never appended
  childId: 7,
  userId: "<uid>",
  activityId: "12345",
  updatedAt: <serverTimestamp>
}
```

Write pattern: optimistic local toggle → `set(merge:true)` with `FieldValue.serverTimestamp()` for the toggled key, or `FieldValue.delete()` to remove a reaction. Mirrors chat's optimistic-send pattern.

Counts: derived. v1 = client `count()` aggregate query per activity card (cheap at typical class sizes). If a class exceeds ~100 linked parents, move to a Cloud Function maintaining a denormalized `count_*` on the parent `Activity` (deferred; noted in research.md open items).

### `diary_comments/{activityId}/comments/{autoId}`

```
{
  authorId: 88, authorRole: "parent", authorName: "Ana M.",
  text: "Que linda a atividade!",
  createdAt: <serverTimestamp>,
  deletedAt: null,
  flagged: false, flagCount: 0,
  childId: 7
}
```

Soft-delete: set `deletedAt` (teacher-own or admin — FR-EN-07). Flag: `flagged=true`, `flagCount++` (FR-EN-05; v1 review is manual via admin web).

## Security rules (sketch — finalize in T-EN-07, deploy via release checklist)

```
match /diary_reactions/{activityId}/users/{userId} {
  allow read:  if isApproved() && linkedToChild(resource.data.childId);
  allow write: if isApproved() && request.auth.uid == userId
                 && linkedToChild(request.resource.data.childId);
}
match /diary_comments/{activityId}/comments/{commentId} {
  allow read:   if isApproved() && (linkedToChild(resource.data.childId) || isAssignedTeacher());
  allow create: if isApproved() && request.resource.data.authorId == currentUserId();
  allow update: if isAuthor() || isAssignedTeacher() || isSchoolAdmin();   // soft-delete / flag
  allow delete: if false;   // never hard-delete; soft-delete only
}
```

`isApproved()` mirrors the app-wide approval gate (Principle VIII / FR-EN-06). `linkedToChild`, `isAssignedTeacher`, `isSchoolAdmin` resolve from custom claims / a memberships doc — coordinate exact predicate source with backend (same open question as the chat rules review in [features.md cross-feature](../features.md#cross-feature-tasks)).

## Offline behavior

Firestore offline persistence is currently **disabled** app-wide ([chat tasks reference](../chat/tasks.md)). Reactions/comments inherit that: a reaction tapped offline will not queue until the chat-side offline-persistence task lands. Acceptable for v1 (reactions are not critical-path); note in quickstart as a known limitation.
