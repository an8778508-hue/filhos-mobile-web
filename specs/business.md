# Business Spec — Criarte / Filhos

## 1. Product

**Criarte** (a.k.a. *Filhos*, codename `escola`) is a school↔home engagement platform for **Brazilian early-education and private schools**. It replaces ad-hoc WhatsApp groups and paper handouts with a single child-centric channel where teachers report daily activities and parents stay in the loop.

- **API:** `https://criarte.filhos.app/api/v1/`
- **Firebase project:** `escola-cede2`
- **Vendor (Android applicationId prefix):** `com.algoriza.*`
- **Primary language:** Portuguese (Brazil) — secondary EN, AR

## 2. Two-sided market (two apps from one codebase)

| App | Audience | Store ID | Entry |
|-----|----------|----------|-------|
| Criarte (parents) | Parents/guardians of enrolled children | `com.algoriza.criarte` | `lib/main.dart` |
| ProfeCriarte (teachers) | Teachers and school staff | `com.algoriza.profecriarte` | `lib/main_professores.dart` |

Both apps must be coherent: a write on the teacher side (diary entry, photo, event) must surface on the parent side without confusion. Treat them as one product with two viewpoints, not two products.

## 3. Audience & value prop

- **Parents** want to see what their child did today (food, sleep, mood, activities), receive photos, RSVP to events, manage medication info, and message the teacher about their child. Value: peace of mind + asynchronous communication that respects teacher time.
- **Teachers** want a structured way to record class activities once and broadcast to all parents, without per-parent messaging overhead. Value: less repeated explaining, fewer parent phone calls.
- **Schools** are the buying customer (B2B sale). Value: parent satisfaction, retention, professional image, regulatory paper trails (medication records, incident reports, consent forms).

## 4. Onboarding & trust

- Phone-OTP login (Firebase Auth). No self-service signup — accounts are pre-provisioned by the school or require admin approval.
- `your_account_under_review` screen blocks unapproved users; a background poll detects approval and routes them on.
- A parent account is bound to one or more enrolled children (`ChildDetailsModel`); a teacher account is bound to one or more classes.

## 5. Monetization (current state)

- No in-app payments, no subscriptions, no ads.
- PIX (Brazilian instant-payment) terminology appears in strings but **no payment flow is implemented**.
- Revenue model is school-level SaaS, billed outside the app.

## 6. Compliance & sensitive data

- Minors' personal data and photos are processed → **LGPD** (Brazilian GDPR equivalent) applies. Consent capture and retention should be auditable; this currently lives in the dynamic `add_form` engine and is school-administered, not codified in app.
- Medical data (`add_medicine`, prescriptions) is sensitive — never log it, never include it in Crashlytics breadcrumbs.
- Chat is parent↔teacher in the context of a specific child; group chats are teacher-side only. There is no public/social surface.

## 7. Success metrics (proposed — not currently instrumented in-app)

- DAU/MAU per school, per role
- % of children with ≥1 diary entry per school day
- Median time-to-read for announcements
- Event RSVP completion rate
- Chat response time (teacher → parent)
- Crash-free sessions per release (Crashlytics)

## 8. Risk & sensitivities

- A teacher posting to the wrong child is a high-trust failure — UI must make the active child unmistakable.
- Approval-gate bypass via deep link / push tap is a privacy risk; every entry point must respect `isApproval`.
- Remote config (Firestore `config/*`) can override translations and styling at runtime — a bad config write is a production incident vector.
- Two stores, two binaries: a release that ships only one flavor is half-shipped. CI must build both.

---

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
| Operational depth | Mid (chat, diary, events, gallery, medicines, addresses) | **Deepest** — bus, gate, HR, IP cam, polling | Mid |
| AI | None | None | None |
| LGPD positioning | Yes (Brazil-specific) | N/A | "Top-tier security" marketing |

### 9.2 Where Criarte already wins (or matches)

