---
status: migrated
feature: gallery_images
migrated_from: lib/features/gallery_images/
migrated_date: 2026-05-14
---

# Implementation Plan: Gallery Images

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/gallery_images/spec.md](spec.md) and code in [lib/features/gallery_images/](../../lib/features/gallery_images/).

## Summary

A small leaf screen reached from the parents' `gallery` list: shows a per-child 2-column image grid. Tapping opens the swipeable `MediaGallery` (from diary); long-pressing opens `PhotoViewer` for pinch-zoom + share. The backing repo is currently a `cataas.com` stub — the REST call is commented out.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `GalleryImagesBloc` is a `Cubit<GalleryImagesState>`.
- `get_it` — registered in [lib/core/dependency_injection/di.dart:128](../../lib/core/dependency_injection/di.dart#L128). No per-feature `gallery_images_di.dart` exists; registration is co-located with `GalleryRepo`/`GalleryBloc`.
- `photo_view` 0.15 — `PhotoViewer` core component.
- `flutter_screenutil` — `.h/.w/.r` sizing.
- `cached_network_image` (via `CommonImage`).

**Storage**: none.

**Testing**: none today.

**Target Platform**: iOS + Android, parents flavor.

**Project Type**: Flutter mobile feature; layout has `bloc/` + screen at the feature root, no `presentation/` wrapper. Matches sibling `featured_events/`.

**Performance Goals**: Grid renders within 1 s; image tiles use `cached_network_image` for disk caching.

**Constraints**:

- Depends on `MediaGallery` from `diary/presentation/widgets/gallery_media/`, which is a known cross-feature import (acceptable per current code).
- The repo is a stub — any timing/sizing claim is contingent on the real endpoint being implemented.

**Scale/Scope**: 3 .dart files + reliance on `core/components/image/photo_viewer.dart` and `diary/.../media_gallery.dart`.

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [x] **I. Feature-First Layout** — `bloc/` + screen at feature root, no `presentation/` wrapper. Matches `featured_events/`; accept as variation. ⚠️ No per-feature `gallery_images_di.dart`; DI lives in `core/dependency_injection/di.dart`.
- [⚠] **II. Dependency Direction** — imports `features/diary/models/child_model.dart` and `features/diary/presentation/widgets/gallery_media/media_gallery.dart`. The `MediaGallery` cross-feature import is the structural concern; either lift `MediaGallery` to `core/components/` or accept the diary dependency. Tracked in [cross-feature import lint task](../features.md#cross-feature-tasks).
- [⚠] **III. Networking Contract** — the bloc *would* go through `NetworkClient.handleRequest` via the repo, but the repo is currently a stub. The signature is correct (`Either<Failure, List<String>>`); the implementation isn't.
- [x] **IV. Persistence Discipline** — no direct Hive use.
- [x] **V. Flavor Branching** — no `mainKey.currentContext` use.
- [x] **VI. Localization** — title via `LocalizationKeys.gallery.tr(context)`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — mounted only behind the gate.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — sizes via `.h/.w/.r`. Default `ClipRRect` and `BorderRadius` are theme-neutral. ✓

## Project Structure

### Documentation (this feature)

```text
specs/gallery_images/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/gallery_images/
├── bloc/
│   ├── gallery_images_bloc.dart            # Cubit<GalleryImagesState>; fetch(id, {reload})
│   └── gallery_images_state.dart           # GenericListState<String>
└── gallery_images_screen.dart              # GridView + RefreshIndicator + nav to PhotoViewer / MediaGallery
```

### Cross-feature touch points

- [lib/features/gallery/gallery_screen.dart](../../lib/features/gallery/gallery_screen.dart) — sole mount site ("See more" CTA).
- [lib/features/gallery/repo/gallery_repo.dart](../../lib/features/gallery/repo/gallery_repo.dart) — `getGalleryImages(id)` (currently stub).
- [lib/features/diary/presentation/widgets/gallery_media/media_gallery.dart](../../lib/features/diary/presentation/widgets/gallery_media/media_gallery.dart) — swipeable pager.
- [lib/core/components/image/photo_viewer.dart](../../lib/core/components/image/photo_viewer.dart) — full-screen `photo_view`.
- [lib/features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart) — `ChildModel` constructor parameter.

**Structure Decision**: Keep current layout. Extract `gallery_images_di.dart` (cleanup). Address the stub repo as a coordinated task with the [gallery feature](../features.md#gallery--p).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| Repo stub returns hardcoded `cataas.com` URLs | The endpoint isn't built server-side yet; preserved as a visual placeholder during UI development. | None — must be wired to real REST before launch. |
| Tap → `MediaGallery`, long-press → `PhotoViewer` (potentially reversed UX) | Implemented as-is; design hasn't validated. | Swap the bindings; trivial change. See [tasks.md T-fix-1](tasks.md). |
| `MediaGallery` is in `diary/` not `core/` | Originally written for diary's gallery sub-feature. | Lift to `core/components/`; mechanical but touches multiple imports. |
| No `gallery_images_di.dart` at feature root | DI co-registered with `GalleryRepo`/`GalleryBloc` in `core/dependency_injection/di.dart`. | Extract; mechanical. |
