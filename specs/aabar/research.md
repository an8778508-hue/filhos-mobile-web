# Research: AABAR — in-app ABA chat agent

Phase 0 research decisions. All NEEDS CLARIFICATION markers from spec.md were resolved during `/speckit-specify` on 2026-05-15 (see spec.md §Resolved Decisions). This file captures the implementation-level unknowns.

---

## R1: REST client — absolute webhook URL with existing NetworkClient

**Decision**: Pass the full AABAR webhook URL (stored in `ConfigCubit`) as `NetworkRequest.url`. Dio 5 recognizes absolute URLs (starting with `https://`) and uses them directly, ignoring the configured `baseUrl` (`criarte.filhos.app/api/v1/`). The existing `NetworkInterceptor` still runs on every request, adding:
- `Authorization: Bearer <token>` — **needed** (n8n validates this token)
- `school`/`school_id` headers — **harmless** (n8n ignores unknown headers; school_id is also in the body)
- `lang` header — **harmless** (lang is also in the body)

No new `Dio` instance. No new interceptor stack. No manual auth header.

**Rationale**: Avoids creating a fresh `Dio()` (the anti-pattern flagged in `share_button.dart` and blocked by constitution Principle III). Keeps AABAR on the same error-mapping and Crashlytics path as every other REST feature.

**Alternatives rejected**:
- Dedicated `AABARDioInstance` — duplicates interceptor logic; breaks redaction guarantees; violates Principle III's spirit
- `BaseOptions(baseUrl: webhookUrl)` with a second DI-registered Dio — same duplication problem
- Manual `'Authorization': 'Bearer ${token}'` header in the request — redundant (interceptor already does it) and fragile (token refresh not handled)

**Action**: Verify absolute-URL behavior in Dio 5 before writing `aabar_impl.dart`. Confirmed: `Dio` resolves a URL starting with `http://` or `https://` as absolute regardless of `baseUrl` (Dio 5 source: `RequestOptions._uri` merges relative paths, treats absolute URLs as-is).

---

## R2: Webhook URL storage and feature flag

**Decision**: Store the AABAR webhook base URL in `ConfigCubit` as a new field sourced from Firestore `config/*`. Proposed field name: `aabar_webhook_url` (string). If the field is null or empty:
- The `aabar` section is absent from `Config.get.homeSections` (home tile is not rendered)
- The diary CTA collapses (conditional widget checks `aabarWebhookUrl.isNotEmpty`)
- The settings row is hidden

This gives zero-release per-school rollout control. The open business decision (single org-wide webhook vs per-school URL) is deferred — the field can hold either a single URL or later be extended to a per-school map. Mobile reads a single string.

**Rationale**: Matches the existing `diary_enhancements` remote-flag pattern (R10 in diary/research.md) and the general discipline of `ConfigCubit` as the remote-config entrypoint.

**Alternatives rejected**:
- Hardcode in `ApiConst` — can't handle per-school routing; requires a release to update
- Separate Firestore collection `aabar_config/schools/{id}` — over-engineering for v1; one field in the existing `config/*` doc suffices

**ConfigCubit extension required**: Add `String get aabarWebhookUrl` to `ConfigCubit` / `ConfigState` reading from the Firestore config doc. Update `toJson`/`fromJson` (HydratedCubit persistence).

---

## R3: Session persistence — no HydratedBloc, plain Cubit

**Decision**: `AABARCubit` extends plain `Cubit<AABARState>` (not `HydratedCubit`). Conversation is device-local, held in Cubit state, wiped on cold start and on navigation away from `AabarScreen`.

**Rationale**: FR-004 mandates a fresh conversation on every open. Persisting conversation state would violate this requirement and expand PII surface without benefit.

**Implication for `toJson`/`fromJson`**: Not needed — `AABARState` has no hydration contract to maintain.

---

## R4: Cubit over BLoC

**Decision**: Use `Cubit<AABARState>` with named methods:
- `sendMessage(String text, {bool attachChildContext = false, ChildDetailsModel? child})`
- `retryLastMessage()`
- `openFromDiary(Activity activity, AppFlavor flavor)`
- `dismissDisclaimer()`
- `setChildContextTick(bool value)` — updates the toggle; resets to false after each send

A full BLoC with typed events is not needed.

**Rationale**: AABAR has a linear request-response cycle with no concurrent event streams (unlike `ChatBloc` which juggles Firestore snapshots, send, mark-seen). The `ChatBloc` catch-all `on<ChatEvent>` handler is explicitly flagged as an anti-pattern in the diary prereq checklist (T-fix-4); AABAR's Cubit avoids the problem entirely.

