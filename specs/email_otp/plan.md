# Implementation Plan: Email OTP — login by email-delivered code

**Branch**: `(Nour_main — alongside sibling work)` | **Date**: 2026-05-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/email_otp/spec.md`

## Summary

Add an email-delivered OTP login path so users in regions with unreliable SMS providers can still authenticate. Login screen gains a **"Telefone" / "E-mail"** tab picker (rendered only when the global `email_otp_globally_visible` flag is on). The email path POSTs to two new REST endpoints on `criarte.filhos.app` — `/auth/email-otp/send` and `/auth/email-otp/verify` — that reuse the existing access-token mint path. The backend generates a 6-digit code, hashes it, and writes a doc to the Firestore `mail/{autoId}` collection; the **Firebase Extension "Trigger Email from Firestore"** picks it up and dispatches via SendGrid SMTP. The same `OTPScreen` is reused with a new `OTPDeliveryMode mode` parameter that swaps the icon (envelope vs. phone), the subline ("Código enviado para s\*\*\*@example.com"), and the spam-folder hint. Per-school enablement is enforced **server-side** (`config/{schoolId}.email_otp_enabled` in Firestore) — mobile never reads that flag directly.

Implementation approach: **extend existing features rather than creating a new feature folder.** `LoginRepository` gets `requestEmailOTP()` and `confirmEmailOTP()` methods. `OTPBloc` (already centrally registered in `di.dart`) gets a `mode` field and parallel `requestEmailOTP`/`confirmEmailOTP` paths sharing the cooldown timer. The email-tab widget lives under `lib/features/login/presentation/widgets/`. New Hive keys (`last_email_otp_request`, `last_email_otp_email`, `last_login_mode`) accessed via `LocalDatabaseRepo` keep cooldowns separate so a stuck SMS cooldown doesn't block an email retry.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3 (FVM-pinned via [.fvmrc](../../.fvmrc))

**Primary Dependencies**: `flutter_bloc` 9, `get_it` 8, `dio` 5, `hive` 2 (via `LocalDatabaseRepo`), Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore` — used **server-side**, not by the mobile app for this feature), `flutter_screenutil`

**New Dependencies**: **None on mobile**. Server-side adds the **Firebase Extension "Trigger Email from Firestore"** to the `escola-cede2` Firebase project + **SendGrid SMTP** credentials (free tier 100/day).

**Storage**: Hive via `LocalDatabaseRepo` with three new keys: `last_email_otp_request` (millis), `last_email_otp_email` (string), `last_login_mode` (string: `"sms" | "email"`). No HydratedBloc state changes. No Firestore reads on mobile.

**Testing**: No test suite exists today. This feature adds no tests in v1 (note for tasks.md follow-up).

**Target Platform**: iOS + Android, **both flavors** (`parents` and `professores`). Behaviour is identical across flavors.

**Performance Goals**:
- p95 `/send` latency ≤ 1.5 s (server-side bound; the Firestore-write + validation, not SMTP send) — SC-EM-06
- 95% of OTP emails delivered within 30 s of `/send` success — SC-EM-01
- Login completion within 5 minutes of `/send` ≥ 90% for email-tab users — SC-EM-03

**Constraints**:
- Mobile must NOT read `config/{schoolId}.email_otp_enabled` (FR-EM-20) — pre-login the schoolId is unknown
- Email and OTP code must NOT appear in Crashlytics breadcrumbs (FR-EM-18) — extend the existing `_redactBody` allowlist
- The same `OTPScreen` widget renders both SMS and email modes — no widget duplication
- Cooldown must be separate per mode so a stuck SMS cooldown doesn't block email retry (FR-EM-14)

**Scale/Scope**: 2 new REST endpoints, 1 widget (`email_tab.dart`), 1 widget edit (`OTPScreen` adds mode-aware chrome), 1 edit (`LoginScreen` adds tab picker conditional on global flag), 4 new methods on `LoginRepository` interface + impl (request + confirm + the two payload models' wire methods), ~6 new states/events on `OTPBloc` (or parallel methods on the existing Cubit), 15 new localization keys, 3 new Hive keys, 0 new feature folders.

## Constitution Check

*Pre-design gate — verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md) v1.3.0.*

