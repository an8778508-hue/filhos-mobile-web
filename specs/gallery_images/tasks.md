---
status: migrated
feature: gallery_images
migrated_from: specs/features.md#gallery_images--p
migrated_date: 2026-05-14
---

# Tasks: Gallery Images

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#gallery_images--p](../features.md#gallery_images--p).

**Tests**: No `test/` directory exists in the repo today — test tasks are listed as `[ ]` aspirational.

## Migration summary

- 3 .dart files: `bloc/gallery_images_bloc.dart`, `bloc/gallery_images_state.dart`, `gallery_images_screen.dart`.
- Sole mount site: [gallery_screen.dart:94](../../lib/features/gallery/gallery_screen.dart#L94).
- DI registration: [core/dependency_injection/di.dart:128](../../lib/core/dependency_injection/di.dart#L128).
- Backing repo (`GalleryRepo.getGalleryImages`): **stub returning `cataas.com` placeholders** — see [gallery_repo.dart:46-67](../../lib/features/gallery/repo/gallery_repo.dart#L46-L67).

## Phase 1: Setup — ✅ Complete

- [x] **T-001**: Create `lib/features/gallery_images/` with `bloc/` directory.
- [x] **T-002**: Register `GalleryImagesBloc` factory in DI.

## Phase 2: User Story 1 — Grid of a child's images (P1) — ✅ Complete

- [x] **T-010**: Implement `GalleryImagesBloc.fetch(id, {reload})` returning filtered URL list via `validString`.
- [x] **T-011**: Render `GridView.builder` (2-col, square aspect, 2px gutter) inside a `RefreshIndicator`.
- [x] **T-012**: Show `LoadingOverlay` during `state.galleryState.loading`.

## Phase 3: User Story 2 — Pinch-zoom single image (P2) — ✅ Complete

- [x] **T-020**: Long-press → push `PhotoViewer(url: gallery[index])` (`photo_view` + blur backdrop + share button).

## Phase 4: User Story 3 — Swipeable MediaGallery (P2) — ✅ Complete

- [x] **T-030**: Tap → push `MediaGallery(media: gallery)` for full-collection horizontal pager.

## Phase 5: Gaps & cleanups

### Constitution drift fixes

- [ ] **T-fix-1** [P1] **UX correctness**: tap should preview, long-press should menu. Today tap opens the multi-image pager and long-press opens the single-image preview — likely reversed. Confirm with design and swap if needed ([gallery_images_screen.dart:46-64](../../lib/features/gallery_images/gallery_images_screen.dart#L46-L64)).

- [ ] **T-fix-2** [P0] **Stub repo**: [GalleryRepo.getGalleryImages](../../lib/features/gallery/repo/gallery_repo.dart#L46-L67) returns hardcoded `cataas.com` URLs. The REST call is commented out — wire it to the real endpoint. **This blocks any production release of the parents' gallery flow.** Coordinate with backend; not implementable from the codebase alone.

- [ ] **T-fix-3** [P1] **Carry-over from [features.md `gallery_images` (P)](../features.md#gallery_images--p)**: "Add 'save to device' via `image_gallery_saver`." Add a save IconButton to `PhotoViewer` (and probably `MediaGallery`) that calls `image_gallery_saver`. ⚠️ `image_gallery_saver` is flagged as **abandoned** in the [cross-feature task](../features.md#cross-feature-tasks) "Replace abandoned packages" — pick the replacement (e.g., `gal`) before doing this work.

- [ ] **T-fix-4** [P1] **Carry-over from [features.md `gallery_images` (P)](../features.md#gallery_images--p)**: "Add share-sheet via `share_plus`." Per-image share already exists in `PhotoViewer`'s `ShareWidget`. Add a top-level share action for the whole collection (`Share.shareFiles(...)` with cached URLs).

- [ ] **T-fix-5** [P2] **Empty-state UI**: when `gallery` is empty after a successful fetch, show a friendly "no photos yet" illustration + copy. Today the screen just renders a 0-item grid.

- [ ] **T-fix-6** [P2] **Reload loading bug**: `fetch(id, reload: true)` triggers `asReloading()` in the state, but the build condition `state.galleryState.loading` is still `true` during reload — the grid is hidden by `LoadingOverlay`. Either build off a separate `reloading` flag, or keep `loading == false` during reload.

- [ ] **T-fix-7** [P3] Extract DI registration into a dedicated `lib/features/gallery_images/gallery_images_di.dart` implementing `DependencyInjection`. Mirror sibling feature DI conventions.

- [ ] **T-fix-8** [P3] **MediaGallery starting index**: `MediaGallery(media: gallery)` does not pass the tapped index. Either modify `MediaGallery` to accept `initialIndex` or pre-position the controller from `gallery_images_screen.dart`.

### Code hygiene

- [ ] **T-cleanup-1** Consider lifting `MediaGallery` from `diary/presentation/widgets/gallery_media/` to `core/components/` to reduce cross-feature dependencies (this would unblock part of the [cross-feature absolute-imports lint task](../features.md#cross-feature-tasks)).

### Tests (aspirational)

- [ ] **T-test-1** [P] Cubit test for `fetch(id)`: success path, filter-empty path, repo failure.
- [ ] **T-test-2** [P] Widget test for tap vs long-press → correct navigation target.
- [ ] **T-test-3** Widget test for pull-to-refresh dispatching `reload: true`.

## Phase 6: Polish & Cross-Cutting

- [ ] **TX01** [X] Run `flutter analyze` after T-fix-* — no new warnings expected.
- [ ] **TX02** [X] On both Android + iOS, verify `image_gallery_saver` (or replacement) returns success when saving to Photos / Gallery.
- [ ] **TX03** [X] Smoke-test on a real device with a populated gallery on staging.

## Dependencies & Execution Order

- **Phase 2–4 are complete in terms of UI shape, but the data layer is stubbed.**
- **Phase 5** order:
  1. T-fix-2 (real REST endpoint) — blocks production.
  2. T-fix-1 (gesture binding clarification) — UX correctness, low risk.
  3. T-fix-3 / T-fix-4 (save + share) — value-add features.
  4. T-fix-5 / T-fix-6 (empty / loading polish).
  5. T-fix-7 / T-fix-8 / T-cleanup-1 (housekeeping).

## Gaps found

- **The repo is a stub.** Until [T-fix-2](#phase-5-gaps--cleanups) is closed, every "fetch images" path renders cat photos. This is the single biggest gap.
- **Save & share follow-ups are real** and feature.md surfaces them — but the upstream dependency choice (`image_gallery_saver` is abandoned) blocks them. Pick a replacement first.
- **`MediaGallery` index is dropped** — tapping any tile always opens the pager at position 0. Minor UX regression.
- **No flavor scoping at the route level.** The screen will technically render in the teacher flavor too, since the only gate is the (parents-only) `gallery` upstream. If a teacher ever gets a deep link to `GalleryImagesScreen`, the stub repo will happily serve cat URLs — not a leak today, but worth pinning the feature scope explicitly.