---

## R5: Markdown rendering in assistant bubbles

**Decision**: Add `flutter_markdown: ^0.7.x` to `pubspec.yaml` (not present today — confirmed via grep). Use `MarkdownBody` widget inside the assistant-bubble widget. Configure `MarkdownStyleSheet.fromTheme(Theme.of(context))` extended with `ConfigCubit.styling` link color so rendered links respect the app theme.

**Rationale**: FR-008 requires markdown rendering (lists, bold, links). `Text` widget cannot handle this. `flutter_markdown` is the Flutter team's standard package.

**Alternatives rejected**:
- `markdown_widget` — more powerful but heavier dependency; `flutter_markdown` covers FR-008 scope
- Custom regex-based parser — maintenance burden, not justified

**Task**: T-setup-1 — add `flutter_markdown` to `pubspec.yaml` before any UI work.

---

## R6: Consent-token fetch flow — inline on send

**Decision**: When the user taps Send with the child-context tick ON, `AABARCubit.sendMessage()` executes a two-phase sequential request:

1. Emit `AABARSendingState` (user bubble appears immediately as "sending").
2. `POST <webhook>/consent-token` → receive `consent_token` (≤ 60 s TTL, single-use).
3. `POST <webhook>/chat` with full payload including `child_context.consent_token`.

On step 2 failure → user bubble flips to `AABARMessageErrorState`. On step 3 failure → same. No auto-retry; user taps "Tentar novamente" which calls `retryLastMessage()`.

**Why inline (not pre-fetch on tick)**: Tokens expire ≤ 60 s. If the user ticks the affordance and delays typing, a pre-fetched token may expire before send. Fetching inline on Send ensures the token is always fresh.

**Idempotency key**: Generate a UUID v4 at Cubit construct time per compose session; pass it in the `/consent-token` request body so the server can deduplicate retries.

---

## R7: Consent audit Cubit placement

**Decision**: `AABARConsentAuditCubit` registered inside `aabar_di.dart` (reuses `AABARRepo` already registered there). The settings shell navigates to `AabarConsentAuditScreen` which provides this Cubit via `BlocProvider.value(di<AABARConsentAuditCubit>())`.

**Rationale**: Mirrors the `register`-inside-`login_di.dart` co-location pattern (Constitution II, pattern C). The consent audit is a settings sub-surface of AABAR — it has no own repository and shares `AABARRepo.listConsentTokens()` / `AABARRepo.revokeConsentToken()`.

---

## R8: Home tile wiring — server-driven section

**Decision**: The AABAR home entry is wired as a section tile, not a hardcoded widget. The existing `HomeSectionsItem` switch statement receives a `SectionModel` with `to: 'aabar'` from `Config.get.homeSections` (server-driven via Firestore ConfigCubit). Mobile adds one `case 'aabar':` branch navigating to `AabarScreen()`. The section is only present in the config when the school has AABAR enabled and `aabar_webhook_url` is non-empty — the backend controls this; the mobile app has no additional gate at the tile level.

**Rationale**: Matches how `timeline`, `chats`, `events` etc. are wired. Zero mobile release needed to add/remove the AABAR tile per school.

---

## R9: Webhook timeout — existing default is correct

**Decision**: Reuse the existing `NetworkClient` default receive timeout (`_defaultReceiveTimeout = 30 s`). Do not call `networkClient.setTimeout(...)` for AABAR.

**Rationale**: SC-001 requires p95 ≤ 8 s; the spec Assumptions note RAG p95 is expected ≪ 8 s under normal load. 30 s is appropriate headroom without hitting the 10-hour ceiling used for media uploads.

---

## R10: Crashlytics redaction for AABAR payloads

**Decision**: The AABAR impl must be added to the same Crashlytics redaction allowlist as medication payloads (see spec Assumptions: "The Crashlytics redaction layer will be extended to the AABAR client before launch"). Concretely: ensure `aabar_impl.dart` calls do not log prompt text or `child_context` fields to Crashlytics breadcrumbs.

**Action**: T-qa-1 in tasks.md — verify staging logs before launch. Reference implementation: medication Crashlytics redaction (2026-05-14 session).

---

## Open items carried into implementation

| Item | Tracked in |
|------|-----------|
| Single org-wide webhook vs per-school webhook URL | specs/business.md §Strategic Decisions |
| AR translations for 25 `aabar_*` keys | Localization team |
| Firestore security rules for the `/consent-list` endpoint (server-side) | Backend coordination ticket |
| NPS prompt timing (once per 30 days per user) — deferred v1.x | tasks.md deferred section |