- **Brazilian fit.** CPF, CEP, PIX vocabulary, Portuguese-first UI, LGPD framing — neither competitor is localized for Brazil.
- **Diary as a typed-question system.** `MainCategory → QuestionCategory → typed Question` (Check / Rating / Select / Number / Duration / Image / Info) is more structured than iCare's "customizable reports" or InstaKidz's "child progress reports". This is a real product asset.
- **Two-flavor binary architecture.** Cleaner than iCare's 4–5 separate apps; more focused than InstaKidz's single app.
- **Audio messages in chat** + **native medicine alarms** — at parity with InstaKidz, ahead of iCare's public marketing.
- **Schema-driven dynamic forms (`add_form`).** Same engine could power polling, accident reports, consent forms, surveys with no new UI — a building block neither comparator advertises.
- **Approval gate + multi-child + flavor-aware role routing** (post the 2026-05-14 review fixes) — sound foundation for institutional sale.

### 9.3 Where Criarte loses today

**vs iCare (operational depth):**

| Missing feature | Why it matters | Build cost |
|-----------------|----------------|-----------|
| Bus fleet management + GPS for parents | "Where is the bus?" is the #1 parent anxiety question; competitors win procurement on this alone. | Medium (3rd-party GPS hardware partner + driver app) |
| Bus speed-limit monitoring | Premium safety story; institutional differentiator. | Medium (hardware-dependent) |
| Gate / entry module | Physical security check-in at the school gate; pairs with QR pickup. | Medium (kiosk/tablet flow) |
| QR-code drop-off / pickup | Trust + safety; replaces "verbal handover" and is fast to demo to school owners. | **Low** (we already have `attendants_selection`) |
| Parent-arrival / "child release" request | Reduces wait at gate; pairs with QR. | Low |
| Child-allergy alerts on teacher app | Safety-first; Brazilian schools care a lot about food allergies. | **Low** (already on `ChildDetailsModel`?) |
| Accident / incident reports | Legal paper trail; LGPD-aligned audit story. | **Low** (`add_form` template) |
| Health / nurse reports + temperature log | COVID-era expectation. | Low (diary subtype) |
| Polling (parent surveys) | Engagement + light governance ("which Friday for the trip?"). | **Low** (`add_form` template) |
| HR / payroll for staff | Out of scope for early-education focus. | High — recommend **defer**. |
| IP camera integration | Privacy-sensitive in Brazil under LGPD; brand risk. | Recommend **do NOT build**. |
| White-label per-school theming | Unlocks the franchise / multi-brand chain segment. | Medium (extend the existing flavor + remote-config system). |
| Notification / report read-receipts (engagement analytics) | Lets the school prove parent engagement to its board. | Low–Medium (server-side primarily). |

**vs InstaKidz (discovery / marketplace):**

| Missing feature | Why it matters | Build cost |
|-----------------|----------------|-----------|
| Public school discovery for parents | Turns the parent app into a demand-gen channel for schools — flips the business model from "school pays per seat" to "school pays for visibility + leads". | **High** — this is a strategic pivot, not just a feature. Requires marketplace flywheel investment. |
| Verified parent reviews | Trust + SEO; backbone of the discovery layer. | Medium (moderation pipeline + abuse handling). |
| Online enrollment / "joining requests" by parents | Captures intent → school CRM. | Medium (backend + workflow). |
| Search nearby schools / filter by price·hours·location | Marketplace UX. | Medium. |
| Likes / comments on posts (social engagement) | Stickiness; turns the gallery into a feed. | Low–Medium (Firestore reactions). |
| Modern parent-facing UX | InstaKidz's "redesigned from the ground up" claim is a differentiator they actively market. | Already a parallel workstream — see [design.md](design.md). |

### 9.4 Whitespace neither competitor owns — AI-native features

The competitor analysis explicitly calls out that **none of the incumbents (iCare, InstaKidz, Famly, illumine, HiMama) ships AI features**. This is the most defensible differentiation for a new entrant:

