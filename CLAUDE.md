# CLAUDE.md

Guidance for Claude Code when working in this repository. Read this first; it captures domain knowledge and architectural conventions that are not obvious from the code alone.

---

## 1. Product Overview (Business Spec)

**Product name:** **Criarte** (sometimes referred to internally as "Escola" / "Filhos").
**What it is:** A Brazilian school ↔ home communication platform. It bridges teachers and parents around a shared child, surfacing the child's daily activities, photos, events, medications, and direct messaging.
**Target users:** Brazilian private/early-education schools and the families enrolled in them. Portuguese is the primary UI language.
**Pubspec name:** `escola` · **API base:** `https://criarte.filhos.app/api/v1/` · **Firebase project:** `escola-cede2`.

### 1.1 Two flavors (two distinct apps from one codebase)

The same codebase ships as two App Store / Play Store apps via Flutter flavors:

| Flavor | Audience | Android applicationId | Entry point |
|--------|----------|------------------------|-------------|
| `parents` | Parents/guardians | `com.algoriza.criarte` | [lib/main.dart](lib/main.dart) |
| `professores` | Teachers (Portuguese for "teachers") | `com.algoriza.profecriarte` | [lib/main_professores.dart](lib/main_professores.dart) |

Flavor is exposed at runtime via [lib/flavors/app_flavors.dart](lib/flavors/app_flavors.dart) and `context.isParents` / `context.isProfessors` extensions. **Always branch on these extensions instead of duplicating screens** — most screens are shared, with small flavor-conditional differences (e.g., chat search field labels, group-chat availability, action permissions).

