# Filhos / Criarte — Commercial Brief

> **Audience**: Commercial, sales, and client-success teams.
> **Purpose**: One place to see *what we have today*, *what we're building*, *what competitors have*, and *what's worth adding next* — written in plain English, not engineering jargon.
> **Use**: Read it, react to it, edit it. Every section has a **Commercial notes** column for your input. This brief is the input to the next product/commercial alignment session.
> **Last updated**: 2026-05-15.

---

## 0. How to read this document

### Status badges

Every feature is marked with one of these:

| Badge | Means |
|---|---|
| ✅ **Live** | Already shipped to real users on both apps. You can show it in a demo today. |
| 🚧 **In build** | Planned, committed, and scheduled. You can promise this with a "coming soon" framing. |
| 💡 **Concept** | We've discussed it; not yet committed. Don't promise it in a sale — *flag* it as roadmap. |
| ⚠ **Recheck** | An earlier comparison document claimed this is live, but production reality is different (or partial). Read the note before you use it in a pitch. |
| ❌ **Won't build** | Intentionally out of scope. Don't sell it. The reason is in the row. |

### Three things this brief is NOT

1. It is **not a technical spec** — engineering specs live under [specs/](.) per-feature, and the deep business rationale is in [business.md](business.md).
2. It is **not a public marketing document** — it's internal alignment. Edit freely.
3. It is **not authoritative for promises to clients** — verify with product before quoting a date.

---

## 1. The elevator pitch (1 page)

**Filhos / Criarte** is a Brazilian school↔home communication platform sold to private nurseries and early-education schools. It ships as **two apps from one codebase**: *Criarte* (parents) and *ProfeCriarte* (teachers). It replaces ad-hoc WhatsApp groups and paper handouts.

### What we sell
- **Real-time visibility** for parents into their child's day — food, sleep, mood, behavior, photos.
- **Structured daily reporting** for teachers — typed-question forms with images, soon voice and video.
- **Direct parent↔teacher messaging** scoped to a specific child, plus class-group chats for teachers.
- **Medication management** with prescription upload, school-side approval, and parent-side native alarm reminders.
- **Event RSVPs and paid-event status** with a payment-confirmation surface.
- **Brazil-native fit**: Portuguese-first, CPF, CEP, PIX vocabulary, LGPD framing.

### Where we'll win against iCare and InstaKidz
1. 🇧🇷 **Brazilian-localized + LGPD-first** — neither competitor is.
2. 🧠 **AABAR — in-app ABA chat agent** (planned v1 flagship) — a clinician-reviewed Applied Behavior Analysis assistant for parents AND teachers, powered by our existing n8n RAG. Nothing competitive in PT-BR. 🚧 In build.
3. 📋 **Structured typed-question diary** — more rigorous than competitor "free-form daily reports".
4. 💊 **Medicine workflow with prescription upload + parental-side native alarms** — competitors don't match this depth.
5. 🔒 **Default-off child data on AI** — every AABAR query is anonymous by default; parents opt-in per message to attach a child's diary. Defensible LGPD posture, no competitor narrative comes close.

### Where we lose today (be honest in pitches)
- 🚌 **Bus tracking / GPS / NFC pickup** — iCare's strongest area; we have nothing.
- 🚪 **Gate / pickup module** — iCare ships this; we don't.
- 💼 **HR / payroll for staff** — iCare ships this; we explicitly won't build it ([§9](#9-dont-promise-these--explicit-non-goals)).
- 🛒 **Public school-discovery marketplace** — InstaKidz pitches this; we don't and probably shouldn't.

### One-line positioning
> *"Criarte is the Brazilian-localized, LGPD-first early-education platform with a clinical-grade ABA assistant — built for nurseries that want professional documentation, parent trust, and a differentiator no competitor has."*

---

## 2. Parents app — what the family experiences

> Use this section in parent-facing demos and brochures. **Edit the "Commercial notes" column** with what your prospects ask about.

