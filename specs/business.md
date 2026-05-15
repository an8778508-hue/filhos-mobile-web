# Business Spec — Criarte / Filhos

> **Status (2026-05-15):** Rewritten from the per-feature trios under [specs/](.). Each `## <Surface>` section names the feature trios that implement it; for product-level "why" the per-feature `spec.md` is the source of truth. Competitive landscape in §9 is preserved from the prior revision.

## Clarifications

### Session 2026-05-15

- Q: What does "ABA" mean in this product context? → A: **Applied Behavior Analysis** (autism / behavioral-therapy methodology). AABAR — the company's in-house n8n RAG agent already deployed on the website — is planned to be exposed inside the app so parents and teachers can ask trusted ABA questions without leaving the diary/chat flow.
- Q: How does the in-app AABAR button connect to the n8n RAG? → A: **Native in-app chat UI** (Flutter) sending/receiving messages over REST to the existing n8n webhook. No WebView, no browser hop. UX should mirror the existing [chat](chat/) feature so users feel at home.
- Q: Who can access the AABAR chat in v1? → A: **Both flavors** — parents and teachers. One shared chat feature with flavor-conditional default suggestion chips: teachers see ABA methodology prompts ("how do I reinforce X behavior?"), parents see daily-support prompts ("what does it mean when my child does Y?"). The role still rides every request so the backend can adjust responses if needed.
- Q: How are AABAR's "trusted information" sources sourced and refreshed? → A: **Clean UX, signed-off corpus**. *In-app:* responses render with no per-message citations or freshness chrome — just the answer. *Behind the scenes:* the AABAR website team gates every corpus update through a **named ABA clinical reviewer**; the signoff is governance/QA on the n8n side and is not surfaced inside the mobile app. Mobile app does not own corpus management.
- Q: What does the app send to the n8n AABAR endpoint per message? → A: **Per-message opt-in (defaults to minimal payload)**. Default payload is `{prompt, role: parent|teacher, school_id, lang}` — no user name, no child name, no diary excerpts. The user may *explicitly tick* an "include my child's recent diary" affordance per message to attach context for richer answers; that tick is positive LGPD consent and must be re-confirmed every conversation (never sticky). ABA touches neurodivergent children = a **special category under LGPD Art. 11**, so the default-off posture is mandatory.

## Glossary

- **ABA** — Applied Behavior Analysis. The evidence-based behavioral-therapy methodology used with neurodivergent (e.g., autism-spectrum) children. *Não confundir com OAB (Ordem dos Advogados do Brasil).*
- **AABAR** — the company's in-house RAG (retrieval-augmented generation) agent specialized in ABA. Currently lives on the company website, built on n8n, exposed over HTTP. Slated for an in-app surface (see §5.11).

## 1. Product

**Criarte** (a.k.a. *Filhos*, codename `escola`) is a school↔home engagement platform for **Brazilian early-education and private schools**. It replaces ad-hoc WhatsApp groups and paper handouts with a single child-centric channel where teachers report daily activities and parents stay in the loop.

- **API:** `https://criarte.filhos.app/api/v1/`
- **Firebase project:** `escola-cede2`
- **Vendor (Android applicationId prefix):** `com.algoriza.*`
- **Primary language:** Portuguese (Brazil) — secondary EN, AR

## 2. Two-sided market (two apps from one codebase)

| App | Audience | Store ID | Entry | Role at the server |
|-----|----------|----------|-------|--------------------|
| Criarte (parents) | Parents/guardians of enrolled children | `com.algoriza.criarte` | [lib/main.dart](../lib/main.dart) | `parent` |
| ProfeCriarte (teachers) | Teachers and school staff | `com.algoriza.profecriarte` | [lib/main_professores.dart](../lib/main_professores.dart) | `teacher` |

