# Implementation Plan: AABAR — in-app ABA chat agent

**Branch**: `(Nour_main — operating with sibling brownfield work)` | **Date**: 2026-05-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/aabar/spec.md`

## Summary

AABAR brings an in-app ABA (Applied Behavior Analysis) chat agent to both Criarte flavors. A user opens a clean chat surface from the home-screen section tile or a diary-entry CTA, types or taps a flavor-conditional suggestion chip, and receives a plain-text reply from the company's existing n8n RAG webhook over REST. A per-message LGPD affordance lets users optionally attach one child's recent diary context (single-use server-issued consent token, default OFF, non-sticky). A "Meus consentimentos AABAR" audit screen ships in v1 under the settings shell.

Technical approach: feature-root `aabar_di.dart` wires an `AABARCubit` (not HydratedCubit — session-only) over `AABARImpl`, which uses the existing `NetworkClient.handleRequest` with the full n8n webhook URL. Dio 5 handles absolute URLs correctly; the interceptor supplies the Bearer auth header automatically. No Firestore, no local persistence. The webhook URL and the section's presence in the home grid are remote-configured via `ConfigCubit` (backed by Firestore `config/*`). Flavor branching on `context.isParents` / `context.isProfessors` drives suggestion chips and diary CTA seed text.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**: `flutter_bloc` 9, `get_it` 8, `dio` 5, Firebase (`firebase_core`, `firebase_auth`, `firebase_crashlytics`), `flutter_screenutil`

**New Dependency Required**: `flutter_markdown: ^0.7.x` — not in pubspec today. Required for markdown rendering in assistant bubbles (FR-008: lists, bold, in-app links). Add before UI work begins (see R5, T-setup-1).

**Storage**: No local persistence. `AABARCubit` holds session-only state; wiped on cold start. Consent ledger is server-owned — mobile only reads it via REST. No Hive box, no HydratedBloc.

**Testing**: No test suite exists today (`flutter_test` available as dev dep). This feature adds no tests in v1. Note in tasks.md for future hardening.

**Target Platform**: iOS + Android, **both flavors** (`parents` and `professores`). Design size 430×932 (`flutter_screenutil`).

**Performance Goals**:
- 95% of replies arrive ≤ 8 s end-to-end under typical Brazilian 4G/5G (SC-001)
- Chat list scroll at 60 fps — trivially achievable for AABAR's short conversation lists

**Constraints**:
- Webhook URL remote-configured via `ConfigCubit`; all AABAR surfaces hidden when URL is unset
- 30 s receive timeout matches existing `NetworkClient` default — no override needed (RAG p95 assumed ≪ 8 s)
- No streaming response in v1
- Rate-limit UX rendered from `429 Retry-After` response header; no client-side countdown or composer disable
- AR translations TBD by localization team; PT-BR + EN ship first

**Scale/Scope**: 1 primary screen (`AabarScreen`), 1 settings sub-screen (`AabarConsentAuditScreen`), ~8 widget files, 2 Cubit files, 1 repository abstract + 1 impl, 1 DI file, 6 model files, 25 localization keys. Home section wiring: 1 `case` branch in `HomeSectionsItem`. Diary CTA wiring: 1 conditional widget in diary detail screen.

## Constitution Check

*Pre-design gate.*

- [x] **I. Feature-First Layout** — new code lands under `lib/features/aabar/` mirroring `chat/`
- [x] **II. Dependency Direction** — no feature-to-feature imports; feature-root `aabar_di.dart` registered in `lib/core/dependency_injection/di.dart`
- [x] **III. Networking Contract** — all REST calls via `NetworkClient.handleRequest` returning `Either<Failure, T>`; no manual auth headers; absolute webhook URL handled by Dio 5 (see R1 in research.md)
- [x] **IV. Persistence Discipline** — session-only conversation; no Hive writes; consent ledger is server-owned and mobile-read only
- [x] **V. Flavor Branching** — `context.isParents` / `context.isProfessors` for suggestion chips and diary CTA seed text; both flavors must be verified before merge
- [x] **VI. Localization** — 25 `aabar_*` keys added to `localization_keys.dart` + PT-BR + EN translations; AR TBD by localization team
- [x] **VII. Realtime Surfaces Source of Truth** — not applicable; AABAR uses REST webhook only, no Firestore
- [x] **VIII. Approval Gate** — home section tile served only to approved users (gated server-side via `Config`); diary CTA gated on `isApproval`; any deep link or push handler routes unapproved users to `your_account_under_review`
- [x] **IX. Medicine Reminders** — not applicable
- [x] **X. Theming & Sizing** — `flutter_screenutil` 430×932; theme pulled from `ConfigCubit.styling`; no hardcoded colors
- [x] **Quality Gates** — `flutter analyze` planned for both flavors; release build planned for both flavors before merge

No violations. Complexity Tracking section is blank.

*Post-design re-check (Phase 1 complete)*: No additional violations surfaced during design. III confirmed: Dio 5 absolute-URL behavior verified in research (R1). VI confirmed: 25-key table fully specified in spec.md localization requirements.

## Project Structure

### Documentation (this feature)

```text
specs/aabar/
├── plan.md                  # This file
├── research.md              # Phase 0 output
├── data-model.md            # Phase 1 output
├── quickstart.md            # Phase 1 output
├── contracts/               # Phase 1 output
│   ├── rest-endpoints.md
│   └── config-schema.md
├── checklists/
│   └── requirements.md      # created by /speckit-specify
└── tasks.md                 # Phase 2 output (/speckit.tasks — not created here)
```

### Source Code (new files)

```text
lib/features/aabar/
  aabar_di.dart                           # DependencyInjection — feature root
  data_sources/
    aabar_repository.dart                 # abstract contract
    aabar_impl.dart                       # NetworkClient.handleRequest with full webhook URL
  models/
    aabar_message.dart                    # AABARMessage (role, text, timestamp, contextAttached, errorReason)
    aabar_conversation.dart               # AABARConversation (session-local list + disclaimer state)
    aabar_request_payload.dart            # wire format (prompt, role, school_id, lang, child_context?)
    aabar_child_context.dart              # AABARChildContext (child_id, recent_activities, consent_token)
    aabar_consent_ledger_entry.dart       # server-read consent audit entry
    aabar_suggestion_chip.dart            # AABARSuggestionChip (key, text, flavor)
  presentation/
    bloc/
      aabar_cubit.dart                    # Cubit<AABARState>
      aabar_state.dart
      aabar_consent_audit_cubit.dart      # Cubit<AABARConsentAuditState>
      aabar_consent_audit_state.dart
    widgets/
      aabar_chat_surface.dart             # scroll list + chips + disclaimer
      aabar_message_bubble.dart           # user / assistant / error variants
      aabar_suggestion_chips_row.dart     # 4 chips, flavor-conditional
      aabar_disclaimer_banner.dart        # full banner ↔ pinned footnote
      aabar_composer.dart                 # text field + child-context toggle + send
      aabar_child_picker_sheet.dart       # bottom sheet: pick child when >1 linked
    aabar_screen.dart                     # top-level navigator target
    aabar_consent_audit_screen.dart       # settings sub-screen

lib/core/localization/localization_keys.dart   ← 25 new aabar_* keys
assets/langs/pt.json                           ← 25 translations (primary)
assets/langs/en.json                           ← 25 translations
assets/langs/ar.json                           ← 25 keys (TBD by localization team)
```

**Home tile wiring** (`lib/features/home/widgets/home_sections_item.dart`):
- Add `case 'aabar':` to the existing switch statement → navigate to `AabarScreen()`
- Section entry is server-driven via `Config.get.homeSections`; home shows AABAR when the backend includes the `aabar` section (controlled per-school via Firestore)

**Diary CTA wiring** (diary entry detail screen):
- Add a conditional action widget gated on `context.isApproval && aabarWebhookUrl.isNotEmpty`
- On tap: navigate to `AabarScreen(seedPrompt: flavorSeedText, fromDiary: activity)` with child-context pre-ticked

**Settings entry** (settings shell):
- Add "Meus consentimentos AABAR" row routing to `AabarConsentAuditScreen`
- Gate on `aabarWebhookUrl.isNotEmpty`

**DI registration**: `AabarInjection` added to the list in `lib/core/dependency_injection/di.dart` → `dependencyInjection()`.

## Complexity Tracking

*No constitution violations to justify. Section intentionally blank.*
