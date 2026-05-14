---
status: migrated
feature: terms_and_condtions
migrated_from: specs/features.md#terms_and_condtions--b
migrated_date: 2026-05-14
---

# Tasks: Terms and Conditions

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#terms_and_condtions--b](../features.md#terms_and_condtions--b).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

## Migration summary

- 5 .dart files: `bloc/terms_{bloc,events,states}.dart`, `repo/terms_repo.dart`, `terms_and_conditions_screen.dart`.
- DI registration: [core/dependency_injection/di.dart:123-124](../../lib/core/dependency_injection/di.dart#L123-L124).
- Reachable from: Settings → Terms ([settings_screen.dart:222](../../lib/features/settings/settings_screen.dart#L222)), Login inline link, Register inline link.
- Folder name has a typo (`terms_and_condtions/`) — spec folder mirrors it.
- features.md describes this as a "WebView wrapper" — that's **inaccurate**; the implementation is REST + `flutter_html` via `TextHtml`. The WebView path lives in `privacy_policy/`.

## Phase 1: Setup — ✅ Complete

- [x] **T-001**: Create `lib/features/terms_and_condtions/` with `bloc/` + `repo/`.
- [x] **T-002**: Register `TermsRepo` (Singleton) and `TermsBloc` (Factory) in DI.
- [x] **T-003**: Add `LocalizationKeys.terms_and_conditions` and translations in pt/en/ar.

## Phase 2: User Story 1 — Render Terms (P1) — ✅ Complete

- [x] **T-010**: Implement `TermsRepo.getTerms()` via `NetworkClient.handleRequest` against `GET pages/terms-conditions`.
- [x] **T-011**: Implement `TermsBloc` handling `FetchTerms` → emit fetching → emit success/failed.
- [x] **T-012**: Render `TextHtml(state.aboutState.data ?? '')` inside a `SingleChildScrollView` with a `LoadingOverlay` while loading.
- [x] **T-013**: Wire `BlocProvider(create: di<TermsBloc>()..add(const FetchTerms()))`.
- [x] **T-014**: Reachable from Settings + Login + Register links.

## Phase 3: Gaps & cleanups

### Constitution drift fixes

- [ ] **T-fix-1** [P2] **Carry-over from [features.md `terms_and_condtions`](../features.md#terms_and_condtions--b) and [cross-feature P2](../features.md#cross-feature-tasks)**: Rename folder `terms_and_condtions/` → `terms_and_conditions/`. Coordinate with all imports — grep confirms 9 files reference the path. This spec folder (`specs/terms_and_condtions/`) must rename in lockstep.

- [ ] **T-fix-2** [P2] Resolve the `FetchPrivacy` dead-code dilemma:
  - **Option A**: Delete `FetchPrivacy` from events + repo + bloc handler. Cleaner.
  - **Option B**: Migrate `privacy_policy/` to dispatch `FetchPrivacy` against this bloc and replace its WebView with `TextHtml` (matching this feature). Unifies on a single rendering path.
  - Option B is preferred because the privacy_policy WebView is flagged for [P1 hardening](../features.md#privacy_policy--b) anyway (navigation allowlist + background color).

- [ ] **T-fix-3** [P2] **Add an error UI**: today on failure the bloc emits `failed(message)` but `terms_and_conditions_screen.dart` only consumes `state.aboutState.loading` and `state.aboutState.data`. The user sees a blank screen. Show a retry CTA.

- [ ] **T-fix-4** [P2] **Add a client-side cache**: terms content is small and changes rarely. Persist the last successful body to Hive via `LocalDatabaseRepo`; serve the cache, refresh in the background. Improves offline UX.

- [ ] **T-fix-5** [P3] Extract DI registration into `lib/features/terms_and_condtions/terms_di.dart` implementing `DependencyInjection`.

- [ ] **T-fix-6** [P3] Use a `sealed class TermsEvents` (matching `background_services` and `login` patterns). Today it's `@immutable abstract class TermsEvents`.

- [ ] **T-fix-7** [P3] **Update features.md description**: change "Static / WebView terms" → "REST-driven `TextHtml` terms". The current copy misleads new contributors into using `webview_flutter`. This spec-kit migration is the right artifact to point at instead.

### Code hygiene

- [ ] **T-cleanup-1** Confirm the server is using `Accept-Language` / `lang` header to localize the body. If not, file a backend ticket. Today the standard interceptor adds `lang`; verify the `pages/*` route reads it.

- [ ] **T-cleanup-2** When the rename in T-fix-1 lands, ensure `Navigator.push(... TermsAndConditions ...)` sites all update if any are passing a route name (currently none — all use `MaterialPageRoute(builder: ...)`).

### Tests (aspirational)

- [ ] **T-test-1** [P] Bloc test: `FetchTerms` → success → state.data populated.
- [ ] **T-test-2** [P] Bloc test: `FetchTerms` → failure → state.error populated.
- [ ] **T-test-3** Repo test: `getTerms` parses `{data: {content: null}}` to empty string.
- [ ] **T-test-4** Widget test: loading overlay covers the body during fetch; clears on success.

## Phase 4: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after the folder rename — expect many import path changes but no semantic warnings.
- [ ] **TX02** [X] Smoke-test on both flavors that the terms screen renders the same content (no flavor branch should exist).
- [ ] **TX03** [X] Smoke-test offline: opening the screen with airplane mode shows the loading overlay then a blank body. After T-fix-3 + T-fix-4 this should show a cached body or a retry CTA.

## Dependencies & Execution Order

- **Phases 1–2 are complete.**
- **Phase 3** order:
  1. T-fix-3 (error UI) — single file, no cross-feature risk.
  2. T-fix-7 (features.md description) — doc-only.
  3. T-fix-4 (cache) — independent.
  4. T-fix-2 (decide privacy_policy merger) — needs design decision.
  5. T-fix-1 (folder rename) — touches many files; do after the dust settles.
  6. T-fix-5 / T-fix-6 (DI extraction + sealed events) — mechanical cleanups.

## Constitution drift fixes (summary table)

| Drift | Source | Status |
|---|---|---|
| Folder name typo `terms_and_condtions/` | features.md cross-feature P2 | Open (T-fix-1) |
| `FetchPrivacy` is dead code | this migration | Open (T-fix-2) |
| No error UI on fetch failure | this migration | Open (T-fix-3) |
| No client-side cache | this migration | Open (T-fix-4) |
| DI not in feature-root `terms_di.dart` | this migration | Open (T-fix-5) |
| Events not a `sealed class` | this migration | Open (T-fix-6) |
| features.md description inaccurate ("WebView") | this migration | Open (T-fix-7) |

## Gaps found

- The features.md one-liner is **wrong** about this being a WebView. The actual rendering path is REST + `TextHtml`.
- The `FetchPrivacy` plumbing is built and unused. Either delete it or fold `privacy_policy/` into this surface.
- There is **no error UI**. A failed fetch silently leaves the user on a blank page.
- There is **no cache**. Every screen open is a round-trip; bad offline UX.
- The folder name typo is a low-cost win that has been pending since launch.
- This feature is reachable **pre-auth** (Login inline link). Verify the server does not require `Authorization` on `pages/*` — if it does, anonymous users will see a 401.