Server role is set from the flavor at login time — see [lib/features/login/data_sources/login_impl.dart:30](lib/features/login/data_sources/login_impl.dart#L30): `'role': context.isProfessors ? 'teacher' : 'parent'`.

### 1.2 Core user flows

- **Sign-in:** Phone-number + country code → SMS OTP (Firebase Auth) → server returns `accessToken` + `UserModel`. New/teacher accounts may land on **`your_account_under_review`** until an admin approves them; a background poll updates approval state.
- **Multi-child:** A parent can have several enrolled children. The home screen lets them switch between children; teacher accounts work across a class roster instead.
- **Diary (atividades):** Teachers post structured daily reports per child (feeding, sleep, mood, behavior, activities). The diary is a typed-question system (`CheckQuestion`, `RatingQuestion`, `SelectQuestion`, `NumberQuestion`, `DurationQuestion`, `ImageQuestion`, `InfoQuestion`) organized into `MainCategory` → `QuestionCategory`. Parents read; teachers write.
- **Chat:** 1:1 messaging between a parent and a teacher in the context of a specific child, plus class-group chats for teachers. Backed by **Firestore** (real-time). Supports text, image, file, and audio messages (`flutter_sound` + `record`).
- **Events:** Teachers create school events (trips, meetings, celebrations) with optional RSVP/approval. Parents RSVP via the `add_form` engine and `select_attendants`.
- **Gallery:** Teachers upload photos per child; parents browse the gallery for their children.
- **Announcements:** Broadcast notices delivered via Firebase Cloud Messaging + an in-app inbox.
- **Medicines:** Parents register medications for a child (dosage, schedule, prescription photo). Local `alarm` reminders fire on the parent's phone; teachers see what's registered for kids in their class.
- **Addresses:** Parents save home/pickup addresses; CEP lookup via `search_cep` (Brazilian postal codes).
- **Settings:** Profile editing, my children, my addresses, medicines, announcements preferences, events preferences, about/terms/privacy.

### 1.3 Domain entities

Core models in [lib/core/models/](lib/core/models/) and feature `models/` folders:

| Entity | Meaning |
|--------|---------|
| `UserModel` | Account holder (parent or teacher); carries `accessToken`, `role`, `isApproval`, `schoolId`, profile fields (CPF, phone, avatar, classes for teachers) |
| `ChildDetailsModel` | Enrolled student; references `responsible` teacher and `enroll_parent` |
| `EventModel` | School event with `startDate`, `endDate`, `requireApproval`, `teacherAllowActions` |
| `Activity` | Diary entry: child + professor + date + `MainCategory` + answered `QuestionCategory` list |
| `MainCategory` / `QuestionCategory` / `Question` (typed subclasses) | Diary schema |
| `Message` / `ChatUser` / `Conversation` | Chat domain (Firestore-backed) |
| `GalleryListModel` | Per-child photo collection |
| `NotificationModel` | Push notification with `eventable_id` / `eventable_type` deep-link target |
| `AddFormFormModel` + typed `FormModel` subclasses | Schema-driven dynamic forms (RSVPs, consents, medical info, incident reports) with conditional visibility (`FormDependencyModel`) |
| `TitleModel` / `ClassModel` | Teacher job title and class assignments |

### 1.4 Localization & geography

- **Languages:** Portuguese (primary), English, Arabic — translation JSONs in [assets/langs/](assets/langs/), keys in [lib/core/localization/localization_keys.dart](lib/core/localization/localization_keys.dart).
- **Translations are remote-driven:** `ConfigCubit` fetches translations and styling from a Firestore `config/*` document. Bundled JSON in `assets/langs/` is the fallback / upload source.
- **Brazil-specific surfaces:** CPF (national ID), CEP (postal code), PIX terminology, phone formatting via `brasil_fields`.

---

## 2. Technical Spec

### 2.1 Stack

- **Flutter** 3.29.3 · Dart SDK `>=3.0.5 <4.0.0` (FVM-pinned via [.fvmrc](.fvmrc))
- **State management:** `flutter_bloc` (BLoC + Cubit), with `hydrated_bloc` for persisted state (`UserBloc`, `ConfigCubit`)
- **DI:** `get_it` (`di` singleton in [lib/core/dependency_injection/di.dart](lib/core/dependency_injection/di.dart))
- **HTTP:** `dio` with custom interceptors
- **Local storage:** `hive` (token, user, OTP state, rememberMe, seen-events flags) + `hydrated_bloc` storage for cubit state
- **Backend:** REST API at `criarte.filhos.app` + Firebase (Auth, Firestore for chat, Storage for media, Messaging for push, Crashlytics)
- **Media:** `image_picker`, `crop_your_image`, `flutter_sound` + `record` (audio messages), `just_audio`, `video_player` + `appinio_video_player`, `photo_view`
- **Notifications:** `firebase_messaging` + `flutter_local_notifications` + `alarm` (for medicine reminders)
- **Sizing/theming:** `flutter_screenutil` (design size 430×932), `flutter_custom_theme` driven by remote styling config

### 2.2 Architecture

Clean-Architecture-flavored, **feature-first**. Each feature in [lib/features/](lib/features/) typically owns:

```
feature_name/
  presentation/
    bloc/                   feature_bloc.dart, _event.dart, _state.dart
    widgets/
    *_screen.dart
  data_sources/             feature_repository.dart, feature_impl.dart, feature_di.dart
  models/
```

Variations exist (some features place `bloc/` at the root, some have no bloc — e.g., `onboard/`). When adding a feature, **mirror the closest sibling feature's layout** rather than inventing a new one.

[lib/core/](lib/core/) is shared infrastructure:

| Subdir | Role |
|--------|------|
| `network/` | Dio client + interceptors (auth, `school`/`school_id`, `lang` headers) + generic `handleRequest<T>` returning `Either<Failure, T>` |
| `errors/` | `ServerException` / `NetworkException` / matching `Failure` types |
| `theme/` | Theme assembled from remote `ConfigCubit.styling` |
| `localization/` | Delegates + locale resolution + translation keys |
| `user/` | `UserBloc` (HydratedCubit) + repo |
| `config/` | `ConfigCubit` (HydratedCubit) — translations + styling from Firestore |
| `models/` | Cross-feature domain models (User, Child, Event, Announcement, …) |
| `utils/` | Date formatting, validation, debouncer, alarm manager, size config, extensions, `api_const.dart` |
| `notifications_service/` | FCM + local notification helpers |
| `local_db/` | Hive-backed `LocalDatabaseRepo`/`Impl` (path: `{appDir}/jeel`) |
| `dependency_injection/` | `di` GetIt instance + `NetworkInjection` |
| `components/` | Shared widgets (buttons, fields, dialogs, snackbars, media) |
| `attachment_selection/` | Image/file picker bottom sheet |
| `custom_packages/` | Brazilian field formatters, native alarm wrapper |
| `event_bus.dart` | Global event bus for cross-feature signals |

Feature DI files implement `DependencyInjection` and are wired through `initDependecies()` in [lib/init_dependencies.dart](lib/init_dependencies.dart).

### 2.3 Networking conventions

- Base URL constants in `lib/core/utils/constants/api_const.dart`. Production: `https://criarte.filhos.app/api/v1/`.
- Auth header `Authorization: Bearer <token>` and `school`/`school_id`/`lang` headers are added by [lib/core/network/network_interceptor.dart](lib/core/network/network_interceptor.dart) — **don't add them manually in repos.**
- Repo methods return `Future<Either<Failure, T>>` via `NetworkClient.handleRequest`. 500-class errors are reported to Crashlytics.
- 10-hour Dio timeout is intentional (large uploads). Don't lower it without checking media upload flows.

### 2.4 Persistence

- **HydratedBloc** storage initialised in `initDependecies()` at `getApplicationDocumentsDirectory()`. Anything stored in `UserBloc` / `ConfigCubit` state is auto-persisted via `toJson`/`fromJson` — keep those round-trippable.
- **Hive** box keys: `token`, `user`, `last_otp_request`, `last_otp_phone`, `rememberMe`, `seenFeaturedEvents`. Access through `LocalDatabaseRepo`, not Hive directly.
- `clearCache` flag in `initDependecies()` wipes both stores — useful when debugging stale state.

### 2.5 Build & run

```bash
# Parents flavor (default)
flutter run -t lib/main.dart --flavor parents

# Teachers flavor
flutter run -t lib/main_professores.dart --flavor professores

# Launcher icons / splash (per flavor)
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml

# Release builds
flutter build apk       --flavor parents      -t lib/main.dart
flutter build appbundle --flavor parents      -t lib/main.dart
flutter build apk       --flavor professores  -t lib/main_professores.dart
flutter build appbundle --flavor professores  -t lib/main_professores.dart

# Codegen (if/when adding generators)
flutter pub run build_runner build --delete-conflicting-outputs
```

Android flavor dimension `flavors` is declared in `android/app/build.gradle`. The repo uses **FVM** (pinned to Flutter 3.29.3 via [.fvmrc](.fvmrc) — there is no `.fvm/` directory); prefer `fvm flutter …` if your environment is configured for it.

---

## 3. Working in this repo — guidance for Claude

### 3.1 Defaults

- **Match existing patterns.** Feature internals vary; pick the closest sibling feature and mirror its layout, not a hypothetical ideal. Don't introduce a domain layer or repository abstraction the rest of the codebase doesn't use.
- **Branch on flavor with `context.isParents` / `context.isProfessors`**, not by checking strings or duplicating screens.
- **Repos return `Either<Failure, T>`.** New endpoints should go through `NetworkClient.handleRequest` so interceptors, error mapping, and Crashlytics behave consistently.
- **Persisted state must serialize.** When extending `UserBloc` or `ConfigCubit` state, update `toJson`/`fromJson` and verify a cold start round-trips.
- **Localization keys live in `lib/core/localization/localization_keys.dart`** and translations in `assets/langs/{en,pt,ar}.json`. Never hardcode user-visible strings — add a key in all three languages.
- **Don't bypass `LocalDatabaseRepo`** to talk to Hive directly; the repo is the single source of truth for the box's schema.
- **Don't add user-visible strings in English only.** Portuguese is the primary UI language; English/Arabic are also required.

### 3.2 Things to be careful about

- **Flavor-specific behavior is easy to forget.** Before shipping a feature, sanity-check both flavors — many screens render differently, and only one flavor may surface a regression.
- **Firestore is the chat source of truth**, not the REST API. Chat queries and message writes go through `cloud_firestore`; don't add a parallel REST chat path.
- **Approval gate.** After login, a user with `isApproval == false` is routed to `your_account_under_review`. Any deep-link / push-handler you add must respect this gate or it will land users on screens they aren't authorized to see.
- **Medicine alarms use the device-native alarm wrapper** in `lib/core/custom_packages/`. Don't mix it with `flutter_local_notifications` schedules for the same reminder.
- **Translations are remote-overridable** via Firestore `config/*`. If a string seems wrong in production but right in the bundled `assets/langs/*.json`, the remote config is overriding it.

### 3.3 Where to look first

| Task | Start here |
|------|-----------|
| New screen | Closest existing feature under `lib/features/` |
| New API call | `lib/core/network/network_client.dart` + nearest feature's `_impl.dart` |
| New persisted setting | `lib/core/local_db/` (Hive) or `UserBloc`/`ConfigCubit` (hydrated) |
| New shared widget | `lib/core/components/` |
| Theme / colors | `ConfigCubit.styling` + `lib/core/theme/` |
| Push notification handling | `lib/core/notifications_service/` |
| Adding a translated string | `lib/core/localization/localization_keys.dart` + `assets/langs/*.json` |
| Flavor-specific behavior | `context.isParents` / `context.isProfessors` from `lib/flavors/app_flavors.dart` |

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