| AI feature | Concrete value | Anchor in current code |
|------------|----------------|------------------------|
| **Auto-drafted daily diary** from teacher photos + 30s voice note | Cuts teacher-side time per child from ~5 min to ~30 s | Hooks into existing `diary` typed-question system |
| **Photo moderation pre-publish** (faces present, no other children visible without consent, no PII in background) | LGPD-aligned; reduces incident risk | Plugs in before `gallery` upload |
| **Sentiment-aware urgent escalation** in chat (PT-aware) | A worried parent message bypasses the teacher's batched-reply window | New layer on `chat_bloc` |
| **Computer-vision pickup verification** (parent's face matches authorized pickup list) | Replaces or augments QR pickup; works without parents installing anything | Pairs with the QR pickup module above |
| **Attendance / behavior anomaly alerts** ("Aluno X faltou 3 dias seguidos pela primeira vez") | Early signal for school admin | Backend job; lightweight push |
| **Bilingual (PT-BR / EN) RAG-based parent FAQ assistant** | Reduces "what's the school's holiday schedule?" / "what's the medication policy?" load on teachers | New surface in chat or settings |
| **Predictive enrollment-churn signal** for the school admin | Helps the buyer prove ROI | Server-side; surfaces in admin dashboard |

### 9.5 Strategic position recommended

- **Primary play:** *Brazilian-localized, LGPD-first, AI-native* school↔home platform. Don't try to out-feature iCare on bus/gate/HR — pick the 4–5 highest-trust operational features (QR pickup, gate check-in, bus tracking, allergies, accident reports, polling) and ship them well.
- **Wedge:** AI-drafted diary entries — cuts the teacher's main daily chore. Easy to demo to a school owner in 60 seconds; nothing the competitors have.
- **Avoid:** IP cameras (LGPD risk), HR/payroll (scope creep), full discovery marketplace (flywheel investment competing with our school-relationship sale model). If a marketplace play is wanted, scope it as a separate product with a separate backend.

---

## Tasks

### Product & positioning
- [ ] [both] Document the one-line positioning statement on the App Store / Play Store listings and keep parity between flavors.
- [ ] [both] Decide and document the support / contact channel surfaced inside the app (currently unclear in `settings/about/`).
- [ ] [both] Capture screenshots of both flavors for store listings each release.

### Onboarding & approval
- [ ] [both] Add analytics events for `login_started`, `otp_verified`, `approval_pending`, `approval_granted` so we can measure activation funnel.
- [ ] [both] Define a maximum time a user can stay in `your_account_under_review` before we surface a "contact your school" CTA.
- [ ] [parents] Confirm the parent enrollment flow: can a parent be linked to a child after first login, or must the school link them first? Document the answer.

### Monetization & billing
- [ ] [both] Decide whether PIX strings should be removed if no payment flow is planned, or whether the payment flow is on the roadmap. Track decision here.

### Compliance (LGPD)
- [ ] [both] Audit Crashlytics breadcrumbs and logging to confirm no child personal data, photos, or medication info is captured.
- [ ] [both] Document data-retention policy for diary entries, chat messages, photos, and medication records — surface it in the in-app privacy policy.
- [ ] [both] Provide an account-deletion / data-export request path inside the app (LGPD Art. 18 rights).
- [ ] [professores] Ensure teachers can identify and tag posts as containing sensitive content (e.g., incident reports) for separate retention.

### Metrics & observability
- [ ] [both] Choose an analytics SDK or commit to a Firebase Analytics rollout and instrument the proposed success metrics in §7.
- [ ] [both] Define Crashlytics SLO (e.g., ≥99.5% crash-free sessions) and add a release gate.

### Two-flavor parity
- [ ] [both] Add a release checklist that requires every PR touching shared code to be smoke-tested in both flavors before merge.
- [ ] [both] Confirm CI builds AAB for both flavors on every release tag.

### Competitive gap closure — Tier 1 (quick wins, cheap because we have the primitives)

*Each item should land before the next release if possible. All reuse existing engines (`add_form`, `diary`, `attendants_selection`, `notifications`).*

- [ ] **[both] QR-code pickup / drop-off.** Combine `attendants_selection` + a new QR generator on the parent side and a scanner on the teacher side. The teacher's daily roster shows who has been picked up by whom and when. **Sells the school on safety. Closes the iCare gap. Estimated 1–2 sprints.**
- [ ] **[parents] "I'm here" / parent-arrival request.** Single tap from the parent home screen sends a push to the assigned teacher: "Parent of <Child> is at the gate." Reduces wait time at pickup. Cheap because chat infra exists.
- [ ] **[both] Allergy & medical-flag highlight on teacher app.** Surface `ChildDetailsModel` allergy/medical fields prominently on the teacher's daily roster and on the child profile header (red banner above name). Safety-first; one of the things iCare advertises and we silently have data for.
- [ ] **[both] Accident / incident report template.** New `AddFormType.incidentReport` in the `add_form` engine: who, what, when, where, severity, photo, parent signature checkbox. Generates a PDF for the school's archive. **Auditable LGPD-aligned paper trail.**
- [ ] **[both] Health / nurse log diary subtype.** New `MainCategory` for "Saúde" with temperature, symptoms, action-taken, and a "notify nurse" flag. Reuses the typed-question system; no new screen architecture.
- [ ] **[both] Polling / parent surveys.** New `AddFormType.poll`. Single-question (radio/multi-select), school-wide or per-class, results visible to admin. Useful for "Which Friday is best for the field trip?" / "How are we doing this semester?".
- [ ] **[both] Likes & comments on gallery posts.** Firestore reactions doc, same shape as chat. Drives engagement and gives the gallery feed the "Instagram-like" feel InstaKidz markets.

### Competitive gap closure — Tier 2 (institutional sale enablers — medium build)

- [ ] **[both] Gate / entry module.** A teacher-app kiosk mode runs at the school's gate tablet; scans the QR from §Tier-1 on arrival and pickup, logs timestamps, and notifies the assigned parent. Pair with `your_account_under_review`-style approval gating for kiosk auth.
- [ ] **[parents] Bus tracking (read-only).** Parent app shows the bus's current position on a map for the trip the child is on, ETA to the child's stop, and a push notification 5 min before arrival. Requires a backend partnership with a GPS / driver-app vendor; **does not require us to build the driver app initially** — we can ingest from an existing telematics API.
- [ ] **[both] White-label per-school theming.** Generalize the existing `ConfigCubit.styling` remote-config so per-school `school_id` resolves to a unique color palette + logo + app name. The two-flavor binary stays; one tenant can rebrand inside it. Unlocks the chain/franchise segment iCare currently owns.
- [ ] **[admin/web — out of scope of mobile, but tracked here] Read-receipt analytics.** Server returns `read_at` for announcements + diary entries; mobile renders "seen by X of Y parents" on the teacher side. Gives the school a metric to take to its board.

### Competitive gap closure — Tier 3 (AI-native differentiator — the real moat)

*Whitespace none of the competitors have publicly marketed. Pick 1 to ship as a flagship before everyone else catches on.*

- [ ] **[professores] AI-drafted diary entries.** Teacher snaps 3–4 photos + records a 30s voice note → an LLM drafts a per-child diary entry pre-filled into the typed-question system. Teacher reviews + taps Send. **Headline feature; this is the demo that sells the school.**
- [ ] **[professores] Photo moderation pre-publish.** Before a teacher posts to `gallery`, a vision model checks: (a) only the tagged children are recognizably visible (LGPD), (b) no PII in background (papers, screens), (c) no inappropriate framing. Suggests crops; teacher confirms.
- [ ] **[both] Sentiment-aware urgent escalation in chat.** A negative-sentiment parent message in PT-BR is tagged for the teacher with a higher-priority push, bypassing the teacher's "do not disturb" window. Optional rather than always-on.
- [ ] **[parents] PT-BR / EN parent FAQ assistant.** RAG over school-administered docs (handbook, calendar, policies); answers parent questions without bothering the teacher. Lives as a "Ask the school" tile on parent home.
- [ ] **[admin] Anomaly alerts.** Server-side: child absent for N consecutive days, sudden behavior-rating drop on diary, missed medication times. Surfaces in admin dashboard + push.
- [ ] **[admin] Enrollment-churn predictor.** Server-side ML; surfaces "at-risk families" to the admin so they can intervene proactively.

### Strategic decisions to make (NOT tasks — decisions blocking the above)

- [ ] **Decision: Do we build the marketplace/discovery layer?** This is a fundamental business-model shift (B2B SaaS → B2B2C marketplace). Document the answer here before adding any task for it. Recommendation in §9.5: defer.
- [ ] **Decision: Do we build a hardware partnership for buses?** Yes/no determines whether the bus-tracking task above is feasible this year.
- [ ] **Decision: Which AI feature is the v1 flagship?** Recommendation in §9.5: AI-drafted diary entries.
- [ ] **Decision: Do we expand beyond Brazil?** Current Arabic translation work suggests yes-someday; lock the timeline or remove the AR strings (see specs/system.md).
- [ ] **Decision: Explicitly NOT building IP camera integration. Document the rationale (LGPD) here so it doesn't get re-raised every sales call.**
