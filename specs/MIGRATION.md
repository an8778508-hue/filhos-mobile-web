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

Sorted by file count (largest first). All 28 features migrated to per-feature trios as of 2026-05-15.

| Feature | Code | Flavor (code) | .dart files | Source-of-truth | Trio |
|---|---|---|---:|---|:---:|
| settings | [lib/features/settings/](../lib/features/settings/) | B | 91 | [#settings--b](features.md#settings--b) | [specs/settings/](settings/) 🟢 |
| diary | [lib/features/diary/](../lib/features/diary/) | B | 68 | [#diary--b](features.md#diary--b) | [specs/diary/](diary/) 🟢 |
| add_form | [lib/features/add_form/](../lib/features/add_form/) | B | 47 | [#add_form--b](features.md#add_form--b) | [specs/add_form/](add_form/) 🟢 |
| chat | [lib/features/chat/](../lib/features/chat/) | B | 44 | [#chat--b](features.md#chat--b) | [specs/chat/](chat/) 🟢 |
| home | [lib/features/home/](../lib/features/home/) | B | 16 | [#home--b](features.md#home--b) | [specs/home/](home/) 🟢 |
| login | [lib/features/login/](../lib/features/login/) | B | 11 | [#login--b](features.md#login--b) | [specs/login/](login/) 🟢 |
| add_address | [lib/features/add_address/](../lib/features/add_address/) | **B** (features.md says P — drift) | 9 | [#add_address--p](features.md#add_address--p) | [specs/add_address/](add_address/) 🟢 |
| otp | [lib/features/otp/](../lib/features/otp/) | B | 8 | [#otp--b](features.md#otp--b) | [specs/otp/](otp/) 🟢 |
| my_addresses | [lib/features/my_addresses/](../lib/features/my_addresses/) | **B** (features.md says P — drift) | 8 | [#my_addresses--p](features.md#my_addresses--p) | [specs/my_addresses/](my_addresses/) 🟢 |
| search | [lib/features/search/](../lib/features/search/) | B | 7 | [#search--b](features.md#search--b) | [specs/search/](search/) 🟢 |
| search_for_filter | [lib/features/search_for_filter/](../lib/features/search_for_filter/) | B | 7 | [#search_for_filter--b](features.md#search_for_filter--b) | [specs/search_for_filter/](search_for_filter/) 🟢 |
| notifications | [lib/features/notifications/](../lib/features/notifications/) | B | 6 | [#notifications--b](features.md#notifications--b) | [specs/notifications/](notifications/) 🟢 |
| main | [lib/features/main/](../lib/features/main/) | B | 6 | [#main--b](features.md#main--b) | [specs/main/](main/) 🟢 |
| all_children | [lib/features/all_children/](../lib/features/all_children/) | **T** (features.md says P — drift) | 6 | [#all_children--p](features.md#all_children--p) | [specs/all_children/](all_children/) 🟢 |
| gallery | [lib/features/gallery/](../lib/features/gallery/) | P (stub — entry-point `if(false)`-gated) | 5 | [#gallery--p](features.md#gallery--p) | [specs/gallery/](gallery/) 🟢 |
| terms_and_condtions | [lib/features/terms_and_condtions/](../lib/features/terms_and_condtions/) | B | 5 | [#terms_and_condtions--b](features.md#terms_and_condtions--b) | [specs/terms_and_condtions/](terms_and_condtions/) 🟢 |
| splash | [lib/features/splash/](../lib/features/splash/) | B | 4 | [#splash--b](features.md#splash--b) | [specs/splash/](splash/) 🟢 |
| register | [lib/features/register/](../lib/features/register/) | B | 4 | [#register--b](features.md#register--b) | [specs/register/](register/) 🟢 |
| featured_events | [lib/features/featured_events/](../lib/features/featured_events/) | B | 4 | [#featured_events--b](features.md#featured_events--b) | [specs/featured_events/](featured_events/) 🟢 |
| background_services | [lib/features/background_services/](../lib/features/background_services/) | B | 4 | [#background_services--b](features.md#background_services--b) | [specs/background_services/](background_services/) 🟢 |
| gallery_images | [lib/features/gallery_images/](../lib/features/gallery_images/) | P (stub — cataas.com) | 3 | [#gallery_images--p](features.md#gallery_images--p) | [specs/gallery_images/](gallery_images/) 🟢 |
| add_medicine | [lib/features/add_medicine/](../lib/features/add_medicine/) | P | 2 | [#add_medicine--p](features.md#add_medicine--p) | [specs/add_medicine/](add_medicine/) 🟢 |
| your_account_under_review | [lib/features/your_account_under_review/](../lib/features/your_account_under_review/) | B | 1 | [#your_account_under_review--b](features.md#your_account_under_review--b) | [specs/your_account_under_review/](your_account_under_review/) 🟢 |
| select_attendants | [lib/features/select_attendants/](../lib/features/select_attendants/) | B (placeholder stub) | 1 | [#select_attendants--b](features.md#select_attendants--b) | [specs/select_attendants/](select_attendants/) 🟢 |
| privacy_policy | [lib/features/privacy_policy/](../lib/features/privacy_policy/) | B | 1 | [#privacy_policy--b](features.md#privacy_policy--b) | [specs/privacy_policy/](privacy_policy/) 🟢 |
| onboard | [lib/features/onboard/](../lib/features/onboard/) | P (teachers skip upstream) | 1 | [#onboard--b](features.md#onboard--b) | [specs/onboard/](onboard/) 🟢 |
| choose_language | [lib/features/choose_language/](../lib/features/choose_language/) | B | 1 | [#choose_language--b](features.md#choose_language--b) | [specs/choose_language/](choose_language/) 🟢 |
| attendants_selection | [lib/features/attendants_selection/](../lib/features/attendants_selection/) | B (scaffold — multi-select half missing) | 1 | [#attendants_selection--b](features.md#attendants_selection--b) | [specs/attendants_selection/](attendants_selection/) 🟢 |

**Settings sub-trios** (the parent shell at [specs/settings/](settings/) routes to these):
- [specs/settings/edit_profile/](settings/edit_profile/) 🟢
- [specs/settings/my_children/](settings/my_children/) 🟢
- [specs/settings/medicines/](settings/medicines/) 🟢 (covers parent `medicines/` + teacher `medicines_professors/`)
- [specs/settings/announcements/](settings/announcements/) 🟢 (reachable from Home tiles + push, not the Settings shell)
- [specs/settings/events/](settings/events/) 🟢 (the bottom-nav events tab, not a Settings row)
- [specs/settings/about/](settings/about/) 🟢

**Coverage**: 28 / 28 features migrated to per-feature trios. 81 trio files written across `specs/`.

## Drift surfaced during migration (action required in features.md)

Flavor tags in [features.md](features.md) disagree with code reality for **four** features. Code is the source of truth; features.md should be patched.

| Feature | features.md | Code reality | Evidence |
|---|---|---|---|
| `add_address` | P | **B** | `settings_screen.dart:96-107` is not gated by `if (context.isParents)` |
| `my_addresses` | P | **B** | same site as above |
| `all_children` | P | **T** | Settings entry guarded by `if (context.isProfessors)` at `settings_screen.dart:134`; endpoint is `teacher/questions/data` |
| `onboard` | B | **P** | teachers skip onboarding upstream |

## Stub / unwired features (P0 — production blockers)

These features exist in code and have trios, but cannot ship without backend or wiring fixes:

| Feature | Status | Blocker |
|---|---|---|
| `gallery` | Shipped-but-disabled | Settings entry wrapped in `if(false)` at `settings_screen.dart:144`; repo returns `cataas.com` cat memes after a 1-second `Future.delayed` |
| `gallery_images` | Production-blocking stub | `GalleryRepo.getGalleryImages` returns hardcoded `cataas.com` URLs; real `NetworkClient.handleRequest` block is commented out |
| `settings/about` | Empty surface | `AboutRepo.getAbout()` REST call commented out; contact rows never render |
| `select_attendants` | `Placeholder()` (10 LOC) | Zero implementation, zero callers. Collides with `attendants_selection` — must resolve naming + intent before either ships |
| `attendants_selection` | Scaffold only | UI half exists; multi-select state, confirm CTA, and pop-with-selection are missing |

## P0 bugs / fixes surfaced during migration

Carried as `T-fix-N` items in each feature's `tasks.md`:

| Feature | P0 finding |
|---|---|
| `add_form` | Double `/api/v1/` prefix on `/api/v1/teacher/announcements` endpoint (NetworkClient already prepends base URL) |
| `settings/events` | EventBus subscription leak — `eventBus.on().listen(...)` inside `Builder.builder` re-subscribes on every rebuild ([event_screen.dart:55-62](../lib/features/settings/events/event_screen.dart#L55-L62)) |
| `add_address` | Duplicate `"city"` JSON key — `region_id` silently overwrites Brazil's `city` text in the same request body |
| `my_addresses` | Delete is dead-wired — button commented out, dialog confirm leads to `//todo`, no backend endpoint |
| `settings/medicines` | `rejectRequest(id, reason, attachments)` discards attachments; `reason` sent in `queryParameters` not body |
| `settings/medicines` | First-time parents can't add — `add_medicine` CTA is inside `if (medicines.isNotEmpty)` (empty state has no add affordance) |
| `settings/about` | Contact rows never render (REST call commented out) |
| `gallery` / `gallery_images` | Both backed by `cataas.com` stubs in production code |
| `background_services` | Wake-up is **mount-driven only** — a pending user has no auto-discovery of approval (re-mount = re-poll); `NotificationService.configureNotifications` may leak `onTokenRefresh` subscriptions |
| `search` | `SearchScreen` always hits the *teacher* endpoint even on parents flavor; `ProfessorSearch` event exists but is unwired |

## features.md description drift (other patches)

- `main`: features.md says "Tab shell with `bottom_navy_bar`". Reality: hand-rolled `CustomBottomNavigation`; `bottom_navy_bar` is a dead pubspec dependency.
- `home`: features.md lists "Pull-to-refresh on the home feed" as open. Already shipped at [home_screen.dart:128-132](../lib/features/home/home_screen.dart#L128-L132).
- `featured_events`: features.md lists "Track 'seen' featured events in Hive" as open. Already shipped (`seenFeaturedEvents` Hive key).
- `terms_and_condtions`: features.md implies it's a WebView like `privacy_policy`. Reality: REST + `flutter_html` via `TextHtml`. Separate code path.

## Status legend

- 🔴 **Not migrated** — source-of-truth lives only in [features.md](features.md)
- 🟡 **In progress** — partial trio under `specs/<feature>/`
- 🟢 **Migrated** — full `spec.md` / `plan.md` / `tasks.md` trio under `specs/<feature>/`
- 💡 **Proposed** — not yet implemented; use `/speckit.specify`, not migrate

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

## Migration history

| Date | Wave | Features | Highlights |
|---|---|---|---|
| 2026-05-14 | 1 | `login`, `otp`, `splash`, `register`, `notifications` | Proved template format on small features |
| 2026-05-14 | 2 | `chat`, `diary` | Surfaced duplicate `_asMap` compile bug in chat; hardcoded `childId: 1`, O(n² log n) sort in diary |
| 2026-05-15 | 3 (final) | All 21 remaining features | 81 trio files written; surfaced 4 flavor-tag drifts, 5 stub/unwired surfaces, 10 P0 bugs (see tables above) |

## Cross-feature work (still tracked in features.md)

The "Cross-feature tasks" section at the bottom of [features.md](features.md#cross-feature-tasks) — CI, testing baseline, lint rules, package upgrades, license/readme, i18n key sync, analytics — is **not** a per-feature migration target. Surface those items into a project-level plan when ready; they don't belong in any one `specs/<feature>/`. Items addressed during the 2026-05-14 remediation are ticked in features.md.

## Stale claims in existing `specs/` (resolved)

- ✅ 2026-05-14: [specs/system.md §1](system.md#1-stack-snapshot) reconciled to `Flutter 3.29.3` + `.fvmrc`.
- ✅ 2026-05-14: [CLAUDE.md §2.1 Stack](../CLAUDE.md) and §2.5 build/run note reconciled to `Flutter 3.29.3` + `.fvmrc`.
- ✅ 2026-05-15: [specs/business.md](business.md) and [specs/system.md](system.md) rewritten from migrated trios.

Constitution v1.2.0, [system.md](system.md), [business.md](business.md), and [CLAUDE.md](../CLAUDE.md) agree.

## Next steps

1. **Patch [features.md](features.md)** to fix the four flavor-tag drifts and four description-drift items listed above. Code is the source of truth.
2. **Resolve the `select_attendants` / `attendants_selection` naming collision** — pick one folder, delete the other, decide whether the picker is for children or for guardians. Blocks any feature that uses an attendant picker (events, RSVPs, QR-pickup).
3. **Wire the four stub surfaces** (`gallery` repo, `gallery_images` repo, `settings/about` REST call, `select_attendants`/`attendants_selection` implementation) — each has a tracked `T-fix-N` task in its trio.
4. **Run the P0 fixes** from the table above as a single follow-up branch: `add_form` double-prefix, `settings/events` rebuild leak, `add_address` duplicate `city` key, `my_addresses` dead delete, `settings/medicines` reject-attachments drop + empty-state CTA, `background_services` mount-only wake-up, `search` flavor-incorrect endpoint.
5. **Use `/speckit.specify`** (not `/speckit.brownfield.migrate`) for any new feature from the proposed-features table.
