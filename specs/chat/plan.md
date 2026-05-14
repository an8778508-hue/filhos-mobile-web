---
status: migrated
feature: chat
migrated_from: lib/features/chat/
migrated_date: 2026-05-14
---

# Implementation Plan: Chat

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

The largest non-settings feature (44 .dart files). Firestore-backed real-time messaging with FCM-triggered notifications. Most P0 review items have already landed (server timestamps, `WriteBatch`, `FieldValue.increment`, auto-id message docs, null-safe `fromJson`, role-via-`UserBloc` not `mainKey`); remaining work is split between **one blocking compile bug** ([T-fix-1](tasks.md)) and a thick backlog of P0/P1 items in [features.md#chat--b](../features.md#chat--b).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `cloud_firestore` 5.6 — chat source of truth ([constitution principle VII](../../.specify/memory/constitution.md))
- `firebase_storage` 12.4 — image / audio / file payloads
- `flutter_bloc` 9.1 — `ChatBloc` is a `Bloc<ChatEvent, ChatState>` (real Bloc, not Cubit). Uses a single `on<ChatEvent>` catch-all dispatcher — see drift below.
- `image_picker` 1.1, `file_picker` 8.0 — attachment selection
- `record` 6.0 + `audio_session` 0.2 + `just_audio` 0.10 — audio recording / playback. `flutter_sound` is also in pubspec but no longer used; flagged for removal in features.md cross-feature tasks.
- `equatable` 2.0
- `dartz` — `Either<Failure, T>` repo contracts
- `dio` 5.8 — REST for `auth/chat` + teachers endpoint

**Storage**:

- **Firestore** — chat is the source of truth (constitution VII). Collections: `chatUsers`, per-user `contacts` + `messages` subcollections, `childrenMessages` (group), `conversations` (declared, unused).
- **Firebase Storage** — image / audio / file uploads.
- No Hive directly (LocalDatabaseRepo is injected but the read paths are commented out in `getCurrentUser`).

**Testing**: None.

**Target Platform**: iOS + Android, both flavors. iOS needs `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`. Android needs `RECORD_AUDIO`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` on API 33+.

**Project Type**: Largest non-settings feature; standard layout with `presentation/`, `models/`, `data_sources/`, plus a sibling `presentation/audio_bloc/` for audio playback state.

**Performance Goals**:

- Initial render of 50 most-recent messages ≤ 1 s on warm cache.
- Send → receiver visibility ≤ 2 s on 4G.
- Image upload progress visible within 200 ms of selection.

**Constraints**:

- `ChatBloc` is `registerLazySingleton` — only one instance for the whole app session. Subscriptions are bloc-owned; opening a new chat cancels the previous subscription.
- Firestore offline persistence is **disabled** at [init_dependencies.dart:42](../../lib/init_dependencies.dart#L42). Send-while-offline is best-effort and lost on process restart.
- `_messagesPageSize = 50` is a hard cap on initial load; pagination UI is not yet wired.

**Scale/Scope**: 44 .dart files, ~3000 LOC across bloc/screens/widgets/styles. Six Firestore collection paths. Three REST endpoints.

## Constitution Check

- [x] **I. Feature-First Layout** — `presentation/{bloc,audio_bloc,widgets,styles}`, `models/`, `data_sources/`. ✓
- [x] **II. Dependency Direction** — feature-root `chat_di.dart` ✓. `ChatBloc` depends on `MyChildrenRepo` from `settings/my_children/` — a feature → feature import. Acceptable per [constitution principle II](../../.specify/memory/constitution.md) as the parent-children list is genuinely shared; consider promoting `MyChildrenRepo` to `lib/core/` if more features start depending on it.
- [x] **III. Networking Contract** — REST calls (`sendNotification`, `getRelatedTeachers`) go through `NetworkClient.handleRequest` returning `Either<Failure, T>`. Firestore calls are wrapped in a custom `arrangeRequestResult` adapter that mirrors the same `Either<Failure, T>` shape. ✓
- [x] **IV. Persistence Discipline** — N/A (Firestore is the persistence layer for chat; no Hive direct access).
- [x] **V. Flavor Branching** — role is read from `UserBloc.get.state.user?.type` (chat_impl.dart:272) and `isCurrentUserParent` (chat_repository.dart, chat_bloc.dart). No `mainKey.currentContext` usage in this feature. ✓
- [x] **VI. Localization** — `LocalizationKeys` used in user-visible copy. ⚠️ **One drift**: notification preview strings (`Audio`, `Image`, `Video`, `File`) are hardcoded English in [chat_impl.dart:213-225](../../lib/features/chat/data_sources/chat_impl.dart#L213-L225). See [tasks.md T-cleanup-3](tasks.md).
- [x] **VII. Chat Source of Truth** — ✅ explicitly Firestore. No parallel REST path for messages. ✓
- [x] **VIII. Approval Gate** — `ChatScreen` is reached post-gate (main shell) or via FCM tap which is gated in `NotificationHelper`. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — pulled from `context.colors.*` per [chat_styles.dart](../../lib/features/chat/presentation/styles/chat_styles.dart). Sizing via `flutter_screenutil`. ✓

## Project Structure

```text
lib/features/chat/
├── chat_di.dart                       # feature-root DI (DependencyInjection)
├── models/
│   ├── chat_user.dart                 # {id, name, avatar, type}
│   ├── message.dart                   # ⚠️ duplicate _asMap declaration (compile bug)
│   ├── last_message.dart              # {message, isRead, unReadCount}
│   └── conversation.dart              # ⚠️ entire file commented out
├── data_sources/
│   ├── chat_repository.dart           # abstract ChatRepo + collection constants
│   ├── chat_impl.dart                 # Firestore + WriteBatch + serverTimestamp
│   └── static_data.dart               # mostly commented-out reference data
└── presentation/
    ├── chat_screen.dart               # 1:1 message stream UI
    ├── new_child_chat_screen.dart     # parents: pick a child to start chat
    ├── contacts_screen.dart           # contacts list (parents flavor)
    ├── professor_contacts.dart        # teachers: tabs for parents vs internal (group_type)
    ├── bloc/
    │   ├── chat_bloc.dart             # Bloc<ChatEvent, ChatState> — catch-all dispatcher
    │   ├── chat_event.dart            # sealed events
    │   ├── chat_state.dart            # sealed states
    │   ├── chat_helper.dart           # static helpers (isVideoFile, etc.)
    │   ├── images_message_bloc.dart   # separate bloc for image upload progress
    │   └── text_message_bloc.dart     # separate bloc for text composition
    ├── audio_bloc/
    │   ├── audio_bloc.dart            # records + plays audio messages
    │   ├── audio_event.dart
    │   ├── audio_player_bloc.dart     # per-message playback state
    │   └── audio_state.dart
    ├── styles/
    │   └── chat_styles.dart           # context.colors-driven theme adapter
    └── widgets/
        ├── (24 widget files)         # message bubbles, mic icon, gallery icon, etc.
```

### Cross-feature touch points

- **[lib/features/settings/my_children/](../../lib/features/settings/my_children/)** — `MyChildrenRepo` injected into `ChatBloc` for the "children with no messages" list.
- **[lib/core/user/bloc/user_bloc.dart](../../lib/core/user/bloc/user_bloc.dart)** + **[lib/core/user/current_role.dart](../../lib/core/user/current_role.dart)** — role and identity.
- **[lib/features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart)** — `Message.child` is a `ChildModel`. Cross-feature import; `ChildModel` should probably live in `lib/core/models/` since multiple features need it.
- **[lib/core/notifications_service/notification_helper.dart](../../lib/core/notifications_service/notification_helper.dart)** — `type == 'chat'` deep-link → `ChatScreen`.
- **[lib/core/attachment_selection/](../../lib/core/attachment_selection/)** — image/file picker bottom sheet.

**Structure Decision**: Standard layout. Splitting `images_message_bloc` / `text_message_bloc` / `audio_bloc` as siblings to the main `ChatBloc` keeps composition explicit. The `widgets/` folder is large but each widget is single-purpose — leave as-is.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `on<ChatEvent>((event, emit) async { if (event is X) ... })` catch-all in [chat_bloc.dart:45-71](../../lib/features/chat/presentation/bloc/chat_bloc.dart#L45-L71) | Originally written before typed handlers were ergonomic. | Typed `on<Specific>` handlers with `droppable()` for sends and `restartable()` for stream loads would be more correct. ([features.md P0](../features.md#chat--b)). See [tasks.md T-fix-2](tasks.md). |
| `ChatBloc` is `registerLazySingleton` | Owns long-lived Firestore subscriptions across screens. | Per-screen factory DI would re-create subscriptions on every navigation; today's design accepts a single "current conversation" window. The risk is that `chat_screen.dart:42-45` was previously closing the singleton's stream on dispose (features.md P0); confirm the fix or move to factory. See [tasks.md T-fix-3](tasks.md). |
| `conversations/` collection path declared but not used by `sendMessage` | Half-built migration toward symmetric storage. | Today writes go to per-user `chatUsers/{id}/contacts/{contactId}/messages` (asymmetric — relies on lenient Firestore rules). Move to symmetric `conversations/{conversationId}/messages` ([features.md P1](../features.md#chat--b)). See [tasks.md T-arch-1](tasks.md). |
| Firestore offline persistence disabled | Disabled to investigate a write-replay bug at some point. | Re-enabling auto-queues offline writes and fixes the "send while offline → message lost" UX ([features.md P1](../features.md#chat--b)). See [tasks.md T-arch-2](tasks.md). |
| `Message.reciever` (typo) everywhere | Codebase-wide rename is a big diff touching ~40 sites. | Acceptable as-is until a paired refactor with the backend payload schema. The `toJson` already writes the corrected `'receiver'` key, so the wire format is correct. |
| `_messagesPageSize = 50` hard cap with no pagination UI | Conservative initial-load size. | Implement cursor-based pagination (Firestore `startAfterDocument`) when threads grow long. ([features.md P0](../features.md#chat--b) — paginated UI is the remaining piece). See [tasks.md T-fix-4](tasks.md). |
