---
name: spec-kit-migration-index
status: index
description: Registry of every Criarte feature and its migration status into spec-kit per-feature trios.
---

# Spec-Kit Migration Index

Bridges the existing source-of-truth ([business.md](business.md), [system.md](system.md), [design.md](design.md), [features.md](features.md), [review.md](review.md)) into the spec-kit per-feature workflow.

Per-feature trios (`specs/<feature>/spec.md` + `plan.md` + `tasks.md`) are generated **on demand** — not all at once. The detailed inventory already lives in [features.md](features.md); this index just tells the migrate command where to look and what's been done.

## How to use this index

1. **Pick a feature** from the table below.
2. **Run** `/speckit.brownfield.migrate <feature>` — the command should treat the linked anchor in [features.md](features.md) as the primary source, augmented by code analysis of `lib/features/<feature>/`.
3. **Update this index** — flip the feature's status from 🔴 to 🟢 (or 🟡 if partial) and link to the new `specs/<feature>/` directory.
4. **Re-validate** with `/speckit.brownfield.validate` after each migration.

## Status legend

- 🔴 **Not migrated** — source-of-truth lives only in [features.md](features.md)
- 🟡 **In progress** — partial trio under `specs/<feature>/`
- 🟢 **Migrated** — full `spec.md` / `plan.md` / `tasks.md` trio under `specs/<feature>/`
- 💡 **Proposed** — not yet implemented; use `/speckit.specify`, not migrate

## Implemented features

Sorted by file count (largest first) to make the cost of each migration visible up front. File counts from a `find lib/features/<feature> -name '*.dart' | wc -l` on 2026-05-14.