### 2.1 Daily child diary (the core surface)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Structured diary timeline** | ✅ Live | Parents pick a child + a date and read teacher-filled, typed-question reports (mood, food, sleep, activities) organized into categories | iCare: free-text daily summary. InstaKidz: similar | _(your notes here)_ |
| **Photo attachments on diary entries** | ✅ Live | Teachers attach photos per question category; parents see them in-line | Both competitors support photos | _(…)_ |
| **Multi-child support** | ✅ Live | A parent switches between enrolled children on home | Standard | _(…)_ |
| **Auto-generated daily reports from logged events** | ⚠ Recheck | The earlier comparison brief said this was Filhos's flagship. **Reality**: today, teachers fill typed-question forms; the diary is not yet auto-aggregated from real-time events. Auto-rollup is on the roadmap (see weekly digest below). | iCare: manual fields per section. InstaKidz: same as us | Don't promise "the system writes the report itself" yet. Promise "structured, fast-to-fill forms"; flag auto-generation as roadmap. |
| **Weekly digest of trends** (mood/sleep/food over the week) | 💡 Concept | Planned as part of the diary value-add layer | Neither competitor markets this | High-interest sales hook with primary-care-conscious parents. |
| **Anomaly callouts** ("sleep dropped 2 days in a row") | 💡 Concept | Planned | Neither competitor | Pitchable as "we don't just show data, we surface what matters". |
| **"Pedir interpretação à AABAR" on a diary entry** | 🚧 In build | Parent taps an entry → AABAR ABA chat opens pre-seeded with that entry. Per-message LGPD consent to attach. | None | The killer demo. See [§7 AABAR](#7-aabar--our-differentiator). |
| **Reactions on diary entries** (❤️ 👏 🥹 😂 🙏) | 🚧 In build | Parent taps a reaction; teacher sees aggregate counts | InstaKidz has "likes" energy in their photo feed | _(…)_ |
| **Comments on diary entries** | 🚧 In build | Free-form parent comments; report-abuse flag; teachers can delete on own entries | InstaKidz: comments on photos | _(…)_ |
| **Read receipts** (visible to teacher only, aggregate "Visto por X de 22 famílias") | 🚧 In build | Proves engagement to the school for procurement narrative | iCare markets engagement analytics to admins | Sales hook with school owners, not parents. |

### 2.2 Photos & gallery

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Per-child photo gallery** | ⚠ Recheck | The earlier comparison brief said this was live with backend RBAC. **Reality**: the gallery surface is built but currently **disabled in production** behind a feature gate, and the data source returns placeholder content. **Do not demo as live.** Wiring the real backend is on the near-term punchlist. | iCare: gallery with admin approval. InstaKidz: photo feed | Until the gallery un-stubs (P0 punchlist), don't show it. We'll un-block as soon as the backend wiring lands. |
| **Photos attached to a diary entry** (above) | ✅ Live | Workaround that's actually shipped | — | This is what to show in a demo today. |
| **Video clips on entries** (≤30s) | 🚧 In build | Teachers attach short clips to a question; parents play in-line | InstaKidz markets richer media | _(…)_ |
| **Voice notes on entries** (≤60s) | 🚧 In build | Teachers leave a voice note instead of typing | Neither competitor | "Teacher had her hands full, so she left a 10-second voice note about lunch" — relatable demo. |
| **Pre-publish photo moderation** (AI checks for non-consented children, PII in background) | 💡 Concept | LGPD-aligned safety pre-check | Neither competitor | School-owner pitch — limits liability. |

### 2.3 Chat (parent ↔ teacher)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **1:1 parent↔teacher chat scoped to a specific child** | ✅ Live | Text, images, file attachments, audio | iCare: parent↔nursery (institutional). InstaKidz: similar to us | Our "WhatsApp replacement" pitch — and it's child-specific, which is the differentiator vs iCare. |
| **Audio messages** | ✅ Live | Record + send + playback | iCare: text only in many surfaces | Worth showing in demos. |
| **Sentiment-aware urgent escalation** (worried parent bypasses teacher's batch-reply window) | 💡 Concept | Adds emotional urgency detection | Neither competitor | Premium feature for schools that want to be responsive. |

### 2.4 Events & RSVPs (parent side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **View school events + RSVP** | ✅ Live | Parents see upcoming events, accept/decline | Both competitors | Table-stakes feature. |
| **Paid-event status** (paid vs not paid, payment success dialog) | ✅ Live | Event has a `requiredPaid` flag; parent sees Paid/Not-Paid widget and a "Payment successfully completed" confirmation | iCare: not available per the earlier comparison | Honest framing: we surface payment **status** (confirm vs not), the actual payment may flow through PIX or an out-of-band channel today. Don't pitch as "Stripe-style in-app checkout" — pitch as "tracks who paid and who didn't, with a clean confirmation flow". |
| **Receipt upload** | ✅ Live (partial) | Parents can attach proof of payment | iCare: not available | Same caveat — verify the exact UX before quoting it. |
| **Full in-app payment SDK (Stripe / Mercado Pago)** | 💡 Concept | Would replace the upload model | iCare: no. InstaKidz: no | Recurring fee revenue opportunity for the school + commission opportunity for us. Big strategic decision. |

### 2.5 Medication management (parent side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Register a child's medication** (dosage, schedule, prescription photo) | ✅ Live | Parent uploads prescription image + structured dosage info | iCare: notes-only per earlier comparison | Headline pitch for our medical posture. |
| **Multi-step approval workflow** (parent submits → school accepts/rejects) | ✅ Live | Teacher side accepts/rejects requests | iCare: not available | Strong differentiator. |
| **Native device alarms for parent-side reminders** | ✅ Live | Survives app kill; uses native alarm wrapper | Neither competitor markets this depth | Show in demos — visceral. |
| **"Add medicine" empty-state CTA** | ⚠ Recheck | Today the Add CTA is inside a list; first-time parents with no medications can't add via the empty list. P1 punchlist. | iCare: n/a | Engineering punchlist; doesn't change pitch. |
| **Real-time push when administered** | 🚧 In build | Parents get a notification when the school records administration | iCare: not available | Pitch as "you know the moment your child got their medication". |
| **Prescription document retention & audit** | ✅ Live (LGPD redacted in logs as of 2026-05-14) | Prescription images stored; Crashlytics scrubs medication payloads | Neither competitor at this depth | LGPD-conscious schools. |

### 2.6 Toileting / diaper tracking (the infant-care depth iCare doesn't have)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Diaper changes, pee/poop counts, hydration signals as diary categories** | ⚠ Recheck | The diary's typed-question system *supports* these as a category, and the earlier comparison brief positioned this as Filhos's "critical differentiator". **Reality**: whether the production diary template a given school sees actually exposes these categories is server-side config — not all schools have it. Verify with the specific school before pitching. | iCare: explicitly not supported per earlier comparison. InstaKidz: partial | If your prospect is a 0-3 infant nursery, **this is the killer pitch** — but confirm the template is enabled for the demo school. |
| **Diaper-supply tracking** ("running out, please send more") | 💡 Concept | Earlier comparison positioned this as live for Filhos; we don't have a dedicated supply-tracking screen today | iCare: "please send" basic system | If you can sell it as "track what the school is using of your child's supplies", we'd need to build it — about a sprint. |

### 2.7 Addresses & enrollment paperwork

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Save home / pickup addresses with CEP lookup** | ✅ Live | Brazilian postal-code autocomplete via `search_cep` | Neither localized for Brazil | Brazil-local hook. |
| **Authorized-pickup-person picker** | ⚠ Recheck | Two competing scaffold screens exist for selecting attendants; neither is fully wired. Engineering punchlist will pick one and finish it. | iCare: parent-arrival module | Don't demo today; foundation for QR-code pickup (below). |
| **QR-code pickup / drop-off** | 💡 Concept | Parent shows a QR at the gate; teacher scans to release the child | iCare: not in this exact form | Tier-1 safety pitch. ~1-2 sprints once the attendant picker is finished. |
| **"I'm here" parent-arrival ping** | 💡 Concept | Single tap on parent home; teacher sees who's at the gate | iCare: parent-arrival tracking | Pairs with QR pickup. Cheap. |

### 2.8 Notifications, language, onboarding

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Push notifications with deep-link to the right screen** | ✅ Live | Diary, chat, events, announcements all push with one-tap navigation | Standard | — |
| **In-app inbox for missed pushes** | ✅ Live | If unknown notification type or app was closed, lands in inbox | Standard | — |
| **Portuguese / English / Arabic** with remote-overridable text | ✅ Live | School can re-skin copy via remote config | iCare/InstaKidz: limited | "We can tune the wording per school" — useful in enterprise sales. |
| **Phone-OTP login** | ✅ Live | Firebase SMS OTP | Standard | — |
| **Social login** (Google, Facebook, Apple) | ✅ Live | Toggleable per school via remote config | Standard | — |
| **Approval gate** (new accounts wait for school admin to approve) | ✅ Live | Pending users see "your account is under review" until approved | iCare: similar | LGPD + child-safety story. |
| **Auto-discovery of approval flips** (no need to refresh / re-login) | ⚠ Recheck | The check happens when the user re-opens the pending screen. A pending user staring at the screen won't see it flip live. Engineering punchlist. | iCare: not specified | Edge case; doesn't move sales. |

---

## 3. Teachers app — what the daily user experiences

### 3.1 Diary composition (teacher side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Compose typed-question reports per child / class / level / all-children** | ✅ Live | Structured forms: ratings, checkboxes, photo questions, free text, numbers, durations | iCare: manual fields. InstaKidz: similar | Pitch: "the form does the structure for you — you just fill it". |
| **Image attachments inline** | ✅ Live | Multi-image per question | Both competitors | — |
| **Save-as-draft (survives app kill AND device switches)** | 🚧 In build | Teacher drafts on the tablet at the classroom, finishes on phone | iCare markets the "draft over the day" workflow | Critical for the everyday-use pitch with teachers. |
| **Soft-delete + resend (recover from wrong-child mistake)** | 🚧 In build | Teacher retracts an entry; if they resend within 24h, parent reactions/comments transfer | Neither competitor | Trust pitch — "you can recover, with an audit trail, without the parent thinking we erased history". |
| **Voice + short video question types** | 🚧 In build | Teacher records 10s audio or 30s video instead of typing | InstaKidz: media-rich | "When you can't type, talk." |
| **Read receipts aggregate** ("Visto por 18 de 22 famílias") | 🚧 In build | Teacher sees engagement count per entry | iCare: per-family detail in admin | Sales hook — the school sees that parents read the diary. |
| **Hardcoded child-id bug in template fetch** | ⚠ Internal | Engineering P0; doesn't affect demos. | — | — |

### 3.2 Chat (teacher side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **1:1 with parent in context of a child** | ✅ Live | Same as parent side | Both competitors | — |
| **Class-group chat (teachers + parents of the class)** | ✅ Live | Teacher broadcasts; parents reply | iCare: nursery-wide | Differentiator: it's class-scoped, not the whole nursery. |

### 3.3 Medication (teacher side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **See medications registered for kids in their class** | ✅ Live | List view with prescription image | iCare: notes-only | Pitch as "you walk into class knowing what every child needs today". |
| **Accept / reject parent's medication request** | ✅ Live | Teacher can decline a request | iCare: not available | — |
| **Confirm administration with timestamp** | ✅ Live (basic) | Teacher records the time given | Both competitors basic | — |
| **Photo proof on administration** | 💡 Concept | Teacher snaps proof | iCare: not available | LGPD-conscious — only if the school's policy allows it. |
| **Reject-request attachments work end-to-end** | ⚠ Internal | Engineering P0; attachments dropped today. Doesn't change pitch. | — | — |

### 3.4 Events (teacher side)

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Create / edit / cancel events** | ✅ Live | Event with RSVP and optional payment flag | iCare: similar | — |
| **See who RSVPed** | ✅ Live | Per-event attendance list | Both competitors | — |
| **EventBus subscription leak on event screen** | ⚠ Internal | Engineering P0. Doesn't affect demos. | — | — |

### 3.5 Search

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Search children in class** | ✅ Live (with caveat) | Teacher finds a child by name | Standard | — |
| **Parents-side teacher search** | ⚠ Recheck | The screen exists but always hits the teacher endpoint regardless of which app you're on — engineering P0. | — | Don't demo from the parent app. |

---

## 4. School / admin operations

> Most of the admin/school-side work in iCare's PDF lives in their separate admin web tool — Filhos's admin tooling is a separate workstream from the mobile app. This brief focuses on the mobile experience; admin-web parity is a separate roadmap.

| Sub-feature | Status | What it does today | What competitors do | Commercial notes |
|---|---|---|---|---|
| **Announcements broadcast** | ✅ Live | Push + in-app inbox | Both competitors | — |
| **Approval gate for new accounts** | ✅ Live | Admin approves pending users | iCare: similar | — |
| **Per-school remote configuration of UI text & colors** | ✅ Live | Translations and theme color overrides via Firestore | iCare: limited | Useful enterprise hook. |
| **Per-school white-label** (each nursery has its own app on the store) | ⚠ Recheck | The earlier comparison brief described this as a Filhos advantage. **Reality**: today the codebase ships as two app-store apps (Criarte + ProfeCriarte). Per-nursery white-label theming is a planned Tier-2 feature, not yet built. | iCare: single-branded | If a school asks for "their own branded app on the store", the answer is "we're building that; here's our timeline". Don't pitch as live. |
| **Read-receipt analytics for diary** | 🚧 In build | Server-side aggregate that the admin web will surface; mobile shows the teacher-side count | iCare: admin analytics | School-owner pitch — proves engagement. |
| **Engagement / compliance dashboard for school admins** | 💡 Concept | Server-side; would need a separate admin web build | iCare: live | If the school is buying for compliance, this becomes a tie-breaker. |
| **HR / payroll for staff** | ❌ Won't build | Out of scope — scope creep, deep specialty | iCare: live, especially GCC visa tracking | Don't sell it. Refer to a dedicated HR vendor. |
| **Bus tracking, GPS, speed alerts, NFC pickup** | ❌ Won't build (or: only with a hardware partner) | Out of scope unless we sign a GPS partner | iCare: live and marketed | Be honest: "transportation isn't our story". If the school's main pain is bus safety, iCare is the right pick for them. |
| **IP camera streaming** | ❌ Won't build | LGPD risk in Brazil + brand damage if a stream is breached | Some competitors offer this | Hard no. Refuse politely. |

---

## 5. AABAR — our differentiator

> This deserves its own section because it's the v1 flagship and there's nothing comparable from any competitor.

### What it is

A native in-app chat with an **Applied Behavior Analysis (ABA)** specialist agent. Built on our existing AABAR n8n RAG (the same one that powers the AABAR website), with a corpus signed off by a named ABA clinical reviewer.

### Status: 🚧 In build (full per-feature spec at [specs/aabar/](aabar/))

### Why it sells

| Audience | The pitch |
|---|---|
| **School owner** | "Your families increasingly need ABA support — autism enrollment is rising in Brazilian early-ed. We give your staff and their families a clinical-grade PT-BR assistant nobody else has." |
| **Teachers** | "You're handling a difficult moment with a neurodivergent child. AABAR is in your pocket, in Portuguese, with answers grounded in real ABA literature reviewed by a credentialed clinician." |
| **Parents** | "When the diary says your child rated their day low and you don't know what to do, AABAR is one tap away — and it can interpret today's diary entry if you choose to share it." |

### How privacy works (you'll be asked)

- **Default**: AABAR sees only your role (parent or teacher), the school id, and the prompt text. No child names. No diary entries.
- **Per-message opt-in**: A parent can *tick a box* on a single message to attach that child's recent diary entries. The tick resets to OFF after that message — never sticky.
- **Right to delete**: When a user deletes their account, AABAR-side conversation history is wiped server-to-server.
- **Disclaimer**: "AABAR is informational — for clinical decisions, consult a BCBA (Board Certified Behavior Analyst)." Always visible on the chat.

### What you can promise in v1

- ✅ Free-form ABA chat from the home tile (both apps)
- ✅ "Pedir interpretação à AABAR" tap on a diary entry (pre-seeded with that entry, consent-gated)
- ✅ Both Portuguese (primary) and English answers
- ✅ "Meus consentimentos AABAR" audit screen — every consent the user has ever given, with revoke

### What's NOT in v1 (don't promise)

- ❌ Voice input / output (v2)
- ❌ Image input (v2)
- ❌ Cross-conversation memory (every chat starts fresh — by design)
- ❌ User-uploaded documents into the corpus (the AABAR team owns the corpus)
- ❌ Group chats with AABAR

---

## 6. Roadmap themes for your review

> This is where commercial / sales judgment is most valuable. Flag what your prospects keep asking for — that should drive prioritization.

### Tier 1 — we're already building (next 1–2 quarters)

| Theme | What lands | Pitchable as |
|---|---|---|
| **AABAR in-app ABA agent** | The flagship, both apps | "AI specialist your competitors don't have" |
| **Diary social layer** | Reactions + comments on entries | "Parents engage, not just read" |
| **Save-as-draft + retract/resend** | Teacher daily workflow | "Match the iCare daily-draft ergonomics" |
| **Voice + video diary entries** | Multimedia richness | "Modern parents expect this" |
| **Read receipts (aggregate)** | School proves engagement | "Sell to the school owner" |
| **Gallery un-stub** | Real backend wiring | "It's coming online" — currently hidden |
| **Medicine UX fixes** | Empty-state CTA, reject-attachments | Internal polish |

### Tier 2 — committed-to-discuss (within 6 months, contingent on book of business)

| Theme | What it unlocks | Comparator parity |
|---|---|---|
| **QR-code pickup** | Safety + parent peace of mind | Beats iCare's basic parent-arrival |
| **Gate / kiosk module** | Teacher tablet at the gate | iCare parity |
| **Allergy & medical flags surfaced to teachers** | Safety + LGPD-grade data | New territory |
| **Accident / incident report template** | Legal paper trail | New territory (uses existing form engine) |
| **Health / nurse log diary subtype** | Post-COVID expectation | iCare parity |
| **Polling / parent surveys** | School governance + engagement | Uses existing form engine |
| **Per-school white-label** | Each nursery gets its own store app | InstaKidz/iCare gap |
| **Bus tracking** | Only with a GPS hardware partner | iCare's strongest area |

### Tier 3 — strategic (needs commercial decision before we commit)

| Theme | The strategic question | Defer reason |
|---|---|---|
| **AI-drafted diary entries** (teacher snaps photos + 30s voice note → AI fills the diary) | Should this be AABAR-adjacent or a separate workstream? | Wait for AABAR v1 to validate the AI workflow. |
| **Photo moderation pre-publish** | Insurance against LGPD photo incidents | After gallery un-stub. |
| **PT-BR school-handbook RAG** | Parents ask "what's the holiday schedule?" — a separate Q&A agent | Distinct from AABAR (which is clinical). |
| **Sentiment-aware chat escalation** | A worried-parent message jumps the teacher's reply queue | Privacy-heavy, needs school buy-in. |
| **Anomaly alerts** (child absent N days, behavior drop) | Server-side, fires to admin/teacher | Pairs with admin-web roadmap. |
| **Full Stripe / Mercado Pago / PIX-API in-app checkout** | Replaces the upload-confirm model with a real PSP | Recurring revenue opportunity. |
| **Public school-discovery marketplace** (InstaKidz model) | Pivot from B2B SaaS to two-sided marketplace | Different business; consider as a separate product. |

---

## 7. Side-by-side competitor cheat sheet

> A pocket version of the full competitor analysis. Edit freely.

| Area | Filhos (today) | Filhos (planned) | iCare | InstaKidz | Who wins |
|---|---|---|---|---|---|
| Brazilian fit (PT-BR, CPF, CEP, PIX) | ✅ Live | — | None | None | **Filhos** |
| LGPD posture (default-off PII, per-msg consent, redacted logs) | ✅ Live | + AABAR consent ledger | Generic privacy | Generic privacy | **Filhos** |
| Structured typed-question diary | ✅ Live | + voice/video + reactions/comments | Free-text reports | Free-text reports | **Filhos** |
| Auto-aggregated daily report from real-time events | ⚠ Roadmap | 💡 Concept | Manual fields | Manual fields | Tie (none ship it today) |
| Photos & gallery | ⚠ Partial (gallery stub) | 🚧 un-stub coming | ✅ With admin approval | ✅ Photo feed | iCare/InstaKidz today; tie after un-stub |
| Video clips on entries | ❌ Not yet | 🚧 In build (≤30s) | ✅ ≤30s | ✅ | Tie after we ship |
| Voice notes on entries | ❌ Not yet | 🚧 In build (≤60s) | ❌ | ❌ | **Filhos** after we ship |
| Chat (1:1, child-scoped) | ✅ Live | + sentiment escalation 💡 | Institutional only | ✅ | **Filhos** for child-scope; tie on basic chat |
| Audio chat messages | ✅ Live | — | ❌ | ✅ | Filhos / InstaKidz |
| Group chat (class-level) | ✅ Live | — | Nursery-wide | — | **Filhos** for class-level granularity |
| Medication (prescription + approval workflow + native alarms + admin proof) | ✅ Live | + administration push 🚧 | Notes only | Notes | **Filhos** by a wide margin |
| Diaper / toileting / hydration tracking | ⚠ Schema-supports; template-config-dependent | — | ❌ | Partial | **Filhos** if the school's template enables it |
| Events + RSVP | ✅ Live | + full PSP 💡 | ✅ RSVP only | ✅ | **Filhos** (we have paid-event status) |
| In-app payment confirmation flow | ✅ Live (status + receipt) | 💡 Full PSP | ❌ | ❌ | **Filhos** |
| Bus tracking / GPS / NFC pickup | ❌ Won't build solo | 💡 Tier-2 with hardware partner | ✅ Full stack | ❌ | **iCare** |
| Gate / kiosk module | ❌ Not yet | 💡 Tier-2 | ✅ Live | ❌ | **iCare** |
| HR / payroll for staff | ❌ Won't build | — | ✅ Live | ❌ | **iCare** |
| Per-school white-label app | ❌ Not yet (single Criarte + ProfeCriarte today) | 💡 Tier-2 | ❌ Single iCare brand | ❌ | InstaKidz markets brand-ownership; we'll catch up |
| AI: in-app ABA specialist | ❌ Not yet | 🚧 AABAR is THE flagship | ❌ | ❌ | **Filhos** when we ship |
| AI: drafted diary entries | ❌ Not yet | 💡 Tier-3 | ❌ | ❌ | **Filhos** if we commit |
| AI: photo moderation | ❌ Not yet | 💡 Tier-3 | ❌ | ❌ | **Filhos** if we commit |
| Admin web (engagement / compliance dashboards) | ❌ Separate roadmap | 💡 | ✅ | Partial | iCare today |
| Public school-discovery marketplace | ❌ Won't build (under current strategy) | — | ❌ | ✅ | InstaKidz (different business model) |
| IP camera | ❌ Won't build | — | Some | — | We refuse — LGPD |

---

## 8. Two narratives to take into the field

### Narrative A — "The Brazilian-localized, professional-grade alternative" (for nurseries)

> **Hook**: Most platforms in your market are either WhatsApp groups (cheap, chaotic, no audit) or imported tools from another country (wrong language, wrong currency, wrong compliance). We built Criarte specifically for Brazilian schools.
>
> **Proof**: Portuguese-first UI, CPF / CEP / PIX vocabulary native, LGPD-grade documentation (medication prescriptions, audit trails, redacted logs). Structured typed-question diary that's more rigorous than the "type whatever" daily summary your teachers write in WhatsApp.
>
> **Differentiator (the close)**: We're the only platform with an in-app ABA specialist agent built on a clinically-reviewed corpus — when the question goes beyond "what did Maria eat today" and into "how do I support my child with autism", we have the answer no one else has.

### Narrative B — "The school is buying engagement, not features" (for school owners)

> **Hook**: Your families pay you for outcomes — peace of mind, transparency, professional care. We give you the tooling to prove that to them every day.
>
> **Proof**: Real-time push when their child eats, sleeps, gets medication. A structured diary that looks like a clinical record, not a WhatsApp message. Aggregate read receipts so YOU can see which families are engaged and where to follow up.
>
> **Differentiator (the close)**: AABAR doesn't just respond to families when they reach out — it elevates your school's positioning. "We're the Brazilian nursery with the in-app ABA specialist" is a procurement narrative no competitor can match.

---

## 9. Don't promise these — explicit non-goals

To save sales conversations from awkward backtracking:

| Feature | Why we refuse / defer | What to say instead |
|---|---|---|
| **IP camera live streaming of classrooms** | LGPD risk in Brazil. A child stream breach would end the business. | "We focus on documentation and communication; for live monitoring, talk to a dedicated security vendor — but we'd advise against it for liability reasons." |
| **HR / payroll for staff** | Scope creep; deep vertical specialty. iCare wins here, that's fine. | "We focus on the parent ↔ teacher loop. For HR, partner with a Brazilian HR vendor." |
| **Public school-discovery marketplace (à la InstaKidz)** | Different business model; flywheel competing with our B2B sale. | "We're a focused B2B SaaS. If discovery is the pain point, that's a different product." |
| **Replacing a clinical electronic health record** | We're informational; AABAR is opt-in support, not a clinical decision tool. | "We complement your school's clinical processes, we don't replace them." |
| **Generic AI chatbot for any question** | AABAR is intentionally scoped to ABA; school-handbook RAG is a separate planned thing. | "Our AI is a specialist, not a generalist — that's why it's defensible." |

---

## 10. Open product/commercial decisions that need your input

> These directly affect what we build next. Add your reaction.

| Decision | Options | Commercial reaction |
|---|---|---|
| **AABAR rollout staging** — both apps at launch, or teachers-only pilot for 30 days first? | Both immediately (max impact) vs Teachers pilot (safer rollout, less viral) | _(your notes)_ |
| **Name the AABAR clinical reviewer publicly** in app + store listings? | Yes (marketing leverage) vs No (privacy of the reviewer) | _(…)_ |
| **AABAR per-school webhook?** Single org-wide AI vs per-school AI (each school could feed its own handbooks into a separate corpus) | Single (simpler) vs Per-school (white-label premium) | _(…)_ |
| **Full PSP for events** — Stripe / Mercado Pago / PIX-API? | Replaces upload-confirm model; opens revenue share | _(…)_ |
| **Bus tracking partnership?** | Pick a Brazilian GPS hardware partner and ship | _(…)_ |
| **Build the public school-discovery marketplace?** | Strategic pivot or "no" | _(…)_ |
| **`select_attendants` vs `attendants_selection`** — internal naming collision, but the decision is "is the pickup picker for *children* or *authorized guardians*?" | Children vs Guardians (each implies different UX) | _(…)_ |
| **Where should the "Meus consentimentos AABAR" audit screen live in the app?** | Inside Settings (recommended) vs as a top-level item | _(…)_ |

---

## 11. How to edit this document

This brief lives at [specs/commercial-brief.md](commercial-brief.md). Anyone on the commercial / product team can:

1. **Add to the "Commercial notes" columns** — what your prospects ask about, what you observe in pitches, where you got pushback.
2. **Re-rank Tier 2 / Tier 3 themes** — change the priority based on what you keep hearing in the field.
3. **Flag inaccuracies** — if you discover the product behaves differently than this brief says, leave a `⚠ Reality check: …` note. Don't delete; product will reconcile.
4. **Add Narratives** beyond A and B — if you've found a third positioning that works, add §8.3.
5. **Add competitor entries** — if you're losing deals to a competitor not named here (Famly, HiMama, illumine, MyKidReports, KinderConnect, etc.), add them to §7.

**Don't**:
- ❌ Don't change status badges (✅/🚧/💡/⚠/❌) — those need product confirmation. Use the notes columns instead.
- ❌ Don't add features as 🚧 In build unless product has confirmed.
- ❌ Don't make this a public document — it's internal alignment.

For the deep business rationale behind any planned feature, see [business.md](business.md). For per-feature engineering specs, see the matching directory under [specs/](.) (e.g., [specs/aabar/](aabar/), [specs/diary/](diary/)).

---

## 12. Changelog

- **2026-05-15** (v1.0) — initial brief. Reconciles the prior *iCare vs Filhos Comprehensive Analysis* PDF against current code reality (4 "⚠ Recheck" items where the prior PDF's claims were aspirational or partial), folds in the AABAR plan and the diary competitive enhancement scope, and exposes 8 open commercial decisions for the team to react to.
