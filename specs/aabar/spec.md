---
status: draft
feature: aabar
flavor_scope: both
seeded_from: specs/business.md#511-aabar--aba-chat-agent-planned
clarifications_session: 2026-05-15
created: 2026-05-15
---

# Feature Specification: AABAR — in-app ABA chat agent

**Feature Branch**: `(not yet — operating on Nour_main with sibling brownfield work)`

**Created**: 2026-05-15

**Status**: Draft

**Input**: User description: "aabar — in-app ABA chat agent. Full product context is already in specs/business.md §5.11. Native Flutter chat UI calling existing n8n RAG webhook over REST (no WebView); both flavors with flavor-conditional default suggestion chips; clean UX (no per-message citations); LGPD default-off payload with per-message opt-in to attach child diary context. v1 entry points: home tile + 'Pedir interpretação à AABAR' diary CTA. Out of scope v1: image/voice input, streaming, user-uploaded docs, cross-conversation memory, group chats."

Cross-references: [specs/business.md §5.11](../business.md#511-aabar--aba-chat-agent-planned), [specs/business.md §5.1.1 Diary value-add](../business.md#511-diary-value-add-planned), [specs/business.md Clarifications 2026-05-15](../business.md#clarifications).

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: both (parents + professores)
- **Flavor-conditional behavior**:
  - Default suggestion chips on cold-start chat differ:
    - **Parents** see daily-support prompts ("Como ajudo meu filho a se acalmar quando…", "O que significa quando…", "Atividades para casa que reforçam…", "Sinais de progresso em…").
    - **Teachers** see methodology prompts ("Como reforço o comportamento X…", "Plano de extinção para…", "Adaptação curricular para criança com…", "Comunicação com a família sobre…").
  - The "Pedir interpretação à AABAR" diary CTA renders on both flavors but the seeding text differs (parent sees "ajuda-me a entender este registro do meu filho"; teacher sees "interpreta este registro em chave de ABA").
  - Visual treatment, composer, attachment affordances, disclaimer copy, and consent affordance are identical across flavors.
- **Server role implication**: Every request to the n8n webhook carries `role: parent | teacher` derived from the flavor at login (see [login_impl.dart:30](../../lib/features/login/data_sources/login_impl.dart#L30)). The backend may tailor the response style (e.g., more technical for `teacher`); the mobile app does not branch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Open AABAR from home and ask an ABA question (Priority: P1) 🎯 MVP

A parent (or teacher) taps the AABAR tile on the home screen, lands on an empty chat with flavor-conditional suggestion chips and a pinned-but-dismissible disclaimer, types or taps a prompt, and receives a plain-text reply within a few seconds.

**Why this priority**: This is the flagship MVP. Without it neither flavor has the v1 differentiator. Every other AABAR surface is a path *to* this same chat. Delivers the [§9.5](../business.md#95-strategic-position-recommended) wedge ("the demo that sells the school").

**Independent Test**:
1. Cold-start the parents flavor on a real device, log in past the approval gate.
2. Tap the AABAR tile on home.
3. Observe: empty chat, pinned-dismissible PT-BR disclaimer at the top, 4 suggestion chips below the composer.
4. Tap a suggestion chip → text fills the composer.
5. Tap Send → loading indicator → reply text renders as a chat bubble within ~8s.
6. Confirm no per-message citations or freshness chrome render.

**Acceptance Scenarios**:

1. **Given** a logged-in approved parent on home, **When** they tap the AABAR tile, **Then** an empty AABAR chat opens with a pinned-dismissible disclaimer and 4 parent-flavor suggestion chips.
2. **Given** a logged-in approved teacher on home, **When** they tap the AABAR tile, **Then** the same chat opens but with 4 teacher-flavor suggestion chips.
3. **Given** the user is on the empty AABAR chat, **When** they tap a suggestion chip, **Then** the chip's text is inserted into the composer (not auto-sent — user can edit).
4. **Given** a non-empty composer, **When** the user taps Send, **Then** the message appears immediately as a "user" bubble, a typing indicator shows, and within ~8 s a reply renders as an "assistant" bubble.
5. **Given** a returning user, **When** they re-open the chat from home, **Then** they see a **fresh empty chat** (cross-conversation memory is explicitly out of scope for v1).
6. **Given** the disclaimer is visible, **When** the user taps "Entendi", **Then** the banner collapses to a smaller persistent footnote ("AABAR é informacional — consulte um BCBA para decisões clínicas") that cannot be fully dismissed.

---

### User Story 2 - "Pedir interpretação à AABAR" from a diary entry (Priority: P2)

A parent reading a diary entry taps the "Pedir interpretação à AABAR" action; AABAR opens with the chat thread **pre-seeded** with that one diary entry as context. Same chat surface, but the seeding pre-flags the per-message child-context consent.

**Why this priority**: This is the daily-stick moment — it turns the existing diary from "report viewer" to "decision-support tool" and proves the parent's daily login. It depends on User Story 1's chat surface existing; building it second is the natural sequencing.

**Independent Test**:
1. From a diary entry detail screen, locate the "Pedir interpretação à AABAR" CTA.
2. Tap it.
3. Confirm AABAR chat opens.
4. Confirm a pre-filled "interpretation" prompt is queued in the composer.
5. Confirm the per-message **"incluir o diário recente do meu filho" affordance is pre-ticked but visibly highlighted** and the user must confirm before send.
6. Confirm the request payload includes the `child_context` block only if the user keeps the tick.

**Acceptance Scenarios**:

1. **Given** a parent on a diary entry, **When** they tap "Pedir interpretação à AABAR", **Then** the AABAR chat opens with the composer pre-filled and the child-context tick set ON but visibly emphasized (e.g., highlighted background + tooltip).
2. **Given** the diary CTA path with the tick ON, **When** the user taps Send, **Then** the outgoing payload includes `child_context: { child_id, recent_activities, consent_token }` and the conversation surface annotates the user-bubble with a small "incluído contexto do diário" badge.
3. **Given** the diary CTA path, **When** the user **unticks** the child-context affordance before tapping Send, **Then** the request payload drops the `child_context` block entirely.
4. **Given** the diary entry the user came from was for a different child than the parent's currently-active child, **Then** the seeding is rejected with an error toast ("Selecione esta criança no início primeiro") and no chat opens. *(Prevents accidental cross-child leakage.)*

---

### User Story 3 - Per-message child-context opt-in from the standalone chat (Priority: P3)

A user already in a standalone AABAR conversation (entered via the home tile) wants to attach their child's recent diary context to a single message. They tick a checkbox below the composer; the next Send carries the `child_context` block; the message after that does not (tick is non-sticky).

**Why this priority**: Power-user / teacher path; lower volume than P1/P2. Necessary for the "richer answers for specific cases" use case but not flagship demo material.

**Independent Test**:
1. Open AABAR from the home tile.
2. Below the composer, locate the "incluir o diário recente do meu filho" checkbox (default OFF).
3. Tick it.
4. Send a message → verify the request payload carries `child_context`.
5. Wait for the reply, then send a second message **without re-ticking**.
6. Verify the second payload has NO `child_context` block.

**Acceptance Scenarios**:

1. **Given** an AABAR chat session, **When** the user opens the composer, **Then** the child-context checkbox is OFF by default at the start of every new conversation.
2. **Given** the checkbox is OFF, **When** the user taps Send, **Then** the request payload contains exactly `{prompt, role, school_id, lang}` with no `child_context` field.
3. **Given** the checkbox is ticked ON, **When** the user taps Send, **Then** the payload includes a `child_context` block with a **single-use** `consent_token` issued by the server and tied to that specific message.
4. **Given** the user just sent a message with the tick ON, **When** they begin typing the next message, **Then** the tick has automatically reset to OFF (non-sticky) and a tooltip surfaces explaining why.
5. **Given** the user has more than one child linked, **When** they tick the checkbox, **Then** a child-picker surfaces inline asking which child's context to attach (defaults to the currently-active child).

---

### Edge Cases

- **Approval gate**: A user with `isApproval == false` who follows a deep link to AABAR is short-circuited to `your_account_under_review` like every other post-login surface.
- **Non-target flavor**: AABAR ships to both flavors; no flavor-rejection path is needed.
- **Webhook unavailable (network down / 5xx / timeout > 30s)**: The pending user-bubble flips to an error state with a "Tentar novamente" retry; no message is silently dropped; no auto-retry that could re-send PII.
- **Webhook returns an empty or malformed response**: Same error state as above; no blank bubble.
- **Rate limit exceeded**: The user sees "Você fez muitas perguntas em pouco tempo. Aguarde {seconds}s." (`aabar_error_rate_limit`). Rate limiting is enforced server-side only (per [Resolved Decisions §2](#resolved-decisions-was-needs-clarification)); the mobile composer remains enabled, and a premature next-send simply returns another `429`. No client-side counter.
- **Disclaimer never dismissed**: The disclaimer persists as a small pinned footnote so legal text is never absent from the chat.
- **User switches the active child mid-conversation**: The current conversation continues; any subsequent child-context attach uses the new active child, with the picker offered (story 3 scenario 5).
- **User logs out mid-conversation**: The conversation is wiped from the device immediately; if v1 includes server-side transcript storage (see open decision), a server-to-server erasure call is queued.
- **Crashlytics breadcrumb leakage**: AABAR request/response payloads must be on the same redaction allowlist as medication payloads. Verify in staging.
- **A parent's diary CTA seeds a child the parent shouldn't have access to**: Server must validate the `consent_token` covers the `child_id`; reject with 403 if not.
- **n8n endpoint URL is unconfigured** (e.g., per-school webhook variant before configuration lands): AABAR tile is hidden and the diary CTA collapses. Surfaces a friendly "Em breve" placeholder if a school-admin has marked AABAR enabled but the URL is empty.

## Requirements *(mandatory)*

### Functional Requirements

#### Surface & navigation

- **FR-001**: The system MUST surface an AABAR entry on the home screen for both flavors, gated by `isApproval == true`.
- **FR-002**: The system MUST surface a "Pedir interpretação à AABAR" action on a diary entry detail view, gated by `isApproval == true` and visible only when the active child is the same child the diary entry belongs to.
- **FR-003**: Tapping either entry MUST navigate to a single shared AABAR chat surface (not two divergent screens).

#### Chat behavior

- **FR-004**: The AABAR chat MUST start fresh every time it is opened (no persisted conversation, no cross-session memory). Users do not see prior conversations.
- **FR-005**: The chat MUST display four (4) suggestion chips beneath the composer when the message list is empty, flavor-conditional (parents vs teachers), localized to the user's selected language.
- **FR-006**: Tapping a suggestion chip MUST insert the chip's text into the composer; it MUST NOT auto-send.
- **FR-007**: Sending a message MUST immediately render the user's text as a user-side bubble, display a typing indicator, and resolve to either a reply bubble or an error state.
- **FR-008**: Replies MUST render as plain text bubbles supporting markdown formatting (lists, bold, links to in-app screens). Images, audio, and external links open in a browser confirmation dialog.
- **FR-009**: The chat MUST NOT render per-message citations, freshness stamps, source URLs, or reviewer-attribution chrome (clean-UX choice per [Clarifications Q4](../business.md#clarifications)).

#### Disclaimer

- **FR-010**: The chat MUST show an LGPD-aware PT-BR disclaimer when opened (English/Arabic translations required). The disclaimer states AABAR is informational and not a substitute for clinical evaluation.
- **FR-011**: The disclaimer MUST be dismissible to a smaller persistent footnote, but never fully removable from the conversation surface.

#### Payload — default (no child context)

- **FR-012**: Every outgoing message MUST, by default, carry exactly: `prompt` (the user's text), `role` (`parent` or `teacher`), `school_id` (current user's school), `lang` (`pt`, `en`, or `ar`). Nothing else.
- **FR-013**: The default payload MUST NOT contain the user's name, the user's CPF, the user's phone, the user's email, any child's name, any child's diary entries, any free-form child reference, or any prior conversation context.

#### Payload — with explicit consent

- **FR-014**: A checkbox-style affordance "incluir o diário recente do meu filho" MUST be present beneath the composer in every conversation. It MUST default OFF at the start of every new conversation and MUST NOT persist its checked state across messages (non-sticky).
- **FR-015**: When the affordance is ticked, the next Send (one message only) MUST request a single-use server-issued `consent_token` and include a `child_context` block in the payload containing: `child_id`, `recent_activities` (the structured typed-question entries from the last N — defaulting to 7 — days for that child), and the `consent_token`.
- **FR-016**: After a message is sent with the affordance ticked, the affordance MUST reset to OFF before the next message can be composed.
- **FR-017**: When the user has multiple children linked, ticking the affordance MUST surface an inline child picker before Send; default selection is the currently-active child.

#### Empty / loading / error / offline states

- **FR-018**: When the device is offline or the webhook times out (> 30 s), the user-bubble MUST flip to a clearly-marked error state with a "Tentar novamente" CTA. The system MUST NOT auto-retry — only on explicit user tap.
- **FR-019**: When the webhook returns a 4xx/5xx or malformed JSON, the user-bubble MUST flip to the same error state. No empty assistant bubble.
- **FR-020**: Rate limiting is **server-side only**. The mobile client MUST NOT disable the composer based on any client-side counter. When the webhook returns `429` with a `Retry-After` header, the user MUST see a localized error message ("Você fez muitas perguntas em pouco tempo. Aguarde {seconds}s.") on the affected user-bubble. The composer remains enabled — the user can type their next message during the cool-down and will simply see another `429` if they send too early. Short-circuiting that second send purely client-side (skipping the network round-trip during a known cool-down) is a v1.x optimization, not a v1 requirement.

#### Settings & audit (LGPD)

- **FR-021**: A "Meus consentimentos AABAR" surface MUST ship in **v1**, accessible from the [settings](../settings/) shell. It lists every `consent_token` ever issued for the current user (within the server-side retention window — see FR-021a), with `issued_at` timestamp, the child the consent attached, and a per-row "Revogar" action that calls the AABAR webhook's `POST /consent-revoke` endpoint and removes the corresponding child_context payload from any retained transcript. Empty state shows `aabar_consent_audit_empty`.
- **FR-021a**: The AABAR backend MUST retain server-side conversation transcripts and the consent ledger for **90 days** from the date of last write, then auto-delete. The mobile audit surface only renders entries that are still inside this window. Older entries naturally drop out of the list.
- **FR-022**: The existing settings "Delete my account" path MUST trigger a server-to-server erasure call to the AABAR / n8n side, removing any server-stored conversation transcripts and consent ledger for this user.

#### Approval gate

- **FR-023**: Any deep link or push handler that lands on AABAR MUST verify `UserBloc.get.state.user?.isApproval == true` before opening the chat; otherwise route to `your_account_under_review`.

### Localization Requirements

All user-visible strings MUST be added as keys in [lib/core/localization/localization_keys.dart](../../lib/core/localization/localization_keys.dart) with PT-BR (primary), EN, and AR translations. Keys for v1:

| Key | pt (primary) | en | ar |
|---|---|---|---|
| `aabar_tile_title` | "AABAR — Especialista em ABA" | "AABAR — ABA Specialist" | "أبار — مختص ABA" |
| `aabar_tile_subtitle` | "Pergunte sobre comportamento, terapia, casa e escola." | "Ask about behavior, therapy, home, and school." | "اسأل عن السلوك والعلاج والمنزل والمدرسة." |
| `aabar_disclaimer_full` | "AABAR responde com base em material curado de ABA por uma equipe clínica. É informacional. Não substitui avaliação de um BCBA / analista do comportamento." | "AABAR answers from an ABA corpus curated by a clinical team. It is informational. It does not replace a BCBA / behavior-analyst evaluation." | (AR translation) |
| `aabar_disclaimer_dismissed` | "AABAR é informacional — consulte um BCBA para decisões clínicas." | "AABAR is informational — consult a BCBA for clinical decisions." | (AR translation) |
| `aabar_disclaimer_dismiss_cta` | "Entendi" | "Got it" | "حسنًا" |
| `aabar_composer_placeholder` | "Pergunte algo à AABAR…" | "Ask AABAR something…" | "اسأل أبار شيئًا…" |
| `aabar_include_diary_label` | "Incluir o diário recente do meu filho" | "Include my child's recent diary" | (AR) |
| `aabar_include_diary_explainer` | "Anexa as últimas atividades registradas como contexto desta mensagem. A escolha não é mantida — você confirma a cada mensagem." | "Attaches recent diary entries as context for this message. The choice is not remembered — you confirm per message." | (AR) |
| `aabar_diary_cta_label` | "Pedir interpretação à AABAR" | "Ask AABAR to interpret" | (AR) |
| `aabar_diary_seed_parent` | "Ajude-me a entender este registro do meu filho." | "Help me understand this entry about my child." | (AR) |
| `aabar_diary_seed_teacher` | "Interprete este registro em chave de ABA." | "Interpret this entry through an ABA lens." | (AR) |
| `aabar_chip_parent_1` | "Como ajudo meu filho a se acalmar quando…" | "How do I help my child calm down when…" | (AR) |
| `aabar_chip_parent_2` | "O que significa quando…" | "What does it mean when…" | (AR) |
| `aabar_chip_parent_3` | "Atividades para casa que reforçam…" | "Home activities that reinforce…" | (AR) |
| `aabar_chip_parent_4` | "Sinais de progresso em…" | "Signs of progress in…" | (AR) |
| `aabar_chip_teacher_1` | "Como reforço o comportamento X…" | "How do I reinforce X behavior…" | (AR) |
| `aabar_chip_teacher_2` | "Plano de extinção para…" | "Extinction plan for…" | (AR) |
| `aabar_chip_teacher_3` | "Adaptação curricular para criança com…" | "Curriculum adaptation for a child with…" | (AR) |
| `aabar_chip_teacher_4` | "Comunicação com a família sobre…" | "Communicating with the family about…" | (AR) |
| `aabar_error_offline` | "Sem conexão. Verifique sua internet." | "No connection. Check your internet." | (AR) |
| `aabar_error_server` | "AABAR não conseguiu responder agora. Tente novamente." | "AABAR couldn't reply right now. Try again." | (AR) |
| `aabar_error_rate_limit` | "Você fez muitas perguntas em pouco tempo. Aguarde {seconds}s." | "Too many questions in a short time. Wait {seconds}s." | (AR) |
| `aabar_retry_cta` | "Tentar novamente" | "Retry" | "إعادة المحاولة" |
| `aabar_context_attached_badge` | "Incluído contexto do diário" | "Diary context attached" | (AR) |
| `aabar_consent_audit_title` | "Meus consentimentos AABAR" | "My AABAR consents" | (AR) |
| `aabar_consent_audit_empty` | "Você ainda não compartilhou contexto do diário com a AABAR." | "You have not shared diary context with AABAR yet." | (AR) |
| `aabar_consent_revoke_cta` | "Revogar" | "Revoke" | (AR) |
| `aabar_child_picker_title` | "De qual criança usar o diário?" | "Whose diary do you want to include?" | (AR) |
| `aabar_coming_soon` | "AABAR estará disponível em breve para sua escola." | "AABAR will be available soon for your school." | (AR) |

(AR translations TBD by the localization team; surface for tracking.)

All keys MUST also be **remote-overridable** via Firestore `config/*` — this is the existing translation discipline.

### Backend Touchpoints

- **REST — n8n webhook** (base URL injected via app config; whether the URL is a single org-wide webhook or per-school is the open product decision tracked in [business.md Strategic Decisions](../business.md#strategic-decisions-to-make-not-tasks--decisions-blocking-the-above)):
  - `POST <webhook>/chat`
    - Auth: bearer token issued by the existing Criarte session (the same `Authorization: Bearer <accessToken>` already attached by [network_interceptor.dart](../../lib/core/network/network_interceptor.dart)). The n8n side accepts and validates this token via a shared verification endpoint.
    - Request (default): `{prompt: string, role: "parent"|"teacher", school_id: int, lang: "pt"|"en"|"ar"}`
    - Request (with child context): adds `child_context: {child_id: int, recent_activities: Activity[], consent_token: string}`
    - Response: `{answer: string}`. Optional future fields anticipated but not required in v1: `citations: [{title, url, updated_at}]`, `corpus_version: string`. Anticipated but unhandled in v1.
    - Errors: `400` (bad payload), `401` (token), `403` (consent_token does not cover this child_id), `429` (rate limit, with `Retry-After`), `5xx` (server). All map to the FR-019 error UI.
  - `POST <webhook>/consent-token` — server-issued single-use token tied to a `(user_id, child_id, message_idempotency_key)` triple. Token is short-lived (≤ 60 s). Mobile MUST request it inline before sending a child-context message.
  - `POST <webhook>/erase` — server-to-server erasure trigger fired from the existing settings "Delete my data" path. Mobile does not need to poll the result.

- **Firestore**: not used.
- **Firebase Storage**: not used.
- **FCM topics / data payload**: not used (no push notifications for AABAR in v1; deferred to v2 if "AABAR has a follow-up for you" makes sense).

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **Yes**. AABAR is post-login; pending users do not see the AABAR tile and the diary CTA is unreachable for them (they cannot reach the diary either).
- Device permissions: none new. Notification permission inherits the existing app posture.

### Key Entities

- **AABARConversation** — *device-local only* (no persistence across app launches in v1). A flat list of `AABARMessage`s plus the metadata needed to render the disclaimer/state.
- **AABARMessage** — `{role: "user"|"assistant"|"error", text, timestamp, contextAttached: bool, errorReason?: string}`. The `contextAttached` flag drives the "Incluído contexto do diário" badge on the rendered user-bubble.
- **AABARRequestPayload** — wire format described in Backend Touchpoints.
- **AABARChildContext** — `{child_id, recent_activities: Activity[], consent_token}`. Single-use; the consent_token is dropped from device memory the instant the response arrives.
- **AABARConsentLedgerEntry** *(server-owned, mobile-read)* — `{consent_token, user_id, child_id, issued_at, used_at, revoked_at?}`. Surfaces on the "Meus consentimentos AABAR" settings screen.
- **AABARSuggestionChip** — `{key, text, flavor}`. Statically defined from the localization keys; not server-driven in v1 (remote overridability still applies via the existing `ConfigCubit` translation overlay).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of AABAR replies arrive within 8 seconds end-to-end (composer-tap to bubble-rendered) under typical Brazilian 4G/5G conditions.
- **SC-002**: Within 30 days of launch, at least 50% of weekly active parents have opened AABAR at least once.
- **SC-003**: Among parents who open AABAR, at least 25% send 3 or more messages in the same conversation (engagement depth, not just curiosity).
- **SC-004**: Among teachers, at least 40% open AABAR weekly after the first 30 days (clinical-tool stickiness).
- **SC-005**: 0 audit findings in an LGPD review of the n8n inbound logs that identify child PII in any message where the consent affordance was not explicitly ticked (the "default-off" promise must hold in production).
- **SC-006**: The pinned disclaimer is visible (in either expanded or footnote form) on 100% of AABAR conversation surfaces, measured by a Crashlytics-instrumented check.
- **SC-007**: When a user invokes "Delete my account", the AABAR server-side conversation and consent ledger are wiped within 10 seconds of the request being acknowledged.
- **SC-008**: Daily error rate (offline + server + malformed responses combined) stays below 3% of total sent messages — measured by the app's existing error-event analytics once instrumented.
- **SC-009**: Net Promoter Score (NPS) for AABAR, measured in a 1-question post-conversation prompt fired no more than once per 30 days per user, is ≥ +30 (industry-good for clinical-info apps).

## Assumptions

- The n8n AABAR webhook is already operational and will be extended (by the AABAR team) to: (a) accept the bearer token issued at Criarte login, (b) implement the `/consent-token` and `/erase` endpoints, (c) emit at minimum `{answer}` in the response. The mobile spec does not block on these — they are part of the AABAR-side delivery commitment.
- The corpus is curated and signed off by a named ABA clinical reviewer on the AABAR side ([Clarifications Q4](../business.md#clarifications)); the mobile app does not surface the reviewer's name in v1 but the company may surface it in store-listing copy and in the AABAR website.
- ABA = Applied Behavior Analysis throughout this spec ([Glossary](../business.md#glossary)).
- The user's `school_id` is reliably available from the existing `UserBloc.state.user.school_id` by the time the AABAR tile is reached (the approval gate guarantees a hydrated user).
- The Crashlytics redaction layer ([network_client._redactBody](../../lib/core/network/network_client.dart)) will be extended to the AABAR client before launch — the medication redaction work from 2026-05-14 is the reference implementation.
- A 30-second client-side timeout on the webhook is appropriate for a RAG call; the AABAR backend p95 is assumed to be ≪ 8 s under normal load (matches SC-001).
- The "Meus consentimentos AABAR" surface lives under the existing [settings shell](../settings/) — it is not its own bottom-nav tab.
- AR translations of the localization keys above will be supplied by the localization team; the table marks them TBD but they must land before AR shipping. PT-BR (primary) and EN are inline.

## Resolved Decisions (was NEEDS CLARIFICATION)

All three open items from the initial draft were resolved on 2026-05-15 during the `/speckit-specify` validation loop:

1. **Server-side transcript retention** — Resolved: **90 days** from date of last write, auto-deletion thereafter. The mobile audit surface (FR-021) only lists entries within this window. Captured in FR-021a. Balances LGPD minimization with operational value (corpus team can replay recent queries to find content gaps).

2. **Per-user rate-limit policy** — Resolved: **server-side only, no client-side counter**. The mobile client never disables the composer based on a client-side limit; the n8n side returns `429 Retry-After` and the mobile UI surfaces the cool-down message inline. Captured in FR-020 (revised). Trade-off: relies on the AABAR backend to enforce limits responsibly; the mobile app stays simple.

3. **"Meus consentimentos AABAR" audit surface scope** — Resolved: **ships in v1** with a per-row "Revogar" action. Captured in FR-021 (revised). Trade-off: ~3-5 extra days of v1 mobile + backend `/consent-list` + `/consent-revoke` endpoints, in exchange for a stronger LGPD story in the launch narrative and store-listing copy.

> Future clarifications, if needed, should land via `/speckit-clarify aabar` against this spec rather than reopening this section.
