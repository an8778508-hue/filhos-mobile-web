---
status: migrated
feature: chat
migrated_from: specs/features.md#chat--b
migrated_date: 2026-05-14
---

# Tasks: Chat

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#chat--b](../features.md#chat--b).

**Tests**: No `test/` directory.

## Phase 1: Setup — ✅ Complete

- [x] T001 Create [lib/features/chat/](../../lib/features/chat/) with `presentation/{bloc,audio_bloc,widgets,styles}`, `models/`, `data_sources/`
- [x] T002 Localization keys (`teachers`, `parent`, `no_teachers_for_this_child_yet`, etc.) in pt/en/ar
- [x] T003 Feature-root `chat_di.dart` registering `ChatRepo` factory, `ChatImpl` factory, and `ChatBloc` as `LazySingleton` (per [constitution principle II](../../.specify/memory/constitution.md))

## Phase 2: Foundational — ✅ Complete (with one compile bug)

- [x] T010 Define `Message`, `ChatUser`, `LastMessage` models; `Conversation` declared but commented-out
- [x] T011 `MessageType` enum + `FromStringToType` / `FromTypeToString` extensions
- [x] T012 Abstract `ChatRepo` with collection constants and Firestore stream signatures
- [x] T013 Implement `ChatImpl` using `cloud_firestore`, wrapping each operation in `arrangeRequestResult` → `Either<Failure, void>` adapter
- [x] T014 **(P0)** `Message.toJson(forServer: true)` writes `FieldValue.serverTimestamp()` for `dateTime`. *Fixed 2026-05-14 in [features.md#chat--b](../features.md#chat--b)*
- [x] T015 **(P0)** `sendMessage` uses `WriteBatch` + `FieldValue.increment(1)` for `unReadCount`. *Fixed 2026-05-14*
- [x] T016 **(P0)** Auto-id message docs via `col.doc()` when no client id is supplied. *Fixed 2026-05-14*
- [x] T017 **(P0)** Null-safe `Message.fromJson` and `ChatUser.fromJson`. *Fixed 2026-05-14*
- [x] T018 **(P0)** `getMessages` adds `.orderBy('timestamp', desc).limit(50)`. *Fixed 2026-05-14*
- [x] T019 **(P0)** Replace `mainKey.currentContext` in `chat_repository.dart` (use `isCurrentUserParent`) and in `getRelatedTeachers` (use `UserBloc.get.state.user?.type`). *Fixed 2026-05-14*
- [x] T020 **(P1)** Lexicographic compare on string ids in `updateConversations` instead of `int.parse`. *Fixed 2026-05-14*

## Phase 3: User Stories 1–4 — ✅ Complete

- [x] T030 [US1] `ChatScreen` renders messages from the Firestore stream
- [x] T031 [US1] Send-message path: `SendMessage` → `_sendSingleMessage` → `ChatImpl.sendMessage` → emit `SendMessageSuccess` → fire `SendMessageNotification`
- [x] T032 [US1] Parent-side fan-out to `relatedTeachers` (when `message.child != null`)
- [x] T033 [US2] `GetLastMessages` subscribes to `users/{userId}/contacts` and aggregates `unReadMessagesCount`
- [x] T034 [US3] Image / file / audio attachments via `lib/core/attachment_selection/` + `record` / `image_picker` / `file_picker`
- [x] T035 [US4] `markMessageAsSeen` writes `LastMessage(isRead: true, unReadCount: 0)` to the receiver's contact doc

---

## Phase 6: Gaps & cleanups

### 🚨 Blocking compile bug

- [x] **T-fix-1** **(P0, blocking)** ✅ **Fixed 2026-05-14** in [message.dart:90-91](../../lib/features/chat/models/message.dart#L90-L91): deleted the second identical `_asMap` declaration. Builds are unblocked.

### Open P0 / P1 from features.md

- [ ] **T-fix-2** **(P0)** [bloc] Replace the catch-all `on<ChatEvent>((event, emit) async { ... })` in [chat_bloc.dart:45-71](../../lib/features/chat/presentation/bloc/chat_bloc.dart#L45-L71) with typed handlers (one `on<Specific>` per event). Use `droppable()` for `SendMessage` to coalesce double-taps; use `restartable()` for `GetMessages` and `GetLastMessages` so a new chat cancels the old stream cleanly. ([features.md#chat--b](../features.md#chat--b))

- [ ] **T-fix-3** **(P0)** [lifecycle] Singleton-stream lifecycle. `ChatBloc` is `registerLazySingleton` ([chat_di.dart:16-22](../../lib/features/chat/chat_di.dart#L16-L22)), so closing it from a screen `dispose()` would break every subsequent chat. [features.md task](../features.md#chat--b) flagged a previous `chat_screen.dart:42-45` site that was killing the stream. **Action**: verify that fix is present today (read [chat_screen.dart](../../lib/features/chat/presentation/chat_screen.dart) lines 1-60), and either (a) keep `ChatBloc` singleton and own subscription lifecycle inside the bloc as today, OR (b) switch to `registerFactory` and let each screen own its own bloc + subscriptions.

- [ ] **T-fix-4** **(P0)** [pagination] Wire pagination UI for messages beyond the 50-most-recent cap. Use Firestore `startAfterDocument` on the messages query; surface a "load older" affordance when the user scrolls to the top of the list.

- [ ] **T-fix-5** **(P1)** [storage] Compress images before `putFile` in [attachment_selection.dart:36](../../lib/core/attachment_selection/attachment_selection.dart#L36) (set `maxWidth` / `imageQuality` on `image_picker.pickImage`). ([features.md#chat--b](../features.md#chat--b))

- [ ] **T-fix-6** **(P1)** [storage] Expose upload `task.cancel()` and consider resumable uploads. Today an in-flight upload cannot be cancelled from the UI. ([features.md#chat--b](../features.md#chat--b))

- [ ] **T-fix-7** **(P2)** [audio] [AudioBloc.close()](../../lib/features/chat/presentation/audio_bloc/audio_bloc.dart#L306-L321) doesn't await `dispose()` chains. Use `Future.wait` and await so the bloc fully releases resources before closing. ([features.md#chat--b](../features.md#chat--b))

- [ ] **T-fix-8** **(P2)** [security] [features.md#chat--b](../features.md#chat--b) — sanity-check Firestore security rules cover the parent/teacher/child triples. Backend-coordinated.

### Architecture

- [ ] **T-arch-1** **(P1)** Move storage path from `chatUsers/{senderId}/contacts/{receiverId}/messages/` (asymmetric) to symmetric `conversations/{conversationId}/messages/`. The `updateConversations` method + `conversationsCollection` constant already exist for this; the migration is mostly in the `sendMessage` write path and the `getMessages` read path. Reduces dependence on lenient cross-user Firestore rules. ([features.md#chat--b](../features.md#chat--b))

- [ ] **T-arch-2** **(P1)** Re-enable Firestore offline persistence at [init_dependencies.dart:42](../../lib/init_dependencies.dart#L42) (`persistenceEnabled: true`). Validate the original write-replay bug that prompted disabling is no longer reproducible, then auto-queue offline writes. Fixes the "send while offline → message lost" UX. ([features.md#chat--b](../features.md#chat--b))

### UX (proposed)

- [ ] **T-feat-1** [T] [features.md#chat--b](../features.md#chat--b) Confirm group-chat creation flow is reachable only when `context.isProfessors && groupType != null`.
- [ ] **T-feat-2** [B] Typing indicators via Firestore presence doc.
- [ ] **T-feat-3** [B] Per-message delivery / read receipts (beyond the per-conversation last-read).

### Code hygiene

- [ ] **T-cleanup-1** Delete the entire commented-out [conversation.dart](../../lib/features/chat/models/conversation.dart) file. If the `Conversation` type is needed for T-arch-1, write it fresh.

- [ ] **T-cleanup-2** Audit `static_data.dart` ([chat/data_sources/static_data.dart](../../lib/features/chat/data_sources/static_data.dart)) — features.md notes one commented-out `mainKey.currentContext!.isProfessors` reference. Delete the file if all references are commented out.

- [ ] **T-cleanup-3** Localize notification preview strings (`"Audio"`, `"Image"`, `"Video"`, `"File"`) at [chat_impl.dart:213-225](../../lib/features/chat/data_sources/chat_impl.dart#L213-L225). Add keys to `localization_keys.dart` + pt/en/ar JSONs. Currently English-only in production push notifications.

- [ ] **T-cleanup-4** Remove the noisy `debugPrint` / `print` calls from `chat_bloc.dart` and `chat_impl.dart` (e.g., `'1111111111111111111111'`, `'5555555555555555555555'`, `'related teachers is empty'`, etc.). Part of the [features.md cross-feature task](../features.md#cross-feature-tasks) about 146 print calls.

- [ ] **T-cleanup-5** `Message.reciever` → `Message.receiver` (typo) — codebase-wide rename. Touches ~40 sites. Schedule when bandwidth allows; the wire format is already corrected via `toJson` writing `'receiver'`.

- [ ] **T-cleanup-6** Capitalize state names: `MarkMassgesAsReadLoading` / `MarkMassgesAsReadSuccess` / `MarkMassgesAsReadError` → `MarkMessagesAsReadLoading` (typo'd `Massges` everywhere). Also `_listentToForgoundNotification` (in notifications_service) is similar style. Coordinate with the cleanup task there.

- [ ] **T-cleanup-7** `ChatError` is **both** a class **and** an interface (declared with `implements ChatError` on three other states, *and* declared as a concrete class at [chat_state.dart:133-140](../../lib/features/chat/presentation/bloc/chat_state.dart#L133-L140)). Confusing. Either rename the concrete class or extract `ChatError` as a pure interface (`abstract interface class`).

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Bloc test for `SendMessage` happy path with mocked Firestore; verify `WriteBatch` is called once.
- [ ] **T-test-2** [P] [US1] Bloc test for parent-side fan-out: 3 related teachers → 3 single-message sends.
- [ ] **T-test-3** [P] [US2] Bloc test for `GetLastMessages` aggregation: `setUnReadMessagesCount` sums correctly across mixed `unReadCount` values.
- [ ] **T-test-4** [P] [US4] Integration test for `markMessageAsSeen` setting `isRead: true` on the receiver's contact doc.
- [ ] **T-test-5** [P] [fromJson] Defensive `Message.fromJson` test: missing `dateTime`, null `sender`, wrong-type `child` — all parse to a renderable message.

---

## Notes

- **T-fix-1 is blocking.** Until the duplicate `_asMap` is removed, `flutter build` will fail on both flavors.
- T-fix-2 + T-fix-3 should be done together — choosing `restartable()` event handlers naturally simplifies the singleton-vs-factory question.
- T-arch-1 + T-arch-2 are interrelated: re-enabling offline persistence is safest after the storage path is symmetric (otherwise queued writes may target the wrong asymmetric doc on the next session).
