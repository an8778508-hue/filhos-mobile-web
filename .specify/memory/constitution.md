<!--
SYNC IMPACT REPORT — 2026-05-15
Version change: 1.2.0 → 1.3.0 (MINOR — Principle VII materially expanded; Technology Stack reconciled to observed code)
Modified principles:
  - "VII. Chat Source of Truth" → "VII. Realtime Surfaces Source of Truth (NON-NEGOTIABLE)"
    (generalized from chat-only to all realtime social/messaging surfaces; diary reactions & comments added)
Stack reconciliation (traceable to pubspec.yaml):
  - Media line: `appinio_video_player_plus` → `video_player` (appinio commented out 2026-05-14, line 109; video_player active, line 107)
  - Principle VII chat-audio detail: `flutter_sound` → `record` capture / `just_audio` playback
    (flutter_sound commented out in pubspec line 82; record active line 87; just_audio active line 85)
Added sections: none
Removed sections: none
Templates / dependent artifacts:
  - ✅ .specify/templates/plan-template.md — Constitution Check line VII updated
  - ✅ CLAUDE.md — "Firestore is the chat source of truth" guidance generalized; audio dep detail corrected
  - ⚠ 41 migrated specs/**/plan.md — Constitution Check lists still say "VII. Chat Source of Truth"
       (point-in-time reverse-engineered artifacts; most are "N/A". Deferred batch rename — NOT blocking;
        tracked as a follow-up. Rewriting all 41 now is disproportionate churn for a wording generalization.)
  - ✅ specs/diary/plan.md — already discusses the VII tension + recommends this amendment
Follow-up TODOs: none deferred as placeholders.
-->

# Criarte Constitution

Criarte (pubspec name `escola`, sometimes internally "Filhos") is a Brazilian school ↔ home communication Flutter app shipped as **two flavors** from one codebase: `parents` (`com.algoriza.criarte`) and `professores` (`com.algoriza.profecriarte`). Portuguese is the primary UI language; English and Arabic are also supported. Backend is the REST API at `https://criarte.filhos.app/api/v1/` plus Firebase (Auth, Firestore for chat, Storage, Messaging, Crashlytics, AppCheck).

Every rule below traces to an existing convention in the codebase — it is descriptive of how this project already works, not aspirational. Deviations require an amendment, not a one-off exception.

## Core Principles

### I. Feature-First Layout

New code lives under `lib/features/[feature]/` (see [lib/features/](lib/features/)) with the structure used by sibling features:

```text
lib/features/[feature]/
  [feature]_di.dart           # DependencyInjection — at feature root
  presentation/
    bloc/                     # feature_bloc.dart, _event.dart, _state.dart
    widgets/
    *_screen.dart
  data_sources/
    [feature]_repository.dart # or [feature]_repo.dart — both are in use
    [feature]_impl.dart
  models/
```

Variations exist:

- Repository file is named **`[feature]_repository.dart`** (e.g., [lib/features/chat/data_sources/chat_repository.dart](lib/features/chat/data_sources/chat_repository.dart), [lib/features/login/data_sources/login_repository.dart](lib/features/login/data_sources/login_repository.dart)) **or `[feature]_repo.dart`** (e.g., [lib/features/diary/data_sources/diary_repo.dart](lib/features/diary/data_sources/diary_repo.dart)). Both are acceptable — mirror the closest sibling.
- Some features place `bloc/` at the feature root rather than under `presentation/`.
- A few features have no bloc at all (e.g., [lib/features/onboard/](lib/features/onboard/)).

**Mirror the closest sibling feature** rather than inventing a layout. Cross-feature shared code goes in [lib/core/](lib/core/), never inside another feature.

### II. Dependency Direction

