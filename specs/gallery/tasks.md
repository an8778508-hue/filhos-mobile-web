---
status: migrated
feature: gallery
migrated_from: specs/features.md#gallery--p
migrated_date: 2026-05-14
---

# Tasks: Gallery

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#gallery--p](../features.md#gallery--p).

## Migration summary

`gallery` is **shipped UI on stubbed data**. The settings entry point is gated behind `if(false)` so the screen is unreachable in production. The cubit, model, state, and screen are complete; the repo's real REST call is commented out and replaced with a 1-second-delayed `cataas.com` cat-meme fixture.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable.
- **[Story]**: US1 = list, US2 = see-more handoff.

---

## Phase 1: Setup — built (with drift)

- [x] **T-001** Feature folder at [lib/features/gallery/](../../lib/features/gallery/).
- [x] **T-002** `GalleryRepo` singleton + `GalleryBloc` factory registered inline in [init_dependencies.dart:126-127](../../lib/init_dependencies.dart#L126-L127). *(Drift: no feature-root DI class — see T-fix-DI.)*
- [x] **T-003** Localization keys `gallery` and `see_more` present in all three langs.

## Phase 2: Foundational — built

- [x] **T-010** `GalleryListModel` with `fromJson` reading `json['child']` + `json['images']` ([gallery_list_model.dart](../../lib/features/gallery/model/gallery_list_model.dart)).
- [x] **T-011** `GalleryState` wrapping `GenericListState<GalleryListModel>` ([gallery_state.dart](../../lib/features/gallery/bloc/gallery_state.dart)).
- [x] **T-012** `GalleryBloc.fetch({reload})` with `asLoading` / `asReloading` / `asSuccessfullyLoaded` / `asFailed` transitions.

## Phase 3: User Story 1 — List — built (stub data)

- [x] **T-020** [US1] Screen + `LoadingOverlay` while loading.
- [x] **T-021** [US1] Filter to entries with `childModel != null && validList(images)` ([gallery_bloc.dart:17](../../lib/features/gallery/bloc/gallery_bloc.dart#L17)).
- [x] **T-022** [US1] Per-child header (avatar + name + age + "See more") + horizontal `ListView.separated` thumbnail strip.
- [x] **T-023** [US1] Thumbnail tap → `PhotoViewer(url, tag)` with Hero key.
- [x] **T-024** [US1] Pull-to-refresh via `RefreshIndicator.onRefresh` → `fetch(reload: true)`.

## Phase 4: User Story 2 — See-more — built

- [x] **T-030** [US2] "See more" → `Navigator.push(GalleryImagesScreen(child: item.childModel!))`.

---

## Phase 5: Gaps & cleanups (BLOCKING — feature is shelved until done)

### Make it real
- [ ] **T-fix-1** **Wire the real REST call** in [gallery_repo.dart:13-31](../../lib/features/gallery/repo/gallery_repo.dart#L13-L31). Delete the stub `Future.delayed` block. Uncomment / replace the `networkClient.handleRequest` block at [lines 32-44](../../lib/features/gallery/repo/gallery_repo.dart#L32-L44). Confirm the endpoint path (`gallery` is a stub) with the backend team.
- [ ] **T-fix-2** **Wire the real `getGalleryImages(id)`** at [gallery_repo.dart:46-67](../../lib/features/gallery/repo/gallery_repo.dart#L46-L67) — same shape as T-fix-1. Used by sibling [gallery_images](../../lib/features/gallery_images/) feature.
- [ ] **T-fix-3** **Re-enable the settings entry.** Remove the `if(false)` wrapper at [settings_screen.dart:144-157](../../lib/features/settings/settings_screen.dart#L144-L157). Logically belongs to settings, recorded here for traceability.
- [ ] **T-fix-4** **Surface failures.** Add an `else if (state.galleryState.error != null)` branch in the screen builder that renders an `ErrorScreen` with retry. Today a failed fetch is silent.
- [ ] **T-fix-5** **Empty-state UI.** When the filtered list is empty, render an empty-state widget instead of a blank `ListView`.

### From features.md
- [ ] **T-fix-6** *(features.md)* **Date-grouping in the list.** Add a `date` field to `GalleryListModel.fromJson`, sort by date desc, render a sticky date header between sections.
- [ ] **T-fix-7** *(features.md)* **Confirm `cached_network_image` + placeholder** is used by [core/components/icons/common_image.dart](../../lib/core/components/icons/common_image.dart). If not, wrap or replace.

### Constitution drift fixes
- [ ] **T-fix-DI** Create [lib/features/gallery/gallery_di.dart](../../lib/features/gallery/gallery_di.dart) implementing `DependencyInjection`; move the `GalleryRepo` singleton + `GalleryBloc`/`GalleryImagesBloc` factory registrations out of `init_dependencies.dart`.
- [ ] **T-fix-LAYOUT** Move [gallery_screen.dart](../../lib/features/gallery/gallery_screen.dart) into `presentation/`.
- [ ] **T-fix-8** Replace `CommonImage(width: 150.h, height: 150.h)` ([gallery_screen.dart:124-128](../../lib/features/gallery/gallery_screen.dart#L124-L128)) with `width: 150.w, height: 150.h` (or pick a unified responsive metric).

### Tests (aspirational)
- [ ] **T-test-1** [P] [US1] Cubit test: `fetch()` success / failure / empty / filter logic.
- [ ] **T-test-2** [P] [US1] Widget test: thumbnail tap pushes `PhotoViewer` with the correct URL/tag.
- [ ] **T-test-3** [P] [US2] Widget test: "See more" pushes `GalleryImagesScreen(child: ...)`.

---

## Constitution Drift Fixes summary

- No feature-root DI class (T-fix-DI).
- Screen at feature root (T-fix-LAYOUT).
- Stubbed data instead of real `NetworkClient.handleRequest` (T-fix-1/2).
- Entry-point gated behind `if(false)` (T-fix-3).
- No error / empty UI (T-fix-4/5).
- Mixed `.h`-for-width on thumbnails (T-fix-8).

## Gaps Found

1. **Stubbed repo** — entire feature is on `cataas.com` cat memes.
2. **Entry-point disabled** — `if(false)` wrapper in `settings_screen.dart`.
3. **No error UI**, **no empty-state UI** — both states pass silently.
4. **`cached_network_image` use is unverified** — features.md asks to confirm.
5. **No date grouping** — would require a `date` field on the model.
6. **Mixed `.h`-for-width thumbnails** — `flutter_screenutil` smell.
