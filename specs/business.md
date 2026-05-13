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