- Features depend on [lib/core/](lib/core/). Features **do not** import each other (rare exceptions for navigation targets and tightly-coupled auth-cluster siblings — keep them visible, not normalized).
- **DI placement** is one of three patterns; pick to match the feature's surface area:
  - **Feature-root `*_di.dart`** implementing `DependencyInjection`, wired into the `dependencyInjection()` function in [lib/core/dependency_injection/di.dart](lib/core/dependency_injection/di.dart). Use this for features that own a repository plus one or more blocs. Examples: [login](lib/features/login/login_di.dart), [chat](lib/features/chat/chat_di.dart), [diary](lib/features/diary/diary_di.dart), [all_children](lib/features/all_children/all_children_di.dart), [search](lib/features/search/search_di.dart), [background_services](lib/features/background_services/background_services_di.dart), home.
  - **Central registration directly in [core/dependency_injection/di.dart](lib/core/dependency_injection/di.dart)** — typically a single `di.registerFactory<FeatureBloc>(...)` line. Use this for "thin" features that own no repository (usually consuming a sibling feature's repo via the shared `di` container). Examples: otp, splash, gallery, my_addresses, add_address, featured_events, terms_and_condtions, notifications, search_for_filter, and most `settings/*` sub-features.
  - **Registered inside a sibling feature's `_di.dart`** — for features that share another feature's repository and are reached through it. Today only `register` qualifies (registered inside [login_di.dart](lib/features/login/login_di.dart) because it shares `LoginRepository`).
- When a thin feature grows its own repository or its own domain, **promote** its registration into a dedicated `*_di.dart` at the feature root. Don't keep central registration for features that have outgrown it.
- Shared widgets go in [lib/core/components/](lib/core/components/), not in a feature. Cross-feature imports of widgets (today, register imports `FieldTitle` from settings) should be migrated into `lib/core/components/` rather than codified.

### III. Networking Contract (NON-NEGOTIABLE)

- Every REST call goes through `NetworkClient.handleRequest` and returns `Future<Either<Failure, T>>`.
- Auth, `school`/`school_id`, and `lang` headers come from [lib/core/network/network_interceptor.dart](lib/core/network/network_interceptor.dart) — never set them manually in a repo.
- Base URL constants live in `lib/core/utils/constants/api_const.dart`.
- The 10-hour Dio timeout is intentional for large media uploads; do not lower it without checking upload flows.

### IV. Persistence Discipline

- Hive access goes through [lib/core/local_db/](lib/core/local_db/) (`LocalDatabaseRepo`/`Impl`), never directly. Known box keys: `token`, `user`, `last_otp_request`, `last_otp_phone`, `rememberMe`, `seenFeaturedEvents`.
- HydratedBloc state (`UserBloc`, `ConfigCubit`, others) **must round-trip** via `toJson`/`fromJson`. When extending state, verify a cold start.
- Storage paths are initialized in `initDependecies()` against `getApplicationDocumentsDirectory()`.

### V. Flavor Branching

- Branch on flavor via `context.isParents` / `context.isProfessors` from [lib/flavors/app_flavors.dart](lib/flavors/app_flavors.dart). **Never** compare strings or duplicate screens.
- Server role is derived from the flavor at login: see [lib/features/login/data_sources/login_impl.dart](lib/features/login/data_sources/login_impl.dart).
- Before shipping a feature, sanity-check **both** flavors. Many screens differ slightly (chat labels, group-chat availability, action permissions); a regression may surface in only one.

### VI. Localization

- No hardcoded user-visible strings.
- Keys are added to [lib/core/localization/localization_keys.dart](lib/core/localization/localization_keys.dart) and translated in all three of [assets/langs/pt.json](assets/langs/pt.json), [assets/langs/en.json](assets/langs/en.json), [assets/langs/ar.json](assets/langs/ar.json). Portuguese is primary.
- Translations are **remote-overridable** via the Firestore `config/*` document consumed by `ConfigCubit`. If production text disagrees with bundled JSON, remote config is the cause — not the code.

### VII. Realtime Surfaces Source of Truth (NON-NEGOTIABLE)

Realtime social and messaging surfaces are backed by **Firestore (`cloud_firestore`)**, not the REST API. No parallel REST realtime (polling-shadow) path may be added for any of them.

- **Chat** — 1:1 parent↔teacher in the context of a child, plus class-group chats for teachers. Message types: text, image, file, audio (capture via `record`, playback via `just_audio`).
- **Diary reactions & comments** — parent/teacher reactions and comment threads on diary `Activity` entries (added 2026-05-15; see [specs/diary/contracts/firestore-schema.md](../../specs/diary/contracts/firestore-schema.md)). Collections `diary_reactions/{activityId}/users/{userId}` and `diary_comments/{activityId}/comments/{autoId}`.

Any future surface whose data is inherently multi-party and realtime (live counts, threads, presence) MUST use Firestore and MUST NOT introduce a polling-over-REST shadow path. Non-realtime data stays on the REST contract (Principle III). Rationale: this is descriptive of how chat already works and how the 2026-05-15 diary enhancement was designed — a single realtime store avoids the stale-count / dual-write failure modes a parallel REST path would create.

### VIII. Approval Gate

After login, any user with `isApproval == false` is routed to [lib/features/your_account_under_review/](lib/features/your_account_under_review/). Every deep-link, push-notification handler, and navigation entry point **must** respect this gate. A background poll updates approval state.

### IX. Medicine Reminders

Medicine alarms use the native alarm wrapper in [lib/core/custom_packages/](lib/core/custom_packages/) (built on the `alarm` package). **Do not** mix `flutter_local_notifications` schedules for the same reminder — they will fight each other.

### X. Theming & Sizing

- Sizing uses `flutter_screenutil` with the design size **430 × 932**.
- Theme is assembled from `ConfigCubit.styling` (remote) in [lib/core/theme/](lib/core/theme/). Don't hardcode colors; pull from theme.
- Fonts: Gotham (default), Ping (Arabic), Gabarito — declared in [pubspec.yaml](pubspec.yaml).

## Technology Stack

- **Flutter** 3.29.3 · Dart SDK `>=3.0.5 <4.0.0` · FVM-pinned via [.fvmrc](.fvmrc)
- **State**: `flutter_bloc` 9, `hydrated_bloc` 10
- **DI**: `get_it` 8
- **HTTP**: `dio` 5
- **Local DB**: `hive` 2 + HydratedBloc storage
- **Firebase**: Auth, Firestore, Storage, Messaging, Crashlytics, AppCheck
- **Auth**: phone + OTP (primary) plus `google_sign_in`, `flutter_facebook_auth`, `sign_in_with_apple`
- **Media**: `image_picker`, `crop_your_image`, `record`, `just_audio`, `video_player`, `photo_view` (stock `video_player`; `appinio_video_player_plus` was removed 2026-05-14 — Flutter 3.27+ `ui.platformViewRegistry` break)
- **Notifications/alarms**: `firebase_messaging`, `flutter_local_notifications`, `alarm`
- **Brazilian fields**: `brasil_fields`, `search_cep`
- **Lints**: `package:flutter_lints/flutter.yaml` ([analysis_options.yaml](analysis_options.yaml))

## Development Workflow

### Build & run

```bash
# Parents flavor
flutter run -t lib/main.dart --flavor parents

# Teachers flavor
flutter run -t lib/main_professores.dart --flavor professores
```

### Release builds

```bash
flutter build apk       --flavor parents      -t lib/main.dart
flutter build appbundle --flavor parents      -t lib/main.dart
flutter build apk       --flavor professores  -t lib/main_professores.dart
flutter build appbundle --flavor professores  -t lib/main_professores.dart
```

### Launcher icons / splash (per flavor)

```bash
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-parents.yaml
flutter pub run flutter_launcher_icons -f flutter_launcher_icons-professores.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-parents.yaml
flutter pub run flutter_native_splash:create -f flutter_native_splash-professores.yaml
```

### Codegen

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Quality Gates

- `flutter analyze` **must pass** on both flavors before merging.
- Both flavors must build (`flutter build apk --flavor parents` and `--flavor professores`).
- **No test suite exists today** — there is no `test/` directory and no `*_test.dart` files in the repo. `flutter_test` is available as a dev dependency. Adding tests for new features is encouraged but not yet a blocking quality gate. When a test directory is established, this rule should be tightened.
- No CI is configured yet ([.github/workflows/](.github/workflows/) is absent — only [.github/copilot-instructions.md](.github/copilot-instructions.md), [.github/agents/](.github/agents/), [.github/prompts/](.github/prompts/)). When CI is added, it must run analyze + per-flavor builds at minimum.

## Governance

- This constitution supersedes ad-hoc practice. Amendments require updating this document and migrating affected templates and code.
- Every rule must trace to something detected in the codebase. Aspirational rules belong in an RFC, not here.
- When a rule blocks a feature, prefer fixing the rule (with an amendment) over a silent exception.
- Day-to-day runtime guidance for AI agents lives in [CLAUDE.md](CLAUDE.md); this constitution captures the load-bearing invariants behind that guidance.
- This constitution is not the only source of build/agent guidance — [Makefile](Makefile) encodes shell commands, [README.md](README.md) is the human-facing intro, and [.github/copilot-instructions.md](.github/copilot-instructions.md) is parallel guidance for GitHub Copilot. When they disagree, this constitution wins for spec-kit workflows; for shell commands, [Makefile](Makefile) is authoritative.

**Version**: 1.3.0 | **Ratified**: 2026-05-14 | **Last Amended**: 2026-05-15

## Amendment Log

- **1.3.0 (2026-05-15)** — Principle VII generalized from "Chat Source of Truth" to "Realtime Surfaces Source of Truth": diary reactions & comments are now Firestore-backed too (designed in the 2026-05-15 diary competitive-enhancement pass — see [specs/diary/plan.md](../../specs/diary/plan.md) Constitution Check and [specs/diary/contracts/firestore-schema.md](../../specs/diary/contracts/firestore-schema.md)). The invariant is now "realtime social/messaging surfaces use Firestore; no parallel REST realtime path" rather than "only chat may use Firestore". Technology Stack Media line reconciled to observed `pubspec.yaml`: `appinio_video_player_plus` → stock `video_player` (appinio removed 2026-05-14 for a Flutter 3.27+ break); Principle VII chat-audio detail corrected from the commented-out `flutter_sound` to `record` (capture) / `just_audio` (playback). MINOR: principle materially expanded, stack reconciled, no breaking removals. 41 migrated `specs/**/plan.md` still reference the old principle name in their Constitution Check lists — deferred batch rename, non-blocking (see Sync Impact Report).
- **1.2.0 (2026-05-14)** — Principle II: acknowledge the three coexisting DI patterns (feature-root, central, sibling-co-located) instead of mandating feature-root for everything. Surfaced by the otp/splash/register migrations on the same day. Recorded the "promote when a thin feature grows a domain" rule. Also noted the cross-feature widget import (register → settings/FieldTitle) as something to migrate into `lib/core/components/`, not normalize.
- **1.1.0 (2026-05-14)** — Validation drift fixes: Flutter 3.13.6 → 3.29.3 (matches [.fvmrc](.fvmrc)); `.fvm/` link → `.fvmrc`; clarified DI file location (then: feature root for all; superseded by 1.2.0); repo-file naming acknowledged both `_repository.dart` and `_repo.dart`; test-suite reality narrowed from "default scaffolding" to "no test suite exists today"; Governance now points at [Makefile](Makefile), [README.md](README.md), [.github/copilot-instructions.md](.github/copilot-instructions.md).
- **1.0.0 (2026-05-14)** — Initial constitution generated via [/speckit.brownfield.bootstrap](.specify/extensions/brownfield/commands/speckit.brownfield.bootstrap.md). 10 principles, all derived from observed code.
