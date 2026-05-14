---
status: migrated
feature: privacy_policy
migrated_from: lib/features/privacy_policy/
migrated_date: 2026-05-14
---

# Implementation Plan: Privacy Policy

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

## Summary

Single-screen WebView wrapper around the school's privacy URL. 1 .dart file, ~85 LOC. No bloc, no data layer, no models. Reads `Config.get.appInfo.privacyUrl` and renders. Also intercepts `payment/status/success` redirects (a payment-flow coupling that should be teased apart later).

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3

**Primary Dependencies**:

- `webview_flutter` 4.x — the only non-Flutter dependency in the file
- `flutter_screenutil` 5.9 — sizing (used by shared widgets)
- `ConfigCubit` (read-only) — source of the URL

**Storage**: none directly. The URL is owned by `ConfigCubit` (HydratedCubit).

**Testing**: None today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature; **single file at feature root** (no `presentation/` subdir — unusual; most features use `presentation/`).

**Performance Goals**: WebView first paint < 5 s on 4G. No blocking work on the main isolate.

**Constraints**:

- `JavaScriptMode.unrestricted` is enabled and there is **no navigation-host allowlist** — phishing vector flagged by [features.md (P1)](../features.md#privacy_policy--b).
- The screen serves two purposes (privacy display + payment-success interception) — a coupling that should be split.
- No error path; transient network failures leave the spinner spinning.

**Scale/Scope**: 1 .dart file, ~85 LOC.

## Constitution Check

- [x] **I. Feature-First Layout** — `lib/features/privacy_policy/privacy_policy_screen.dart` lives at feature root (not under `presentation/`). Minor deviation from the dominant pattern but matches what some single-file features do. Acceptable.
- [x] **II. Dependency Direction** — no DI to register; no bloc.
- [x] **III. Networking Contract** — N/A (WebView, not `NetworkClient`).
- [x] **IV. Persistence Discipline** — N/A (consumes hydrated `ConfigCubit`).
- [x] **V. Flavor Branching** — none; correct.
- [x] **VI. Localization** — `privacy_policy` title via `LocalizationKeys`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [ ] **VIII. Approval Gate** — N/A (pre-login surface; gate must not apply).
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — no hardcoded colors visible; uses `MyAppBar`. ✓

## Project Structure

### Documentation (this feature)

```text
specs/privacy_policy/
├── spec.md
├── plan.md   (this file)
└── tasks.md
```

### Source Code (existing)

```text
lib/features/privacy_policy/
└── privacy_policy_screen.dart   # single file at feature root
```

### Cross-feature touch points

- **[lib/features/login/presentation/login_screen.dart:421](../../lib/features/login/presentation/login_screen.dart#L421)** — inline privacy link push.
- **[lib/features/register/presentation/register_screen.dart:311](../../lib/features/register/presentation/register_screen.dart#L311)** — inline privacy link push.
- **[lib/core/config/config.dart](../../lib/core/config/config.dart)** — `Config.get.appInfo.privacyUrl` source.

**Structure Decision**: Single-file at feature root. No subdirectories needed today. If/when error handling, host-allowlist config, and payment-success extraction land, a `presentation/` + small `models/` (e.g. `AllowedHost`) layout becomes appropriate.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `JavaScriptMode.unrestricted` on a remote URL without a navigation allowlist | The published policy doc may rely on JS for accessibility / analytics. | Add a host allowlist via `onNavigationRequest` (return `prevent` for hosts outside the list). [features.md (P1)](../features.md#privacy_policy--b). See [tasks.md T-fix-1](tasks.md). |
| Single-screen feature serving two purposes (privacy display + payment-success interception) | Historical reuse. | Split: dedicated `PaymentResultWebView` for the payment flow. [tasks.md T-fix-4](tasks.md). |
| No `onWebResourceError` handler | Skipped at build time. | Add error UI + retry CTA. [tasks.md T-fix-3](tasks.md). |
| Screen file at feature root rather than `presentation/` | The feature is one file; adding `presentation/` adds nesting with no benefit today. | When the screen grows (error widget, allowlist config), promote to `presentation/`. |