- [x] **I. Feature-First Layout** — extends `lib/features/login/` and `lib/features/otp/` rather than creating a new feature folder. Mirrors existing OTP pattern (thin feature, central DI, uses LoginRepository). New widget lives under `login/presentation/widgets/email_tab.dart` matching siblings.
- [x] **II. Dependency Direction** — no new feature-to-feature imports. `OTPBloc` already depends on `LoginRepository`; the new methods extend that existing relationship. New widget is in `login/`, not a separate feature, so no cross-feature widget import.
- [x] **III. Networking Contract** — both new endpoints go through `NetworkClient.handleRequest` returning `Either<Failure, T>`. Auth headers (none here — pre-login endpoint) handled by interceptor. `school`/`school_id`/`lang` headers automatically attached but ignored by these pre-login endpoints (harmless).
- [x] **IV. Persistence Discipline** — all three new keys (`last_email_otp_request`, `last_email_otp_email`, `last_login_mode`) accessed via `LocalDatabaseRepo`, never via Hive directly. No HydratedBloc state changes.
- [x] **V. Flavor Branching** — feature is identical across flavors. No `context.isParents` / `context.isProfessors` checks needed.
- [x] **VI. Localization** — 15 new `email_otp_*` keys added to `localization_keys.dart` with PT-BR (primary) + EN translations. AR placeholder keys present; localization team supplies AR copy. Email-body templates live separately in Firestore `email_templates/email_otp_{lang}` and are remote-overridable like all other translations.
- [x] **VII. Realtime Surfaces Source of Truth** — not applicable. Mobile uses REST only. The `mail/{autoId}` Firestore collection is **server-write-only**; mobile never reads it.
- [x] **VIII. Approval Gate** — verify path reuses `UserBloc.loggedIn(user)` exactly like SMS OTP. The `isApproval == false` → `YourAccountUnderReviewScreen` routing is unchanged.
- [x] **IX. Medicine Reminders** — not applicable.
- [x] **X. Theming & Sizing** — `flutter_screenutil` 430×932; theme from `ConfigCubit.styling`; no hardcoded colors. The new tab picker uses existing `context.colors.*` extensions.
- [x] **Quality Gates** — `flutter analyze` planned for both flavors; release build planned before merge.

No violations. Complexity Tracking section is blank.

*Post-design re-check*: No new violations surfaced in design. The decision to extend `LoginRepository` and `OTPBloc` rather than fork into a new feature was the principal architectural choice; it aligns with Principle I ("mirror the closest sibling") and Principle II (thin features get central DI).

## Project Structure

### Documentation (this feature)

```text
specs/email_otp/
├── plan.md                              # This file
├── research.md                          # Phase 0 output
├── data-model.md                        # Phase 1 output
├── quickstart.md                        # Phase 1 output
├── contracts/                           # Phase 1 output
│   ├── rest-endpoints.md
│   └── firestore-mail-schema.md
└── tasks.md                             # Phase 2 output (generated alongside this plan)
```

### Source Code (changes by file)

```text
lib/features/login/
├── data_sources/
│   ├── login_repository.dart            ← add 2 methods: requestEmailOTP, confirmEmailOTP
│   └── login_impl.dart                  ← implement the 2 methods via NetworkClient.handleRequest
├── models/
│   ├── email_otp_send_request.dart      ← NEW {email, lang} payload
│   ├── email_otp_send_response.dart     ← NEW {maskedEmail, retryAfter}
│   ├── email_otp_verify_request.dart    ← NEW {email, code}
│   └── email_otp_verify_response.dart   ← NEW alias for UserModel + token (reuses existing response shape)
└── presentation/
    ├── login_screen.dart                ← add tab picker (visible only when ConfigCubit.emailOtpGloballyVisible == true)
    └── widgets/
        └── email_tab.dart               ← NEW: email field + Send CTA + format validation

lib/features/otp/
├── presentation/
│   ├── bloc/
│   │   └── otp_bloc.dart                ← add mode-aware methods: requestEmailOTP, confirmEmailOTP
│   │                                      reuse _startTimer / cooldown for both modes
│   │                                      add `OTPDeliveryMode mode` field on OTPState
│   ├── otp_screen.dart                  ← accept `mode: OTPDeliveryMode` ctor parameter
│   │                                      render envelope icon + email-mode subline when mode == email
│   └── widgets/
│       └── delivery_mode_chrome.dart    ← NEW: reusable widget swapping icon/subline by mode
└── models/
    └── otp_delivery_mode.dart           ← NEW enum: { sms, email }

lib/core/
├── localization/
│   └── localization_keys.dart           ← 15 new email_otp_* keys
├── local_db/
│   └── local_db_repo.dart               ← 3 new LocalKeys: last_email_otp_request, last_email_otp_email, last_login_mode
├── config/
│   └── cubit/ (or state file)           ← add emailOtpGloballyVisible: bool (default false); update toJson/fromJson
└── network/
    └── network_client.dart              ← extend _redactBody allowlist to redact /auth/email-otp/* payloads

assets/langs/
├── pt.json                              ← 15 translations (primary)
├── en.json                              ← 15 translations
└── ar.json                              ← 15 keys (TBD by localization team)
```

**No new feature folder.** Email OTP threads through the existing `login/` + `otp/` features. The `specs/email_otp/` folder exists purely as a product-grouping artifact, not a mirror of a code folder.

**DI**: `OTPBloc` is already registered centrally in `lib/core/dependency_injection/di.dart:87`. Adding mode-aware methods doesn't change its constructor signature, so DI wiring is unchanged. The new repository methods extend the existing `LoginRepository` interface — no new DI registrations.

**Server-side** (out of mobile scope but tracked):
- Firebase Extension **"Trigger Email from Firestore"** installed in the `escola-cede2` project
- SendGrid SMTP credentials configured in the extension
- `email_templates/email_otp_{pt,en,ar}` Firestore template docs created with `{{code}}` placeholders
- DKIM + SPF records for the sender domain (e.g., `noreply@criarte.filhos.app`) before pilot
- `config/{schoolId}.email_otp_enabled` flag set per pilot school

## Complexity Tracking

*No constitution violations to justify. Section intentionally blank.*
