---
status: migrated
feature: privacy_policy
migrated_from: specs/features.md#privacy_policy--b
migrated_date: 2026-05-14
---

# Tasks: Privacy Policy

**Input**: [spec.md](spec.md), [plan.md](plan.md), [features.md#privacy_policy--b](../features.md#privacy_policy--b).

**Tests**: No `test/` directory; tests aspirational.

## Migration summary

Single-screen WebView (1 .dart file, ~85 LOC). Surfaced from login + register. URL from `Config.get.appInfo.privacyUrl`. No bloc / data layer / models. Three open follow-ups: nav-host allowlist (P1, security), white-flash background (P1, polish), environment-aware URL audit.

---

## Phase 1: Setup — Complete

- [x] T001 Create [lib/features/privacy_policy/](../../lib/features/privacy_policy/)
- [x] T002 Reserve localization key `privacy_policy` at [localization_keys.dart:78](../../lib/core/localization/localization_keys.dart#L78)
- [x] T003 PT / EN translations present in [assets/langs/](../../assets/langs/)
- [x] T004 AR translation — verify per [features.md cross-feature task](../features.md#cross-feature-tasks) (~40% of repo-wide keys flagged as missing in AR)

## Phase 2: Foundational — Complete

- [x] T010 Pick `webview_flutter` 4.x. No bloc / repo needed for a static remote document.

## Phase 3: User Story 1 — View the privacy policy (P1) MVP — Complete

- [x] T020 [US1] Build [`PrivacyPolicy`](../../lib/features/privacy_policy/privacy_policy_screen.dart) with `WebViewController` + `MyAppBar`
- [x] T021 [US1] Wire `JavaScriptMode.unrestricted` (⚠️ paired with the missing host allowlist — see T-fix-1)
- [x] T022 [US1] Loading overlay via `Stack` + `isLoading` flag toggled on `onPageStarted` / `onPageFinished`
- [x] T023 [US1] Inline "privacy policy" link in [login_screen.dart:421](../../lib/features/login/presentation/login_screen.dart#L421) and [register_screen.dart:311](../../lib/features/register/presentation/register_screen.dart#L311)

## Phase 4: User Story 2 — Payment success interception (P3) — Complete

- [x] T030 [US2] Intercept `payment/status/success` in `onNavigationRequest` and `Navigator.pop(context, true)` ([privacy_policy_screen.dart:25-28](../../lib/features/privacy_policy/privacy_policy_screen.dart#L25-L28))

---

## Phase 6: Gaps & cleanups (from this migration's review)

### Security / drift

- [ ] **T-fix-1** **(P1)** *(from [features.md](../features.md#privacy_policy--b))* **Add a navigation-host allowlist.** With `JavaScriptMode.unrestricted` on a remote URL, any link in the page loads in-app — phishing surface. In `onNavigationRequest`, only allow URLs whose host matches a small allowlist (the school's privacy host, perhaps `criarte.filhos.app` and a handful of known CDNs). Return `NavigationDecision.prevent` and optionally launch external links via `url_launcher` for any host outside the list.

- [ ] **T-fix-2** **(P1)** *(from [features.md](../features.md#privacy_policy--b))* **Set `WebView.setBackgroundColor`** to the scaffold color (e.g. `context.colors.background` or `Colors.transparent`) to avoid the white flash before first paint.

- [ ] **T-fix-3** **(P2)** Add `onWebResourceError` handler with a user-visible error widget + retry CTA. Today a network failure leaves the spinner spinning forever.

- [ ] **T-fix-4** **(P2)** **Decouple payment-success interception** from this screen. The privacy WebView serves two purposes (privacy display + payment-redirect detection). Extract a dedicated `PaymentResultWebView` and remove the `payment/status/success` branch from `PrivacyPolicy`.

- [ ] **T-fix-5** **(P2)** *(from [features.md](../features.md#privacy_policy--b))* Confirm policy URL is environment-aware (no prod URL in staging). Audit the Firestore `config/*` documents per environment and document the contract in [CLAUDE.md](../../CLAUDE.md).

- [ ] **T-fix-6** **(P2)** Defensive guard: bail out if `Config.get.appInfo.privacyUrl` is null/empty. Today `Uri.parse(null)` would crash. Either short-circuit with a localized "no policy configured" error or fall back to a bundled `assets/legal/privacy_default.html`.

### Code hygiene

- [ ] **T-cleanup-1** Promote the file to `lib/features/privacy_policy/presentation/privacy_policy_screen.dart` to match the dominant feature layout. Update all imports.

- [ ] **T-cleanup-2** Class name `PrivacyPolicy` is generic; rename to `PrivacyPolicyScreen` for consistency with neighbour screens.

- [ ] **T-cleanup-3** Initialize `controller` in `initState` *after* `super.initState()` (today `super.initState()` is called *after* `controller.loadRequest(...)` at line 52 — works but unconventional).

### Tests (aspirational)

- [ ] **T-test-1** [P] [US1] Widget test: screen mounts and `controller.loadRequest` is called with the URL from `Config.get.appInfo.privacyUrl`.
- [ ] **T-test-2** [P] [US1] Widget test: `onPageFinished` hides the loading overlay.
- [ ] **T-test-3** [P] [US2] Widget test: navigation to `…/payment/status/success` pops with `true`.
- [ ] **T-test-4** [P] [US1] Widget test: a navigation request to an out-of-allowlist host is rejected (gated on T-fix-1).

---

## Phase 7: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-* and T-cleanup-*
- [ ] **TX02** [X] Verify the screen on both flavors (no flavor branching expected — same WebView)

---

## Constitution Drift Fixes (summary)

| ID | Drift | Severity |
|----|-------|----------|
| T-fix-1 | `JavaScriptMode.unrestricted` + no host allowlist on a remote URL | High (P1, security) |
| T-fix-2 | White flash on first paint | Low (P1, polish) |
| T-fix-3 | No error path on WebView load failure | Medium (P2) |
| T-fix-4 | Single screen with two unrelated responsibilities | Low (P2, refactor) |

## Gaps Found

- **Phishing-surface WebView** — no nav-host allowlist; any link inside the page loads in-app under JS.
- **No error UI** — transient failures leave the user staring at a spinner.
- **No environment guard on the URL** — staging may load production privacy doc if `config/*` is not split per environment.
- **Payment-flow coupling** — `payment/status/success` interception piggybacks on this screen; should be a separate WebView.
- **`Uri.parse(null)` crash potential** when `privacyUrl` is empty.

## Notes

- This is a **migration** — `[x]` items are inferred from existing code + [features.md](../features.md).
- The same WebView pattern is repeated in [terms_and_condtions/](../../lib/features/terms_and_condtions/) (note: folder name typo); same allowlist / background-color / error-UI gaps likely apply there too. Coordinate fixes.
