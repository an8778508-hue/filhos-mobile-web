---
status: migrated
feature: terms_and_condtions
migrated_from: lib/features/terms_and_condtions/
migrated_date: 2026-05-14
---

# Implementation Plan: Terms and Conditions

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/terms_and_condtions/spec.md](spec.md) and code in [lib/features/terms_and_condtions/](../../lib/features/terms_and_condtions/).

## Summary

A small REST-backed screen that fetches HTML terms from `pages/terms-conditions` and renders it via the shared `TextHtml` widget. The bloc *also* knows how to fetch the privacy policy, but no screen dispatches that event — `privacy_policy/` is its own feature using a WebView ([privacy_policy_screen.dart](../../lib/features/privacy_policy/privacy_policy_screen.dart)). The folder name carries a typo (`terms_and_condtions/` — missing `i`); rename is tracked at the cross-feature level.

The features.md description ("Static / WebView terms") is **inaccurate** — this is REST + `TextHtml`, not a WebView.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `TermsBloc` is a `Bloc<TermsEvents, TermsStates>`.
- `get_it` — `TermsRepo` registered as `Singleton` and `TermsBloc` as `Factory` in [core/dependency_injection/di.dart:123-124](../../lib/core/dependency_injection/di.dart#L123-L124).
- `dio` (via `NetworkClient`).
- `dartz` — `Either<Failure, String>`.
- `flutter_html` (via shared `TextHtml`).
- `flutter_screenutil` — `.h` padding.

**Storage**: none.

**Testing**: none today.

**Target Platform**: iOS + Android, both flavors.

**Project Type**: Flutter mobile feature, standard layout with `bloc/`, `repo/`, and the screen at the feature root.

**Performance Goals**: First-byte renders within 1 s on 4G.

**Constraints**:

- Must work without `Authorization` (reachable from Login).
- Must tolerate `null` content payload.
- Must localize the app-bar title; body content is server-localized.

**Scale/Scope**: 5 .dart files, ~110 LOC total.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/{events,states,bloc}.dart` + `repo/terms_repo.dart` + `terms_and_conditions_screen.dart`. ⚠️ No per-feature `terms_di.dart`; DI registration lives in `core/dependency_injection/di.dart`.
- [x] **II. Dependency Direction** — only `core/*` imports. ✓
- [x] **III. Networking Contract** — REST via `NetworkClient.handleRequest`; `Either<Failure, String>`. ✓
- [x] **IV. Persistence Discipline** — no direct Hive use. ✓
- [x] **V. Flavor Branching** — no `mainKey.currentContext` use. ✓
- [x] **VI. Localization** — title via `LocalizationKeys.terms_and_conditions.tr(context)`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — pre-gate access required (Login inline link) — feature works without auth. ✓
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h` sizing; no hardcoded colors. ✓

⚠️ **Folder typo** — `terms_and_condtions/` (constitution principle I covers naming consistency; this violates it). Tracked at [features.md cross-feature P2](../features.md#cross-feature-tasks) "Rename `terms_and_condtions/` → `terms_and_conditions/`".

## Project Structure

### Documentation (this feature)

```text
specs/terms_and_condtions/    # typo preserved to match code
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/terms_and_condtions/   # ⚠️ folder name typo (missing 'i')
├── bloc/
│   ├── terms_bloc.dart              # Bloc<TermsEvents, TermsStates>
│   ├── terms_events.dart            # @immutable abstract — not a sealed class
│   └── terms_states.dart            # TermsStates wrapper + TermsState({data, loading, error})
├── repo/
│   └── terms_repo.dart              # getTerms / getPrivacy (the latter is dead today)
└── terms_and_conditions_screen.dart  # ⚠️ file name correctly spelled; folder is not
```

### Cross-feature touch points

- [lib/features/settings/settings_screen.dart](../../lib/features/settings/settings_screen.dart) (line 222) — Settings list item.
- [lib/features/login/presentation/login_screen.dart](../../lib/features/login/presentation/login_screen.dart) — inline link.
- [lib/features/register/presentation/register_screen.dart](../../lib/features/register/presentation/register_screen.dart) — inline link.
- [lib/core/components/text/text_html.dart](../../lib/core/components/text/text_html.dart) — body renderer.
- [lib/core/components/widgets/app_bar.dart](../../lib/core/components/widgets/app_bar.dart) — `MyAppBar`.
- [lib/core/components/loading/loading_overlay.dart](../../lib/core/components/loading/loading_overlay.dart).

**Structure Decision**: Rename the folder once the dependent imports are updated. Drop the unused `FetchPrivacy` branch or migrate `privacy_policy/` onto this bloc. Extract DI into `terms_di.dart`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| `Bloc` with two events that share state | Future-proofed for serving both terms and privacy from one surface. | Cubit with two methods is leaner; would still work. |
| Folder name typo (`terms_and_condtions`) | Historical. | Rename + update imports — tracked. |
| `FetchPrivacy` event handler is unreferenced | Originally planned to share this screen between terms and privacy, but `privacy_policy/` ended up using a WebView for layout fidelity. | Delete or migrate `privacy_policy/` onto this bloc. |
| No per-feature `terms_di.dart` | Co-located with `GalleryRepo`/`FeaturedEventsBloc` in `core/dependency_injection/di.dart`. | Extract — mechanical. |
| No client-side cache | Document is small and changes rarely. | Add a stale-while-revalidate cache via `LocalDatabaseRepo` — optional. |
| No error UI when `state.aboutState.error != null` | Original scope was happy-path only. | Add a retry button — see tasks. |
| Two parallel "static document" features (this + `privacy_policy/`) using different rendering paths | Privacy policy uses a WebView (`webview_flutter`); terms uses `flutter_html` via `TextHtml`. | Unify on one approach. See [features.md privacy_policy P1](../features.md#privacy_policy--b). |