Both binaries must stay coherent: a write on the teacher side (diary entry, photo, event) must surface on the parent side without confusion. They are one product with two viewpoints, not two products. Flavor branching uses `context.isParents` / `context.isProfessors` ([specs/login/spec.md](login/spec.md), [specs/system.md §8](system.md#8-flavors)). The server role rides every auth request; parents and teachers may use the same phone number but resolve to different accounts.

## 3. Audience & value prop

- **Parents** want to see what their child did today (food, sleep, mood, activities), receive photos, RSVP to events, manage medication info, and message the teacher about their child. Value: peace of mind + asynchronous communication that respects teacher time. Primary surfaces: [home](home/), [diary](diary/), [gallery](gallery/), [chat](chat/), [add_medicine](add_medicine/), [add_address](add_address/), [my_addresses](my_addresses/), [all_children](all_children/), [settings/my_children](settings/my_children/).
- **Teachers** want a structured way to record class activities once and broadcast to all parents, without per-parent messaging overhead. Value: less repeated explaining, fewer parent phone calls. Primary surfaces: [diary](diary/) (write side), [chat](chat/) (group + 1:1), [settings/events](settings/events/), [settings/medicines](settings/medicines/) (teacher view).
- **Schools** are the buying customer (B2B sale). Value: parent satisfaction, retention, professional image, regulatory paper trails (medication records, incident reports, consent forms — most still pending; see §6 and the proposed `incident_report` feature).

## 4. Onboarding & approval

Source-of-truth trios: [splash](splash/), [choose_language](choose_language/), [onboard](onboard/), [login](login/), [otp](otp/), [register](register/), [your_account_under_review](your_account_under_review/), [terms_and_condtions](terms_and_condtions/), [privacy_policy](privacy_policy/).

| Step | Trio | Notes |
|---|---|---|
| Cold start | [splash](splash/) | Restores `UserBloc` (HydratedCubit) and routes to language picker / login / approval gate / main |
| Language picker | [choose_language](choose_language/) | EN / PT / AR. ATT prompt moved to `MainScreen.initState` (post-approval) per Apple 5.1.2 |
| Onboarding | [onboard](onboard/) | Parents-only carousel (teachers skip upstream — features.md mis-tags this as `· B`). First-install gate not yet wired (Hive flag commented out) |
| Phone OTP | [login](login/) + [otp](otp/) | Firebase Auth for SMS; server returns long-lived `accessToken` on `auth/login`. Server role derives from the flavor binary. Email/password and Google/Facebook/Apple social paths exist for the same role |
| Register | [register](register/) | Self-service for new parents; teachers are pre-provisioned by the school (open question — see register/spec.md FR-NN) |
| Approval gate | [your_account_under_review](your_account_under_review/) | `UserModel.isApproval == false` parks the user on this screen; a background poll detects approval and reroutes. Push deep-links honor the gate via `notification_helper.dart` (fixed 2026-05-14) |
| Legal | [terms_and_condtions](terms_and_condtions/), [privacy_policy](privacy_policy/) | Terms is REST + `flutter_html` (`TextHtml`); Privacy is a `WebView` driven by `Config.get.appInfo.privacyUrl`. Two separate code paths despite features.md describing both as "WebView" |

A parent account is bound to one or more enrolled children ([ChildDetailsModel](../lib/core/models/child_details_model.dart) — see [all_children/spec.md](all_children/spec.md) and [settings/my_children/spec.md](settings/my_children/spec.md)). A teacher account is bound to one or more classes ([ClassModel](../lib/core/models/class_model.dart)).

## 5. Daily-life surfaces (parent + teacher)

### 5.1 Diary (atividades)

Source-of-truth: [specs/diary/](diary/).

Teachers record structured per-child reports across typed questions: `CheckQuestion`, `RatingQuestion`, `SelectQuestion`, `NumberQuestion`, `DurationQuestion`, `ImageQuestion`, `InfoQuestion`. Organized into `MainCategory → QuestionCategory → Question`. Parents read; teachers write.

Differentiator: the typed-question model is more structured than competitors' "customizable reports" (§9). Pending work tracked in [diary/tasks.md](diary/tasks.md) includes hardcoded `childId: 1` in template fetch (P0), `activities.sort` inside a loop (O(n² log n)), and missing `idempotency_key` on submit (P1).

#### 5.1.1 Diary value-add (planned)

The structured payload that today *reports* a child's day is also the input for everything else parents and nurseries pay for. Two layers of value-add are now committed (see [diary/spec.md Clarifications 2026-05-15](diary/spec.md#clarifications)):

**Layer A — Insight loops** (whitespace; competitors don't address):

1. **Weekly digest for parents** — auto-rolled trends across mood, sleep, food, and behavior ratings; surfaced on parent home and as a Sunday-evening push. Reuses the same `RatingQuestion` / `NumberQuestion` aggregations the teacher already filled in; no new data entry.
2. **Anomaly callouts** — when a child's ratings drop two days in a row, or a behavior trigger spikes, parents see a soft pill on the relevant diary card ("o sono está atípico esta semana"). Tracked under proposed [`anomaly_alerts`](features.md#anomaly_alerts--admint-tier-3--proposed-primarily-server-side).
3. **AABAR diary interpretation (opt-in)** — a parent reading a diary entry can tap "Pedir interpretação à AABAR" → an AABAR chat thread opens, pre-seeded with this one diary entry (per-message LGPD consent — see [§5.11](#511-aabar--aba-chat-agent-planned) and [Clarifications](#clarifications)). AABAR explains what the data point usually means in ABA terms and what to look for at home.

**Layer B — Competitive parity (the "match the comparator" pass, locked in [diary/spec.md FR-EN-01 … FR-EN-37](diary/spec.md))**:

| Gap closed | Decision | Anchor |
|---|---|---|
| InstaKidz social-feed feel | Reactions (❤️/👏/🥹/😂/🙏) + free-form comments, Firestore-backed. v1 moderation = report-abuse flag only | diary/spec.md FR-EN-01 … FR-EN-07 |
| iCare "draft over the day" workflow | Hybrid local-first save-as-draft with server-side sync (cross-device) | diary/spec.md FR-EN-08 … FR-EN-13 |
| Wrong-target recovery (high-trust UX failure) | Soft-delete + resend with 24h reaction/comment carry-over and a server audit log | diary/spec.md FR-EN-14 … FR-EN-20 |
| InstaKidz multimedia-rich entries | New `AudioQuestion` (≤60s) and `VideoQuestion` (≤30s) question types; reuse chat audio infra | diary/spec.md FR-EN-21 … FR-EN-30 |
| iCare engagement-analytics procurement narrative | Read receipts: teacher sees aggregate-only ("Visto por X de Y famílias"); per-family detail in admin web (out of mobile scope) | diary/spec.md FR-EN-31 … FR-EN-37 |

Layer A (1) and (2) make the existing diary worth the parent's daily attention. Layer A (3) makes it worth the school's procurement budget. Layer B closes the explicit competitor checklist so the sales conversation never starts with "but iCare/InstaKidz already does X".

### 5.2 Chat

Source-of-truth: [specs/chat/](chat/).

Firestore-backed 1:1 messaging between a parent and a teacher in the context of a specific child, plus class-group chats for teachers. Supports text, image, file, and audio. Source of truth is Firestore — there is no parallel REST chat path.

Pending high-trust items in [chat/tasks.md](chat/tasks.md): singleton-stream killed on screen disposal (P0), catch-all `on<ChatEvent>` handler, image compression before upload (P1), symmetric `conversations/{conversationId}/...` storage paths to replace the asymmetric `chat/{senderId}/{receiverId}/...` layout.

### 5.3 Events

Source-of-truth: [specs/settings/events/](settings/events/) (the bottom-nav events tab, despite living under `settings/`).

Teachers create school events; parents RSVP via the `add_form` engine plus `select_attendants`/`attendants_selection` (the latter two are still placeholder stubs — see §11). P0 bug surfaced: `eventBus.on().listen(...)` inside `Builder.builder` re-subscribes on every rebuild ([event_screen.dart:55-62](../lib/features/settings/events/event_screen.dart#L55-L62)).

### 5.4 Gallery

Source-of-truth: [specs/gallery/](gallery/) (list), [specs/gallery_images/](gallery_images/) (viewer).

**Both surfaces are non-production today.** The list entry is wrapped in `if(false)` at [settings_screen.dart:144](../lib/features/settings/settings_screen.dart#L144) and the repo returns `cataas.com` cat memes after a 1-second `Future.delayed`. The viewer (`gallery_images`) is a similar stub. Real backend wiring is the P0 unblock.

### 5.5 Announcements

Source-of-truth: [specs/settings/announcements/](settings/announcements/).

Broadcast notices delivered via FCM + an in-app inbox. Reachable today only via Home tiles and push deep-links (not from the Settings shell — folder-casing drift on imports breaks case-sensitive filesystems; tracked).

### 5.6 Medicines

Source-of-truth: [specs/add_medicine/](add_medicine/) (parent-side write), [specs/settings/medicines/](settings/medicines/) (parent list + teacher dispense view).

Parents register medications (dosage, schedule, prescription photo); native `alarm`-package reminders fire on the parent's phone and survive app kill. Teachers see medications registered for kids in their class and can accept/reject requests. P0 hardening landed 2026-05-14: foreground-service declared, `SCHEDULE_EXACT_ALARM` runtime gating, CPF/medication redacted from Crashlytics. Open: `rejectRequest(reason, attachments)` drops attachments and posts `reason` via `queryParameters` instead of body; first-time parents have no Add CTA in the empty-list state.

### 5.7 Addresses

Source-of-truth: [specs/add_address/](add_address/), [specs/my_addresses/](my_addresses/).

Parents save home/pickup addresses; CEP lookup uses `search_cep` (Brazilian postal codes). **Both surfaces are reachable from both flavors today** despite features.md tagging them parents-only — the entry in `settings_screen.dart` is not gated by `if (context.isParents)`. P0 bug: `addOrUpdateAddress` writes `"city"` twice in the body — the second write (`region_id`) silently overwrites the Brazilian city text. Delete is dead-wired in `my_addresses` (button commented out, dialog confirm leads to `//todo`, no backend endpoint).

### 5.8 Settings

Source-of-truth: [specs/settings/](settings/) (parent shell) + 6 sub-trios.

| Sub-feature | Trio | Status |
|---|---|---|
| Profile editor | [settings/edit_profile](settings/edit_profile/) | Live; phone-format validator is commented out — invalid numbers can be saved |
| My children | [settings/my_children](settings/my_children/) | Parents-only list; `page` argument silently dropped (pagination is theatrical); no "remove from account" yet |
| Medicines | [settings/medicines](settings/medicines/) | Live; see §5.6 |
| Announcements | [settings/announcements](settings/announcements/) | Live but only reachable via Home tiles / push, not the Settings shell |
| Events | [settings/events](settings/events/) | Live (and is the bottom-nav events tab); P0 EventBus leak |
| About | [settings/about](settings/about/) | **Empty surface — `AboutRepo.getAbout()` REST call commented out; contact rows never render** |

LGPD-relevant gaps (P0): "Export my data" path missing; `deleteAccount()` aliases to local logout, not server erasure (§6).

### 5.9 Notifications & deep-linking

Source-of-truth: [specs/notifications/](notifications/), [specs/background_services/](background_services/).

FCM payloads carry `eventable_id` + `eventable_type` for deep-linking. Background handler is `@pragma('vm:entry-point')` and initialises Firebase. Token-refresh is wired ([NotificationService.configureNotifications](../lib/core/notifications_service/notifications_service.dart) accepts `onTokenRefresh`; `BackgroundServicesBloc` connects it to `UserBloc.updateDeviceToken`). Unknown FCM `type` deep-links to the in-app inbox (fixed 2026-05-14).

Wake-up cadence in `background_services` is **mount-driven only**: a pending user has no auto-discovery of approval. Re-mount re-polls. Also: `configureNotifications` is non-idempotent — re-mount likely leaks `onTokenRefresh` subscriptions.

### 5.10 Search

Source-of-truth: [specs/search/](search/), [specs/search_for_filter/](search_for_filter/).

Parents search teachers; teachers search children. P0: `SearchScreen` always hits the *teacher* endpoint regardless of flavor; `ProfessorSearch` event/handler exist but are unwired. `search_for_filter` is a reusable component used by other features; its `SearchForFilterModel` class is defined but unused at runtime (the actual row type is the shared `SchoolItem`).

### 5.11 AABAR — ABA chat agent (planned)

> **Status:** New planned feature. No per-feature trio yet — run `/speckit-specify aabar` to generate one once the items in this section are reviewed.
>
> All design choices captured here flow from the [Clarifications session 2026-05-15](#clarifications). The feature exists to make the app stickier than competitors (§9.4 whitespace) and to give the school owner a concrete differentiator they can demo in 60 seconds.

#### What it is

A native in-app chat surface that lets parents and teachers ask **trusted ABA (Applied Behavior Analysis) questions** and get answers grounded in AABAR — the company's in-house n8n RAG agent that today lives on the AABAR website. The mobile feature does not own the corpus, the model, or the retrieval — it is a thin, well-mannered client of the n8n webhook.

#### Why it matters

- **Brazilian whitespace.** Neither iCare nor InstaKidz (§9) ships AI. None of them have an ABA-specialist agent. A Brazilian early-ed app with a clinical-reviewer-signed ABA agent is a category of one in PT-BR.
- **Daily-stick.** Parents currently open the app to read the diary. Adding a "Pedir interpretação à AABAR" tap on a diary card turns passive reading into active engagement, and grounds the school in a service the parent could not get for free on Google.
- **Teacher leverage.** Teachers handling neurodivergent children have a 24/7 PT-BR clinical-style assistant they can ask during a difficult moment — drives retention of the harder-to-replace half of the workforce.
- **Procurement story.** The school owner buys safety (LGPD-clean), specialization (ABA, not generic), and exclusivity (no competitor has it). All three are in this feature.

#### Audience and surfaces

| Surface | Flavor | Entry point | Notes |
|---|---|---|---|
| Standalone chat tile on home | Both | Home dashboard card / settings row | Free-form Q&A; flavor-conditional default chips |
| "Pedir interpretação à AABAR" CTA on a diary entry | Both | Tap on a diary card (read view) | Opens AABAR chat **pre-seeded with this one diary entry** — gated by the explicit per-message LGPD opt-in (see "Privacy & LGPD" below) |
| "Perguntar à AABAR" inline action from chat | Both (later) | Long-press a parent/teacher message → "ask AABAR to interpret" | Deferred to v2 |

Suggestion chips on the cold-start chat (no message typed yet) are flavor-conditional:

- **Parents:** "Como ajudo meu filho a se acalmar quando…", "O que significa quando…", "Atividades para casa que reforçam…", "Sinais de progresso em…"
- **Teachers:** "Como reforço o comportamento X…", "Plano de extinção para…", "Adaptação curricular para criança com…", "Comunicação com a família sobre…"

#### Integration shape (technical)

Native Flutter chat UI calling the n8n webhook over REST. Reuses the visual language of the existing [chat](chat/) feature so users feel at home (same bubbles, same composer, same audio-message affordance if/when wired). **Not** a WebView (avoids the [privacy_policy](privacy_policy/) phishing-surface class of risks).

Per-message payload (default):

```json
{
  "prompt": "<user text>",
  "role": "parent" | "teacher",
  "school_id": "<int>",
  "lang": "pt" | "en" | "ar"
}
```

Per-message payload (when the user explicitly ticks "incluir o diário recente do meu filho"):

```json
{
  "prompt": "<user text>",
  "role": "parent" | "teacher",
  "school_id": "<int>",
  "lang": "pt" | "en" | "ar",
  "child_context": {
    "child_id": "<int>",
    "recent_activities": [/* last N typed-question entries */],
    "consent_token": "<server-issued, single-use, scoped to this message>"
  }
}
```

The consent token is server-issued per tick (single-use, scoped to one message), never sticky across the conversation. Removing the tick removes the field entirely from the next request — the n8n side never has to infer consent state.

Response payload renders **plain answer text** — no per-message citations, no "updated_at" stamps, no reviewer chrome (clean-UX choice from [Clarifications Q4](#clarifications)). Markdown formatting allowed (lists, bold), images deferred to v2.

#### Privacy & LGPD posture

Applied Behavior Analysis is used with neurodivergent children, so any payload that ties a question to a specific child is **special-category personal data under LGPD Art. 11**. This forces the design:

- **Default off.** No child name, no diary excerpts, no user name leave the device. Just role + school_id + prompt.
- **Per-message opt-in.** The "incluir o diário recente do meu filho" affordance is a clearly-labeled checkbox under the composer with PT-BR microcopy explaining what is sent and to whom (the AABAR n8n endpoint). It defaults unchecked every conversation; never sticky across conversations.
- **Audit trail.** Every opt-in tick is logged server-side with the consent token, the user ID, the child ID, and a timestamp. Surfaces under settings → "Meus consentimentos AABAR" so the user can list and revoke historical consents.
- **No PHI in Crashlytics.** The AABAR client's request/response payloads must be on the same redaction allowlist as medication payloads ([network_client._redactBody](../lib/core/network/network_client.dart)).
- **Right to erasure.** When a user invokes "Delete my data" ([settings/about](settings/about/) is currently empty — see §6 LGPD gaps), AABAR-side conversation history is wiped via a server-to-server call to the n8n side. Tracked as a cross-feature concern.
- **Disclaimer.** First-launch (and dismissible-but-pinned on the chat) PT-BR disclaimer: AABAR is informational, not a substitute for clinical evaluation; for a clinical decision, consult a credentialed BCBA / behavior analyst. Required not just for LGPD but for general medical-information liability.

#### Trusted corpus governance

Mobile app does not own the corpus. The AABAR website team maintains it on n8n with a **named ABA clinical reviewer signoff** on every update ([Clarifications Q4](#clarifications)). This signoff is not surfaced in the mobile app's chat UI (per the clean-UX choice), but the company can name the reviewer publicly on the AABAR website and in store-listing marketing copy — the mobile chat just inherits the trust.

If a future regulator requires per-message citations, the n8n endpoint can return them in the response payload and the app can light them up. The mobile app's data contract anticipates that field but does not require it today.

#### Out of scope for v1

- ❌ Image input (photos of a child, prescriptions, etc.).
- ❌ Voice input / output (defer to v2 when audio infra matures).
- ❌ Streaming responses — v1 is request/response; streaming is a v2 UX nicety.
- ❌ User-uploaded documents into the corpus (corpus stays website-managed).
- ❌ Cross-conversation memory — every conversation starts fresh; the agent does not remember prior chats.
- ❌ Group / shared chats — strictly 1:user:agent.

## 6. Compliance & sensitive data (LGPD)

Minors' personal data and photos are processed → **LGPD** (Brazilian GDPR equivalent) applies.

- Consent capture and retention should be auditable; this currently lives in the dynamic `add_form` engine ([specs/add_form/](add_form/)) and is school-administered, not codified in app.
- Medical data ([add_medicine](add_medicine/), [settings/medicines](settings/medicines/), prescriptions) is sensitive — never log it, never include it in Crashlytics breadcrumbs. Redaction landed 2026-05-14 in [network_client._redactBody](../lib/core/network/network_client.dart).
- Chat is parent↔teacher in the context of a specific child; group chats are teacher-side only. There is no public/social surface.
- **Open LGPD gaps** (Art. 18, II — *data portability and erasure rights*):
  - **Export my data**: not implemented anywhere. Tracked in [settings/tasks.md](settings/tasks.md).
  - **Delete account**: `UserBloc.deleteAccount()` aliases to `_signOutCleanup()` — local logout only, no server-side erasure trigger. Tracked in [settings/tasks.md](settings/tasks.md) as P1.
  - **WebView privacy surfaces** (`privacy_policy`) run with `JavaScriptMode.unrestricted` and no nav-host allowlist — phishing surface if a hostile link is injected into the policy doc. Tracked in [privacy_policy/tasks.md](privacy_policy/tasks.md).
- The `disney.filhos.app` legacy hostname appears in [firebase_options.dart](../lib/firebase_options.dart) / config but business docs say `criarte.filhos.app` — reconcile during the next infra cleanup.

## 7. Monetization (current state)

- No in-app payments, no subscriptions, no ads.
- PIX (Brazilian instant-payment) terminology appears in strings but **no payment flow is implemented**.
- Revenue model is school-level SaaS, billed outside the app.

## 8. Success metrics (proposed — not currently instrumented in-app)

- DAU/MAU per school, per role.
- % of children with ≥1 diary entry per school day (`diary` surface).
- Median time-to-read for announcements.
- Event RSVP completion rate.
- Chat response time (teacher → parent).
- Crash-free sessions per release (Crashlytics).
- Approval-gate dwell time (how long pending teachers sit in `your_account_under_review`).

No analytics SDK is wired today. Firebase Analytics is the path of least resistance given existing Firebase deps; tracked in [system.md §10 Observability](system.md#10-observability).

## 9. Competitive landscape

Comparators studied (analysis dated 2026-05): **iCare Kids** (AppWare, Lebanon — 10+ years, 21 countries, 20M+ photos, deep operational stack) and **InstaKidz** (Egypt — ~4 years, modern UX, two-sided parent-discovery marketplace). Source notes in [the competitor analysis sheets](../docs/competitors/) (paste the supplied analysis there if not yet committed). Both are MENA-based; neither targets Brazil specifically.

### 9.1 At a glance

| Dimension | Criarte | iCare Kids | InstaKidz |
|-----------|---------|------------|-----------|
| Origin | Brazil | Lebanon | Egypt |
| Tenure | New (this codebase) | 10+ years, 21 countries | ~4 years, Egypt-focused |
| Apps | 2 native (parent + teacher) | 4–5 (Admin, Teachers, Parents, Clock, white-label) | 1 unified consumer app + web admin |
| Languages | PT (primary), EN, AR | Multi (Francophone + Arabic) | AR + EN |
| Sale model | School B2B | School B2B + white-label | Freemium B2B + B2C marketplace |
| Discovery layer | None | None | **Yes — searchable nursery directory + reviews** |
| Operational depth | Mid (chat, diary, events, gallery [stub], medicines, addresses) | **Deepest** — bus, gate, HR, IP cam, polling | Mid |
| AI | None | None | None |
| LGPD positioning | Yes (Brazil-specific) | N/A | "Top-tier security" marketing |

### 9.2 Where Criarte already wins (or matches)

- **Brazilian fit.** CPF, CEP, PIX vocabulary, Portuguese-first UI, LGPD framing — neither competitor is localized for Brazil.
- **Diary as a typed-question system.** `MainCategory → QuestionCategory → typed Question` is more structured than iCare's "customizable reports" or InstaKidz's "child progress reports". Real product asset.
- **Two-flavor binary architecture.** Cleaner than iCare's 4–5 separate apps; more focused than InstaKidz's single app.
- **Audio messages in chat** + **native medicine alarms** — at parity with InstaKidz, ahead of iCare's public marketing.
- **Schema-driven dynamic forms ([add_form](add_form/)).** Same engine could power polling, accident reports, consent forms, surveys with no new UI — a building block neither comparator advertises.
- **Approval gate + multi-child + flavor-aware role routing** (post 2026-05-14 fixes) — sound foundation for institutional sale.

### 9.3 Where Criarte loses today

**vs iCare (operational depth):**

| Missing feature | Why it matters | Build cost | Anchor |
|-----------------|----------------|-----------|--------|
| Bus fleet management + GPS for parents | "Where is the bus?" is the #1 parent anxiety question | Medium (3rd-party GPS hardware partner + driver app) | new `bus_tracking` |
| Bus speed-limit monitoring | Premium safety story | Medium | new `bus_tracking` |
| Gate / entry module | Physical security check-in; pairs with QR pickup | Medium (kiosk/tablet flow) | new `gate_module` |
| QR-code drop-off / pickup | Trust + safety; replaces "verbal handover" | **Low** (we have `attendants_selection`/`select_attendants` — but they need to be unblocked first; see §11) | new `qr_pickup` |
| Parent-arrival / "child release" request | Reduces wait at gate | Low | new `parent_arrival` |
| Child-allergy alerts on teacher app | Safety-first | **Low** (field may already exist on `ChildDetailsModel`) | new `allergies` |
| Accident / incident reports | Legal paper trail; LGPD-aligned audit story | **Low** (`add_form` template) | new `incident_report` |
| Health / nurse reports + temperature log | COVID-era expectation | Low (diary subtype) | new `health_log` |
| Polling (parent surveys) | Engagement + light governance | **Low** (`add_form` template) | new `poll` |
| HR / payroll for staff | Out of scope for early-education focus | High — **defer** | — |
| IP camera integration | LGPD risk in Brazil; brand damage if a stream is breached | — | **NOT building** |
| White-label per-school theming | Unlocks chain/franchise segment | Medium (extend `ConfigCubit.styling`) | new `white_label_theming` |
| Read-receipt analytics for announcements | Lets the school prove parent engagement to its board | Low–Medium (server-side primarily) | — |

**vs InstaKidz (discovery / marketplace):**

| Missing feature | Why it matters | Build cost |
|-----------------|----------------|-----------|
| Public school discovery for parents | Turns the parent app into a demand-gen channel — flips business model from "school pays per seat" to "school pays for visibility + leads" | **High** — strategic pivot, not a feature |
| Verified parent reviews | Trust + SEO; backbone of the discovery layer | Medium (moderation + abuse handling) |
| Online enrollment / "joining requests" by parents | Captures intent → school CRM | Medium |
| Search nearby schools / filter by price·hours·location | Marketplace UX | Medium |
| Likes / comments on posts | Stickiness; turns gallery into a feed | Low–Medium (Firestore reactions) |
| Modern parent-facing UX | InstaKidz's "redesigned from the ground up" claim is a differentiator they market | Parallel workstream — see [design.md](design.md) |

### 9.4 Whitespace neither competitor owns — AI-native features

Incumbents (iCare, InstaKidz, Famly, illumine, HiMama) ship no AI today. This is the most defensible differentiation for a new entrant.

| AI feature | Concrete value | Anchor in current code |
|------------|----------------|------------------------|
| **AABAR — in-app ABA chat agent** *(planned v1 flagship)* | Specialized PT-BR Applied-Behavior-Analysis assistant for both parents and teachers; built on the company's existing n8n RAG; clinical-reviewer-signed corpus. Zero competitor has an ABA-specialist agent. | See [§5.11](#511-aabar--aba-chat-agent-planned). New native chat surface mirroring [chat](chat/); calls existing n8n webhook |
| **Auto-drafted daily diary** from teacher photos + 30s voice note | Cuts teacher-side time per child from ~5 min to ~30 s | Hooks into existing [diary](diary/) typed-question system |
| **Photo moderation pre-publish** (faces present, no other children visible without consent, no PII in background) | LGPD-aligned; reduces incident risk | Plugs in before [gallery](gallery/) upload |
| **Sentiment-aware urgent escalation** in chat (PT-aware) | A worried parent message bypasses the teacher's batched-reply window | New layer on [chat_bloc](../lib/features/chat/) |
| **Computer-vision pickup verification** (parent's face matches authorized pickup list) | Replaces or augments QR pickup | Pairs with the new QR pickup module |
| **Attendance / behavior anomaly alerts** ("Aluno X faltou 3 dias seguidos pela primeira vez") | Early signal for school admin | Backend job; lightweight push |
| **Bilingual (PT-BR / EN) school-handbook RAG** *(distinct from AABAR — answers school-policy questions, not ABA clinical questions)* | Reduces "what's the holiday schedule?" load on teachers | New surface in chat or settings; out of AABAR scope |
| **Predictive enrollment-churn signal** for the school admin | Helps the buyer prove ROI | Server-side; admin dashboard |

### 9.5 Strategic position recommended

- **Primary play:** *Brazilian-localized, LGPD-first, AI-native, ABA-specialist* school↔home platform. Don't try to out-feature iCare on bus/gate/HR — pick the 4–5 highest-trust operational features (QR pickup, gate check-in, bus tracking, allergies, accident reports, polling) and ship them well.
- **Wedge (v1 flagship):** **AABAR — in-app ABA chat agent** ([§5.11](#511-aabar--aba-chat-agent-planned)). The company already owns the agent (n8n RAG on the AABAR website); exposing it inside the app is a low-build-cost, high-narrative-value play. ABA is a clinical specialty Brazilian early-ed schools increasingly need (autism-spectrum enrollment is rising) and the competitors do not address it at all. AI-drafted diary entries remain the *second* AI play once AABAR is live.
- **Avoid:** IP cameras (LGPD risk), HR/payroll (scope creep), full discovery marketplace (flywheel investment competing with our school-relationship sale model). If a marketplace play is wanted, scope it as a separate product with a separate backend.

## 10. Risk & sensitivities

- A teacher posting to the wrong child is a high-trust failure — UI must make the active child unmistakable. Tracked under [home/tasks.md](home/tasks.md) (parent-side switcher), [diary/spec.md](diary/spec.md) (active child header).
- Approval-gate bypass via deep link / push tap is a privacy risk; every entry point must respect `isApproval`. Cross-cutting check across [notifications](notifications/), [splash](splash/), [your_account_under_review](your_account_under_review/).
- Remote config (Firestore `config/*`) can override translations and styling at runtime — a bad config write is a production incident vector.
- Two stores, two binaries: a release that ships only one flavor is half-shipped. CI must build both ([system.md §9](system.md#9-build--release)).
- The medication and address surfaces have **silent server-contract bugs** ([add_address](add_address/) duplicate `"city"` key; [settings/medicines](settings/medicines/) `rejectRequest` dropping attachments). Backend may be returning `200 OK` while user intent is lost.

## 11. Production-blocking surfaces (must fix before next release)

Each item is tracked as a `T-fix-N` task in its trio. Listed here for product visibility.

| Surface | Issue | Trio |
|---|---|---|
| [gallery](gallery/) | Entry-point `if(false)`-gated in settings; repo returns `cataas.com` stubs | gallery/tasks.md |
| [gallery_images](gallery_images/) | Same `cataas.com` stub at the repo layer | gallery_images/tasks.md |
| [settings/about](settings/about/) | REST call commented out; contact rows never render | settings/about/tasks.md |
| [select_attendants](select_attendants/) | 10-LOC `Placeholder()` with zero implementation and zero callers; collides with [attendants_selection](attendants_selection/) | select_attendants/tasks.md |
| [attendants_selection](attendants_selection/) | UI scaffold present, multi-select half missing (`onSchoolItemsPressed: (item) {}`, no `selectedIds`, no confirm CTA, no pop-with-selection) | attendants_selection/tasks.md |
| Naming-collision blocker | `select_attendants` vs `attendants_selection` — both stubbed, both unowned, neither wired. Must decide intent (children vs guardians) and delete one folder before any event-RSVP / QR-pickup feature can ship | both trios |

## Tasks

### Product & positioning
- [ ] [both] Document the one-line positioning statement on the App Store / Play Store listings and keep parity between flavors.
- [ ] [both] Decide and document the support / contact channel surfaced inside the app (currently broken — see [settings/about](settings/about/)).
- [ ] [both] Capture screenshots of both flavors for store listings each release.
- [ ] [both] Reconcile `disney.filhos.app` (in code/firebase_options) vs `criarte.filhos.app` (in business docs).

### Onboarding & approval
- [ ] [both] Add analytics events for `login_started`, `otp_verified`, `approval_pending`, `approval_granted` so we can measure activation funnel ([login](login/), [otp](otp/), [your_account_under_review](your_account_under_review/)).
- [ ] [both] Define a maximum time a user can stay in `your_account_under_review` before we surface a "contact your school" CTA (tracked in [your_account_under_review/tasks.md](your_account_under_review/tasks.md)).
- [ ] [both] Resolve `background_services` mount-only wake-up — pending users currently have no auto-discovery of approval flips ([background_services/tasks.md](background_services/tasks.md)).
- [ ] [parents] Confirm the parent enrollment flow: can a parent be linked to a child after first login, or must the school link them first? Document the answer.
- [ ] [both] Fix `onboard` flavor tag in [features.md](features.md) (it's parents-only, not both).

### Monetization & billing
- [ ] [both] Decide whether PIX strings should be removed if no payment flow is planned, or whether the payment flow is on the roadmap.

### Compliance (LGPD)
- [ ] [both] Audit Crashlytics breadcrumbs and logging to confirm no child personal data, photos, or medication info is captured.
- [ ] [both] Document data-retention policy for diary entries, chat messages, photos, and medication records — surface in the in-app privacy policy.
- [ ] [both] **Build an "Export my data" path** ([settings/tasks.md](settings/tasks.md)) — LGPD Art. 18, II.
- [ ] [both] **Make `deleteAccount` trigger server-side erasure**, not just a local logout ([settings/tasks.md](settings/tasks.md)).
- [ ] [both] Add a navigation-host allowlist to the [privacy_policy](privacy_policy/) WebView.
- [ ] [professores] Ensure teachers can identify and tag posts as containing sensitive content (e.g., incident reports) for separate retention.

### Metrics & observability
- [ ] [both] Choose an analytics SDK or commit to a Firebase Analytics rollout and instrument the proposed success metrics in §8.
- [ ] [both] Define Crashlytics SLO (e.g., ≥99.5% crash-free sessions) and add a release gate.

### Two-flavor parity
- [ ] [both] Patch [features.md](features.md) flavor tags that disagree with code: `add_address`, `my_addresses`, `all_children`, `onboard` (see [MIGRATION.md](MIGRATION.md#drift-surfaced-during-migration-action-required-in-featuresmd)).
- [ ] [both] Add a release checklist that requires every PR touching shared code to be smoke-tested in both flavors before merge.
- [ ] [both] Confirm CI builds AAB for both flavors on every release tag.

### Competitive gap closure — Tier 1 (quick wins, cheap because we have the primitives)

*Each item should land before the next release if possible. All reuse existing engines ([add_form](add_form/), [diary](diary/), [attendants_selection](attendants_selection/) **after collision resolved**, [notifications](notifications/)).*

- [ ] **[both] QR-code pickup / drop-off.** Blocked on the `select_attendants` / `attendants_selection` collision (§11). Combine the resolved attendant picker + a new QR generator on the parent side and a scanner on the teacher side. **Sells the school on safety. 1–2 sprints.**
- [ ] **[parents] "I'm here" / parent-arrival request.** Single tap on parent home; cheap because chat infra exists ([chat](chat/) + [home](home/)).
- [ ] **[both] Allergy & medical-flag highlight on teacher app.** Surface `ChildDetailsModel` allergy/medical fields prominently on the teacher's daily roster and on the child profile header. Safety-first.
- [ ] **[both] Accident / incident report template.** New `AddFormType.incidentReport` in the [add_form](add_form/) engine: who, what, when, where, severity, photo, parent signature checkbox. Generates a PDF for the school's archive.
- [ ] **[both] Health / nurse log diary subtype.** New `MainCategory` for "Saúde" with temperature, symptoms, action-taken, and a "notify nurse" flag. Reuses the typed-question system; no new screen architecture.
- [ ] **[both] Polling / parent surveys.** New `AddFormType.poll`. Single-question (radio/multi-select), school-wide or per-class, results visible to admin.
- [ ] **[both] Likes & comments on gallery posts.** Firestore reactions doc, same shape as chat. Blocked on un-stubbing [gallery](gallery/) first.

### Competitive gap closure — Tier 2 (institutional sale enablers — medium build)

- [ ] **[both] Gate / entry module.** Teacher-app kiosk mode at the school's gate tablet; scans the QR from Tier 1.
- [ ] **[parents] Bus tracking (read-only).** Parent app shows the bus's current position on a map for the trip the child is on, ETA to the child's stop, and a push 5 min before arrival. Backend partnership with a GPS / driver-app vendor.
- [ ] **[both] White-label per-school theming.** Generalize the existing `ConfigCubit.styling` remote-config so per-school `school_id` resolves to a unique color palette + logo + app name.
- [ ] **[admin/web — out of scope of mobile, but tracked here] Read-receipt analytics.** Server returns `read_at` for announcements + diary entries; mobile renders "seen by X of Y parents" on the teacher side.

### Competitive gap closure — Tier 3 (AI-native differentiator — the real moat)

- [ ] **[both] AABAR in-app ABA chat agent.** Native Flutter chat surface (mirroring [chat](chat/)) calling the existing n8n RAG webhook over REST. Both flavors; flavor-conditional default suggestion chips. Default per-message payload is minimal (role + school_id + lang); per-message LGPD-consent opt-in to attach child diary context. Pre-launch disclaimer pinned in the chat. **This is the v1 flagship — the demo that sells the school.** Full spec to be generated via `/speckit-specify aabar` against [§5.11](#511-aabar--aba-chat-agent-planned).
- [ ] **[both] "Pedir interpretação à AABAR" diary CTA.** Tap on any diary card opens the AABAR chat thread pre-seeded with that one entry (consent-gated). Pairs the diary feature with the agent and is the daily-stick moment.
- [ ] **[both] AABAR audit surface in Settings.** "Meus consentimentos AABAR" lists every per-message consent token issued and lets the user revoke it; pair with the LGPD "Export my data" / "Delete my data" paths.
- [ ] **[professores] AI-drafted diary entries.** Teacher snaps 3–4 photos + records a 30s voice note → an LLM drafts a per-child diary entry pre-filled into the typed-question system. Teacher reviews + taps Send. *Sequence after AABAR ships — re-uses the same Anthropic/Vertex stack but adds multimodal scope.*
- [ ] **[professores] Photo moderation pre-publish.** Before a teacher posts to [gallery](gallery/), a vision model checks LGPD-relevant safety (only tagged children visible, no PII in background).
- [ ] **[both] Sentiment-aware urgent escalation in chat.**
- [ ] **[parents/teachers] PT-BR / EN school-handbook RAG.** Distinct from AABAR — answers school-policy questions (calendar, fees, regulations), not ABA clinical questions. Same architectural pattern as AABAR (RAG behind a webhook) but a different corpus and a different name.
- [ ] **[admin] Anomaly alerts.** Server-side: child absent for N consecutive days, sudden behavior-rating drop on diary, missed medication times.
- [ ] **[admin] Enrollment-churn predictor.**

### Strategic decisions to make (NOT tasks — decisions blocking the above)

- [x] **Decision: Which AI feature is the v1 flagship?** ✅ **AABAR — in-app ABA chat agent** ([§5.11](#511-aabar--aba-chat-agent-planned), [Clarifications 2026-05-15](#clarifications)). AI-drafted diary entries become the v2 follow-on.
- [x] **Decision: Mobile owns the AABAR corpus?** ✅ **No** — the AABAR website team owns the corpus on n8n with a named ABA clinical-reviewer signoff. Mobile is a thin client of the existing webhook.
- [x] **Decision: AABAR default privacy posture?** ✅ **Minimal payload by default + per-message LGPD opt-in to attach child diary context.** Never sticky. Special-category LGPD Art. 11 applies.
- [ ] **Decision: AABAR v1 launch rollout — both flavors at once, or stage parents-only after a 30-day teacher pilot?** Confirmed *both flavors* in clarifications, but the rollout cadence is open and tied to clinical-liability comfort.
- [ ] **Decision: Name the AABAR clinical reviewer on store-listing copy / inside the app's "about AABAR" disclaimer?** Marketing leverage vs. privacy of the named reviewer.
- [ ] **Decision: AABAR endpoint config — single webhook for all schools, or per-school webhook?** Single is simpler; per-school enables future white-label tenants to bring their own corpus (white-label theming + AABAR-byo-corpus is a plausible Tier-2 expansion).
- [ ] **Decision: Do we build the marketplace/discovery layer?** Recommendation in §9.5: defer.
- [ ] **Decision: Do we build a hardware partnership for buses?** Yes/no determines whether `bus_tracking` is feasible this year.
- [ ] **Decision: Do we expand beyond Brazil?** Current Arabic translation work suggests yes-someday; lock the timeline or remove the AR strings (see [system.md](system.md)).
- [ ] **Decision: Explicitly NOT building IP camera integration. Document the rationale (LGPD) here so it doesn't get re-raised every sales call.**
- [ ] **Decision: `select_attendants` vs `attendants_selection` — pick one folder, delete the other, decide whether the picker is for children or for guardians.** Blocks any feature that uses an attendant picker (events, RSVPs, QR-pickup).