| Feature | Code | Flavor | .dart files | Source-of-truth (features.md) | Trio status |
|---|---|---|---:|---|:---:|
| settings | [lib/features/settings/](../lib/features/settings/) | B | 91 | [#settings--b](features.md#settings--b) | 🔴 |
| diary | [lib/features/diary/](../lib/features/diary/) | B | 68 | [#diary--b](features.md#diary--b) | 🔴 |
| add_form | [lib/features/add_form/](../lib/features/add_form/) | B | 47 | [#add_form--b](features.md#add_form--b) | 🔴 |
| chat | [lib/features/chat/](../lib/features/chat/) | B | 44 | [#chat--b](features.md#chat--b) → [specs/chat/](chat/) | 🟢 |
| home | [lib/features/home/](../lib/features/home/) | B | 16 | [#home--b](features.md#home--b) | 🔴 |
| login | [lib/features/login/](../lib/features/login/) | B | 11 | [#login--b](features.md#login--b) → [specs/login/](login/) | 🟢 |
| add_address | [lib/features/add_address/](../lib/features/add_address/) | P | 9 | [#add_address--p](features.md#add_address--p) | 🔴 |
| otp | [lib/features/otp/](../lib/features/otp/) | B | 8 | [#otp--b](features.md#otp--b) → [specs/otp/](otp/) | 🟢 |
| my_addresses | [lib/features/my_addresses/](../lib/features/my_addresses/) | P | 8 | [#my_addresses--p](features.md#my_addresses--p) | 🔴 |
| search | [lib/features/search/](../lib/features/search/) | B | 7 | [#search--b](features.md#search--b) | 🔴 |
| search_for_filter | [lib/features/search_for_filter/](../lib/features/search_for_filter/) | B | 7 | [#search_for_filter--b](features.md#search_for_filter--b) | 🔴 |
| notifications | [lib/features/notifications/](../lib/features/notifications/) | B | 6 | [#notifications--b](features.md#notifications--b) → [specs/notifications/](notifications/) | 🟢 |
| main | [lib/features/main/](../lib/features/main/) | B | 6 | [#main--b](features.md#main--b) | 🔴 |
| all_children | [lib/features/all_children/](../lib/features/all_children/) | P | 6 | [#all_children--p](features.md#all_children--p) | 🔴 |
| gallery | [lib/features/gallery/](../lib/features/gallery/) | P | 5 | [#gallery--p](features.md#gallery--p) | 🔴 |
| terms_and_condtions | [lib/features/terms_and_condtions/](../lib/features/terms_and_condtions/) | B | 5 | [#terms_and_condtions--b](features.md#terms_and_condtions--b) | 🔴 |
| splash | [lib/features/splash/](../lib/features/splash/) | B | 4 | [#splash--b](features.md#splash--b) → [specs/splash/](splash/) | 🟢 |
| register | [lib/features/register/](../lib/features/register/) | B | 4 | [#register--b](features.md#register--b) → [specs/register/](register/) | 🟢 |
| featured_events | [lib/features/featured_events/](../lib/features/featured_events/) | B | 4 | [#featured_events--b](features.md#featured_events--b) | 🔴 |
| background_services | [lib/features/background_services/](../lib/features/background_services/) | B | 4 | [#background_services--b](features.md#background_services--b) | 🔴 |
| gallery_images | [lib/features/gallery_images/](../lib/features/gallery_images/) | P | 3 | [#gallery_images--p](features.md#gallery_images--p) | 🔴 |
| add_medicine | [lib/features/add_medicine/](../lib/features/add_medicine/) | P | 2 | [#add_medicine--p](features.md#add_medicine--p) | 🔴 |
| your_account_under_review | [lib/features/your_account_under_review/](../lib/features/your_account_under_review/) | B | 1 | [#your_account_under_review--b](features.md#your_account_under_review--b) | 🔴 |
| select_attendants | [lib/features/select_attendants/](../lib/features/select_attendants/) | B | 1 | [#select_attendants--b](features.md#select_attendants--b) | 🔴 |
| privacy_policy | [lib/features/privacy_policy/](../lib/features/privacy_policy/) | B | 1 | [#privacy_policy--b](features.md#privacy_policy--b) | 🔴 |
| onboard | [lib/features/onboard/](../lib/features/onboard/) | B | 1 | [#onboard--b](features.md#onboard--b) | 🔴 |
| choose_language | [lib/features/choose_language/](../lib/features/choose_language/) | B | 1 | [#choose_language--b](features.md#choose_language--b) | 🔴 |
| attendants_selection | [lib/features/attendants_selection/](../lib/features/attendants_selection/) | B | 1 | [#attendants_selection--b](features.md#attendants_selection--b) | 🔴 |

**Coverage**: 6 / 28 features migrated to per-feature trios ([login](login/), [otp](otp/), [splash](splash/), [register](register/), [notifications](notifications/), [chat](chat/)).

## Proposed features (not yet implemented)

These are candidates from the iCare Kids / InstaKidz competitive analysis in [features.md "Proposed features"](features.md#proposed-features--competitive-gap-closure-added-2026-05-14). They have no code yet — use `/speckit.specify` to create a fresh spec when one is greenlit, **not** `/speckit.brownfield.migrate`.

| Feature | Flavor | Tier | Source |
|---|---|---|---|
| qr_pickup | B | 1 | [#qr_pickup--b](features.md#qr_pickup--b-tier-1--proposed) |
| parent_arrival | P | 1 | [#parent_arrival--p](features.md#parent_arrival--p-tier-1--proposed) |
| allergies | B | 1 | [#allergies--b](features.md#allergies--b-tier-1--proposed) |
| incident_report | B | 1 | [#incident_report--b](features.md#incident_report--b-tier-1--proposed) |
| health_log | B | 1 | [#health_log--b](features.md#health_log--b-tier-1--proposed) |
| poll | B | 1 | [#poll--b](features.md#poll--b-tier-1--proposed) |
| reactions | B | 1 | [#reactions--b](features.md#reactions--b-tier-1--proposed) |
| gate_module | B | 2 | [#gate_module--b](features.md#gate_module--b-tier-2--proposed) |
| bus_tracking | P | 2 | [#bus_tracking--p](features.md#bus_tracking--p-tier-2--proposed) |
| white_label_theming | B | 2 | [#white_label_theming--b](features.md#white_label_theming--b-tier-2--proposed) |
| ai_diary_draft | T | 3 | [#ai_diary_draft--t](features.md#ai_diary_draft--t-tier-3--proposed--flagship-ai-feature) |
| photo_moderation | T | 3 | [#photo_moderation--t](features.md#photo_moderation--t-tier-3--proposed) |
| chat_sentiment | B | 3 | [#chat_sentiment--b](features.md#chat_sentiment--b-tier-3--proposed) |
| parent_faq_assistant | P | 3 | [#parent_faq_assistant--p](features.md#parent_faq_assistant--p-tier-3--proposed) |
| anomaly_alerts | T+admin | 3 | [#anomaly_alerts--admint](features.md#anomaly_alerts--admint-tier-3--proposed-primarily-server-side) |

## Explicit non-goals

From [features.md "NOT building" section](features.md#not-building--explicit-non-goals-from-93):

- ❌ **IP camera integration** — LGPD risk in BR for a children's product
- ❌ **HR / payroll module** — scope creep
- ❌ **Full discovery / marketplace pivot** — different business model

## Suggested migration order

Recommended sequence for the first few migrations — small and self-contained first to validate the spec-kit template, then up the complexity ladder:

1. ~~**`login`** (11 files, well-documented in features.md, clean P0 task list) — proves the template format~~ ✅ Migrated 2026-05-14 → [specs/login/](login/)
2. ~~**`otp`** or **`splash`** — small, clear boundaries~~ ✅ Both migrated 2026-05-14 → [specs/otp/](otp/), [specs/splash/](splash/)
3. ~~**`register`** (4 files, shares LoginRepository)~~ ✅ Migrated 2026-05-14 → [specs/register/](register/)
4. ~~**`notifications`** — exercises the FCM / deep-link / approval-gate axes~~ ✅ Migrated 2026-05-14 → [specs/notifications/](notifications/)
5. ~~**`chat`** — first complex Firestore-backed feature; stresses the "backend touchpoints" template section~~ ✅ Migrated 2026-05-14 → [specs/chat/](chat/). **Surfaced blocking compile bug: duplicate `_asMap` declaration in `message.dart` ([T-fix-1](chat/tasks.md))**.
6. **`diary`** — typed-question domain; will surface any template gaps for schema-driven UI
7. **`settings`** — largest; split into sub-features (`edit_profile`, `my_children`, `medicines`, `announcements`, `events`, `about`) per the source-of-truth in features.md

~~`register` is **not yet in [features.md](features.md)**~~ ✅ Anchor added and feature migrated 2026-05-14 → [specs/register/](register/).

## Stale claims in existing `specs/` (resolved 2026-05-14)

✅ [specs/system.md §1](system.md#1-stack-snapshot) reconciled to `Flutter 3.29.3` + `.fvmrc`.

✅ [CLAUDE.md §2.1 Stack](../CLAUDE.md) and §2.5 build/run note reconciled to `Flutter 3.29.3` + `.fvmrc`.

Constitution v1.1.0, [system.md](system.md), and [CLAUDE.md](../CLAUDE.md) now agree.

## Cross-feature work (already tracked in features.md)

The "Cross-feature tasks" section at the bottom of [features.md](features.md#cross-feature-tasks) — covering CI, testing baseline, lint rules, package upgrades, license/readme, i18n key sync, analytics — is **not** a per-feature migration target. Surface those items into a project-level plan when ready; they don't belong in any one `specs/<feature>/`.

## Next step

Pick a feature from the **Suggested migration order** above and run `/speckit.brownfield.migrate <feature>`. The command will:

1. Read the matching [features.md](features.md) section as primary source
2. Cross-reference code in `lib/features/<feature>/`
3. Generate `specs/<feature>/spec.md`, `plan.md`, `tasks.md` using the customized templates in [.specify/templates/](../.specify/templates/)
4. Mark tasks already-complete (✓) when they correspond to ticked items in features.md
5. Surface gaps as `[NEEDS CLARIFICATION]` markers

Re-run `/speckit.brownfield.validate` after each migration to confirm artifacts match reality.
