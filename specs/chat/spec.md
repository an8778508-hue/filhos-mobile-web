---
status: migrated
feature: chat
flavor_scope: both
migrated_from: specs/features.md#chat--b
migrated_date: 2026-05-14
---

# Feature Specification: Chat

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/chat/](../../lib/features/chat/) (44 .dart files) and [features.md#chat--b](../features.md#chat--b).

## Flavor Scope

- **Target flavor(s)**: both. Same screens render for parents and teachers, but with different roles:
  - **Parents** chat with teachers in the context of a specific child (`Message.child` is set).
  - **Teachers** chat with parents (also child-scoped) and with each other in **internal professor-to-professor** threads (no child context).
- **Flavor-conditional behavior**:
  - Group-chat / internal-thread creation flow is reachable only when `context.isProfessors && groupType != null` ([features.md task](../features.md#chat--b)).
  - Contact-list label switches between "teachers" (parents flavor) and "parent" (teachers flavor) via [ChatBloc.getContactFullName](../../lib/features/chat/presentation/bloc/chat_bloc.dart#L351-L360).
  - Role for `getRelatedTeachers` is read from `UserBloc.get.state.user?.type` (not from `mainKey.currentContext`), so the request body / endpoint shape is correct in both flavors.
- **Server role implication**: `teachersEndpoint` switches between `parent/children/teachers` and `teacher/children-teachers` via `isCurrentUserParent` in [chat_repository.dart:10-11](../../lib/features/chat/data_sources/chat_repository.dart#L10-L11).

## User Scenarios & Testing

### User Story 1 — Parent ↔ Teacher 1:1 chat in a child's context (Priority: P1) 🎯 MVP

A parent opens a child's chat, sees the message history, and sends a text / image / file / audio message to the teacher.

**Why this priority**: This is the daily-use communication primitive — without it, neither flavor delivers core value.

**Independent Test**: Open `ChatScreen(contact: teacher, child: child)`. Verify (a) `GetMessages` fires, (b) Firestore stream returns up to 50 most-recent messages ordered by `timestamp desc`, (c) typing + send writes via `WriteBatch` and the receiver sees the message in real time.

**Acceptance Scenarios**:

1. **Given** a parent opens a teacher's chat, **When** `ChatScreen` mounts, **Then** `GetMessages` event fires, `chatRepo.getMessages` returns a Firestore stream, and the bloc subscribes to incoming messages.
2. **Given** the user types text and hits send, **When** `SendMessage` is dispatched, **Then** `ChatImpl.sendMessage` writes via a `WriteBatch`: sender's last-message doc (isRead=true, unReadCount=0), receiver's last-message doc with `FieldValue.increment(1)`, and the message in both per-user `messages` subcollections — all atomic.
3. **Given** the user is the parent and the message has a child context, **When** `SendMessage` fires, **Then** the bloc fans out via `_sendToRelatedTeachers` to every teacher in `relatedTeachers`.
4. **Given** a successful send, **When** the result is `Right(void)`, **Then** `SendMessageNotification` event fires → `chatRepo.sendNotification` posts to `auth/chat` so FCM delivers a push to the receiver.
5. **Given** the user views received messages, **When** `_listenToMessages` receives a snapshot, **Then** `MarkMessageAsSeen` fires for the most recent message and the receiver's last-message doc is updated (isRead=true, unReadCount=0).
6. **Given** the stream returns the most recent 50 messages, **When** the user scrolls past the top, **Then** older messages are paged in (paging UI not yet implemented — features.md task).

### User Story 2 — Teacher contacts list with unread badges (Priority: P1)

A teacher opens the chat tab; they see a list of recent conversations (parents + child rosters), each row showing the last message, timestamp, and unread count.

**Acceptance Scenarios**:

1. **Given** the chat tab is open, **When** `GetLastMessages` fires, **Then** the bloc subscribes to `users/{userId}/contacts` ordered by `message.timestamp desc`.
2. **Given** a snapshot arrives, **When** `_listenToLastMessages` parses, **Then** `lastMessages` list updates, `setUnReadMessagesCount` aggregates, and `LastMessagesSucceed` emits.
3. **Given** a teacher is also messaging another professor, **When** `getLastMessagesGroup(GroupType.internals)` is called, **Then** only professor-↔-professor threads (no `child`) are returned.

### User Story 3 — Image / file / audio / video attachments (Priority: P2)

Users attach an image (gallery / camera), document, or record an audio note.

**Acceptance Scenarios**:

1. **Given** the user taps the camera or gallery icon, **When** they pick or capture an image, **Then** the bytes upload to Firebase Storage and a `Message(type: image)` is written with the resulting URL as `content`.
2. **Given** the user records audio (`record` package), **When** they release the mic, **Then** the file uploads to Storage and a `Message(type: audio)` is written.
3. **Given** the user attaches a file, **When** the upload completes, **Then** a `Message(type: file)` is written; the helper [ChatHelper.isVideoFile](../../lib/features/chat/presentation/bloc/chat_helper.dart) detects video extensions for the notification copy.

### User Story 4 — Real-time read receipts via last-message docs (Priority: P2)

Once a message is seen by the receiver, the unread count drops to 0 and the read flag flips to true.

**Acceptance Scenarios**:

1. **Given** the receiver opens the conversation, **When** `_callMarkMessagesAsSeen` is invoked from `_listenToMessages`, **Then** `markMessageAsSeen` writes `LastMessage(isRead: true, unReadCount: 0)` to the receiver's contact doc.

### Edge Cases

- **A malformed message doc**: tolerated. `Message.fromJson` defends against missing `dateTime` (falls back to `timestamp`, then to "now") and `ChatUser.fromJson` is null-safe. One bad message no longer blanks the entire conversation. ([features.md ✅ P0](../features.md#chat--b))
- **Two messages in the same millisecond**: handled via Firestore auto-id on `messages` subcollection when no client id is supplied ([chat_impl.dart:89-97](../../lib/features/chat/data_sources/chat_impl.dart#L89-L97)).
- **`int.parse` on user ids**: replaced with lexicographic compare in [updateConversations:131](../../lib/features/chat/data_sources/chat_impl.dart#L131) so non-numeric ids don't crash. ([features.md ✅ P1](../features.md#chat--b))
- **Send-while-offline**: Firestore offline persistence is **currently disabled** at [init_dependencies.dart:42](../../lib/init_dependencies.dart#L42) (`persistenceEnabled: false`). Without it, queued offline writes don't survive a process restart — the send-while-offline UX silently loses messages. ([features.md P1](../features.md#chat--b))
- **`ChatBloc` is a `LazySingleton`**: subscriptions are owned by the bloc and live across screen navigations. `messagesSubscription?.cancel()` runs on each new `GetMessages`. ⚠️ Opening chat A → chat B cancels A's subscription. Reopening chat A re-subscribes; lost messages between cancellations are still in Firestore and will be picked up by the next `getMessages` call (limit 50). Acceptable but worth understanding.
- **Approval gate**: `ChatScreen` is reached either via deep-link tap (already gated in [NotificationHelper.handleNotificationTap](../../lib/core/notifications_service/notification_helper.dart#L40-L42)) or via the main shell's chat tab (post-gate). No direct entry skips the gate.
- **Server timestamp clock skew**: `Message.toJson(forServer: true)` writes `FieldValue.serverTimestamp()` for `dateTime` so ordering doesn't depend on the client clock. ([features.md ✅ P0](../features.md#chat--b))
- **Unknown message type**: `FromStringToType.toMessageType()` falls through to `MessageType.text`. The image/file/audio receiver code paths must explicitly check `type` before rendering as media — otherwise an unknown type renders as text.
- **Compile-time bug**: ⚠️ `Message._asMap` is declared **twice** (identical bodies) in [message.dart:90-94](../../lib/features/chat/models/message.dart#L90-L94). Definite duplicate-method error. **See [tasks.md T-fix-1](tasks.md).**

## Requirements

### Functional Requirements

- **FR-001**: System MUST present a 1:1 chat surface backed by Firestore (`cloud_firestore`); REST is used only for `POST auth/chat` (server-side FCM trigger) and `GET teachersEndpoint`.
- **FR-002**: System MUST write outgoing messages via a `WriteBatch` covering: sender's user doc (merge), receiver's user doc (merge), sender's last-message contact doc, receiver's last-message contact doc with `FieldValue.increment(1)`, and the message in both per-user `messages` subcollections (or, when `child != null`, a single `childrenMessages/{childId}/messages` doc).
- **FR-003**: System MUST use Firestore's `FieldValue.serverTimestamp()` for `Message.dateTime` so ordering is server-authoritative.
- **FR-004**: System MUST also persist a numeric `timestamp` (UTC millis) for back-compat with older readers and for `orderBy('timestamp', desc)`.
- **FR-005**: System MUST `orderBy('timestamp', descending: true).limit(50)` on the initial messages stream.
- **FR-006**: System MUST tolerate malformed message docs without blanking the conversation (defensive `fromJson` for `Message` and `ChatUser`).
- **FR-007**: System MUST mark messages as seen when the receiver opens the conversation: write `LastMessage(isRead: true, unReadCount: 0)` to the receiver's contact doc.
- **FR-008**: System MUST route message types `text`, `image`, `audio`, `file` from `Message.type`. Unknown types fall back to `text`.
- **FR-009**: System MUST fire `SendMessageNotification` after a successful Firestore write so the backend can deliver an FCM push.
- **FR-010**: System MUST resolve a parent's related teachers via `GET parent/children/teachers?child_id=…` and a teacher's via `GET teacher/children-teachers?child_id=…`, dispatched on `isCurrentUserParent`.
- **FR-011**: System MUST cancel both `messagesSubscription` and `_lastmessagesSubscription` in `ChatBloc.close()`.

### Localization Requirements

Keys referenced by chat UI (already present in pt/en/ar):

| Key | Use site |
|---|---|
| `teachers`, `parent` | `getContactFullName` description suffix |
| `no_teachers_for_this_child_yet` | thrown error when `getRelatedTeachers` returns empty |
| (notification copy strings — `Audio`, `Image`, `Video`, `File`) | ⚠️ **hardcoded English** in [chat_impl.dart:213-225](../../lib/features/chat/data_sources/chat_impl.dart#L213-L225) — see [tasks.md T-cleanup-3](tasks.md) |

### Backend Touchpoints

- **Firestore collections**:
  - `chatUsers/{userId}` — user profile mirror for chat (merged on each send)
  - `chatUsers/{userId}/contacts/{contactId}` — per-user contact doc carrying `LastMessage`
  - `chatUsers/{userId}/contacts/{contactId}/messages/{messageId}` — per-user message subcollection (writes are duplicated on both sides)
  - `childrenMessages/{childId}/messages/{messageId}` — child-scoped (group) message stream
  - `conversations/{conversationId}` — declared in `updateConversations` but **not used by the current sendMessage path** (legacy / future). See [tasks.md T-arch-1](tasks.md).
- **REST**:
  - `POST auth/chat` — server-side FCM push trigger with `{receiver_id, data: {type: 'chat', sender, child?}, title, message}`
  - `GET parent/children/teachers?child_id=…` — parents flavor
  - `GET teacher/children-teachers?child_id=…` — teachers flavor
- **FCM**: incoming pushes with `data.type == 'chat'` are deep-linked by [NotificationHelper.handleNotificationTap](../../lib/core/notifications_service/notification_helper.dart#L47-L54) to `ChatScreen(contact, child)`.

### Permissions & Approval Gate

- `isApproval == true` required to reach the chat tab (enforced by `MainScreen` route and by the FCM deep-link gate).
- Device permissions:
  - **Camera** (image capture), **Photos** (gallery picker), **Microphone** (audio recording), **Storage** (file picker)
  - All flow through [lib/core/attachment_selection/](../../lib/core/attachment_selection/) and `permission_handler`.

### Key Entities

- **`Message`** ([message.dart](../../lib/features/chat/models/message.dart)) — `{id, dateTime?, timestamp?, content, type, sender, reciever, child?}`. Defensive `fromJson`, server-timestamp `toJson`. ⚠️ `reciever` typo persists throughout the codebase; `_asMap` declared twice (compile error).
- **`ChatUser`** ([chat_user.dart](../../lib/features/chat/models/chat_user.dart)) — `{id, name?, avatar?, type?}`. Null-safe `fromJson`. Built from `UserModel` via `ChatUser.fromUserModel`.
- **`LastMessage`** ([last_message.dart](../../lib/features/chat/models/last_message.dart)) — `{message, isRead, unReadCount?}`. Written to contact docs; `unReadCount` updated via `FieldValue.increment(1)` on the receiver side.
- **`Conversation`** ([conversation.dart](../../lib/features/chat/models/conversation.dart)) — **entire file is commented out**. Dead code; the `conversationsCollection` constant in the repo references the unused path. See [tasks.md T-cleanup-1](tasks.md).
- **`MessageType`** — enum `{text, audio, image, file}`. No `video`; videos ride as `file` with the `ChatHelper.isVideoFile` content-extension check producing a different notification preview.

## Success Criteria

- **SC-001**: A sent message appears on the receiver's device within 2 seconds on a typical 4G connection (Firestore + FCM round-trip).
- **SC-002**: Two simultaneous sends never both render `unReadCount = 1` (the `FieldValue.increment` invariant).
- **SC-003**: A malformed message doc never blanks the conversation; the surrounding messages still render.
- **SC-004**: After the receiver opens the chat, the sender's UI shows the message as read within 3 seconds.
- **SC-005**: Both flavors compile and run with `flutter build apk --flavor parents` and `--flavor professores` — currently **fails today** until [tasks.md T-fix-1](tasks.md) lands (duplicate `_asMap`).

## Assumptions

- Firestore security rules cover the parent/teacher/child triples — flagged in [features.md task](../features.md#chat--b) as needing a sanity check.
- The backend's `auth/chat` endpoint is the only FCM trigger; client-side FCM sends are not used.
- Firestore offline persistence will be re-enabled after the chat queue UX is designed (today disabled per [init_dependencies.dart:42](../../lib/init_dependencies.dart#L42)).
- The hardcoded `_messagesPageSize = 50` is sufficient for typical school-day usage. Pagination is needed for long-running parent ↔ teacher threads (not yet implemented).
- Image uploads compress before `putFile` would meaningfully reduce LGPD risk and bandwidth — not yet implemented (features.md P1).
