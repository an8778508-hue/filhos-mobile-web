---
status: migrated
feature: gallery
migrated_from: lib/features/gallery/
migrated_date: 2026-05-14
---

# Implementation Plan: Gallery

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/gallery/spec.md](spec.md) and code in [lib/features/gallery/](../../lib/features/gallery/).

## Summary

`gallery` is a parent-facing per-child photo-collection list. **It is currently disabled** at the settings entry point (`if(false)` wrapper) and **uses stubbed data** (cat memes from `cataas.com`) inside the repo. The UI shell, bloc, model, and state are all wired and ready for the real endpoint.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `GalleryBloc extends Cubit<GalleryState>` (Cubit, not Bloc).
- `get_it` — `GalleryRepo` singleton + `GalleryBloc` factory registered in [init_dependencies.dart:126-127](../../lib/init_dependencies.dart#L126-L127). No feature-root DI class.
- `dio` via `NetworkClient.handleRequest` (in the commented-out real branch).
- `cached_network_image` via [core/components/icons/common_image.dart](../../lib/core/components/icons/common_image.dart) (to confirm).
- `flutter_screenutil` for sizing.

**Storage**: None.

**Testing**: None.

**Target Platform**: iOS + Android, parents flavor.

**Project Type**: Read-side list with handoff to a sibling viewer feature.

**Performance Goals**: List render under 2 s on a warm network once the real endpoint is wired.

**Constraints**:

- Today's repo returns mocked data after a 1s delay. Cannot meaningfully exercise the network path without uncommenting the real block and confirming the endpoint.
- Entry-point is gated behind `if(false)` — feature is essentially shelved in production.

**Scale/Scope**: 5 .dart files, ~190 LOC (~70% of it the screen).

## Project Structure

### Documentation (this feature)

```text
specs/gallery/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/gallery/
├── gallery_screen.dart                    # Entry — not under presentation/
├── bloc/
│   ├── gallery_bloc.dart                  # Cubit<GalleryState>
│   └── gallery_state.dart                 # Wraps GenericListState<GalleryListModel>
├── model/
│   └── gallery_list_model.dart            # { childModel, images } + fromJson
└── repo/
    └── gallery_repo.dart                  # STUBBED — returns cat-meme URLs
```

### Cross-feature touch points

- [lib/features/gallery_images/](../../lib/features/gallery_images/) — destination of "See more"; receives `ChildModel`.
- [lib/features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart) — `ChildModel` row sub-type.
- [lib/core/models/generic_state.dart](../../lib/core/models/generic_state.dart) — `GenericListState` helper (`asLoading/asReloading/asSuccessfullyLoaded/asFailed`).
- [lib/core/components/image/photo_viewer.dart](../../lib/core/components/image/photo_viewer.dart) — destination of thumbnail tap.
- [lib/core/components/icons/common_image.dart](../../lib/core/components/icons/common_image.dart) — thumbnail renderer (confirm caching).
- [lib/features/settings/settings_screen.dart:144-157](../../lib/features/settings/settings_screen.dart#L144-L157) — disabled entry point.

## Implementation Phases

- **Phase 1 — Setup**: feature folder + inline DI. ✓
- **Phase 2 — Foundational**: `GalleryListModel` + `GenericListState`-backed `GalleryState`. ✓
- **Phase 3 — User Story 1**: screen + bloc + thumbnail strip + pull-to-refresh. ✓ (with stubbed data)
- **Phase 4 — Real backend wiring**: replace stub, surface failures, confirm cached thumbnails, re-enable settings entry. **Pending — see [tasks.md](tasks.md).**
- **Phase 5 — Date grouping** (features.md): add `date` field and group adjacent entries by it. Pending.

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| `GalleryBloc` as `Cubit`, not `Bloc` | Single async action, no event taxonomy needed. | Good. |
| Filter `childModel == null` or empty `images` in the bloc | Avoid empty placeholder sections. | Reasonable; documented. |
| `asReloading` on pull-to-refresh | Preserves existing UI during refresh. | Good UX. |
| `PhotoViewer` keyed on URL via `tag` | Hero animation. | URL collisions would break the animation; today's stub uses unique URLs. |
| Stubbed repo with `Future.delayed` | Keeps the UI driveable before backend exists. | Must be removed before re-enabling the settings entry. |

## Constitution Check

- [ ] **I. Feature-First Layout** — screen at feature root (not under `presentation/`). ⚠️
- [ ] **II. Dependency Direction** — no feature-root `GalleryInjection` class. ⚠️
- [x] **III. Networking Contract** — *will* use `NetworkClient.handleRequest` once the real block is uncommented. ✓ (today: stubbed)
- [x] **IV. Persistence Discipline** — N/A.
- [x] **V. Flavor Branching** — entry-point gated on `context.isParents` (although wrapped in `if(false)`). ✓
- [x] **VI. Localization** — `LocalizationKeys.gallery` / `see_more` used; no hardcoded strings. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reached from settings, post-login.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.w`/`.h`/`.r`/`.sp` + `context.colors.*`. ⚠️ One smell: `CommonImage(width: 150.h, height: 150.h)` mixes vertical units for both axes.

## Dependencies

- Consumes `core/models/generic_state.dart`, `core/components/image/photo_viewer.dart`, `core/components/icons/common_image.dart`.
- Depends on `diary` for `ChildModel`.
- Hands off to `gallery_images`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Screen at feature root | Earlier convention. | Move to `presentation/`. |
| No feature DI class | Inline registration. | Add `GalleryInjection`. |
| Repo returns stubbed data; real branch commented out | Backend not ready when shelf-built. | Wire the real endpoint and delete the stub. |
| Entry-point behind `if(false)` | Feature shelved until backend exists. | Re-enable once FR-009 is done. |
| No error / empty UI | Stub never fails or empties. | Add both before re-enabling. |
| `CommonImage(width: 150.h, height: 150.h)` mixes height units | Quick copy-paste. | Use `.w` for width. |
| `getGalleryImages` repo method also stubbed | Same shelf state. | Wire alongside FR-009. |
