---
status: migrated
feature: gallery_images
flavor_scope: parents
migrated_from: specs/features.md#gallery_images--p
migrated_date: 2026-05-14
---

# Feature Specification: Gallery Images

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/gallery_images/](../../lib/features/gallery_images/) and the [features.md `## gallery_images · P`](../features.md#gallery_images--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: parents (per features.md tag `· P`). Reached from the parents' `gallery` feature via [gallery_screen.dart:94](../../lib/features/gallery/gallery_screen.dart#L94). No teacher-side mount today.
- **Flavor-conditional behavior**: none in the screen itself. The flavor restriction is upstream in `gallery`.
- **Server role implication**: parents see per-child collections; the endpoint is parents-only — but see Gaps: the backing repo is currently a hardcoded stub.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse per-child photo collection in a grid (Priority: P1) 🎯 MVP

A parent on the gallery list taps **See more** under a child's section. The app pushes `GalleryImagesScreen(child: childModel)`, which fetches that child's image URLs and renders them as a 2-column grid.

**Why this priority**: This is the primary visual record-keeping surface for parents — without it, the gallery list has no leaf navigation.

**Independent Test**:
1. From the gallery list, tap **See more** under any child.
2. Confirm: `GalleryImagesScreen` mounts, `GalleryImagesBloc.fetch(child.id)` runs, a `LoadingOverlay` shows, then a 2-col grid renders with the returned URLs.
3. Pull down to refresh — confirm the bloc dispatches `fetch(id, reload: true)`.

**Acceptance Scenarios**:

1. **Given** a valid child id, **When** the screen mounts, **Then** `BlocProvider` calls `di<GalleryImagesBloc>()..fetch(child.id.toString())` ([gallery_images_screen.dart:24](../../lib/features/gallery_images/gallery_images_screen.dart#L24)).
2. **Given** the loading state is true, **When** the screen builds, **Then** `LoadingOverlay` displays centered.
3. **Given** images load successfully, **When** the bloc emits `asSuccessfullyLoaded(...)`, **Then** the grid renders with `crossAxisCount: 2`, `childAspectRatio: 1`, `crossAxisSpacing: 2.w`, `mainAxisSpacing: 2.h` ([gallery_images_screen.dart:73-78](../../lib/features/gallery_images/gallery_images_screen.dart#L73-L78)).
4. **Given** the bloc returns a list with some invalid URLs, **When** the cubit emits state, **Then** entries failing `validString` are filtered out ([gallery_images_bloc.dart:18](../../lib/features/gallery_images/bloc/gallery_images_bloc.dart#L18)).
5. **Given** the user pulls to refresh, **When** the `RefreshIndicator` resolves, **Then** `fetch(child.id.toString(), reload: true)` is dispatched (uses `asReloading()` rather than `asLoading()`, so the grid stays visible during the refetch — though the active code emits `asLoading()` if `reload == false`).

---

### User Story 2 - Pinch-zoom a single image full-screen (Priority: P2)

A user long-presses any grid item; the app pushes `PhotoViewer` with `photo_view`-backed pinch-zoom + share button.

**Why this priority**: Inspecting a single image is the most common follow-up after browsing.

**Independent Test**:
1. Long-press any grid tile.
2. Confirm: a full-screen `PhotoViewer` opens with `BackdropFilter` blur + `PhotoView` zoomable image + a share IconButton in the app bar.
3. Pinch and verify zoom; pan and verify drag.

**Acceptance Scenarios**:

1. **Given** the user long-presses a tile, **When** the gesture fires, **Then** `PhotoViewer(url: gallery[index])` pushes ([gallery_images_screen.dart:47-55](../../lib/features/gallery_images/gallery_images_screen.dart#L47-L55)).
2. **Given** `PhotoViewer` opens, **When** the user pinches, **Then** the image scales between `PhotoViewComputedScale.contained` and `.covered` ([photo_viewer.dart:78-79](../../lib/core/components/image/photo_viewer.dart#L78-L79)).
3. **Given** the share IconButton is tapped, **When** `ShareWidget` is invoked, **Then** native share-sheet opens via the existing `diary/.../share_button.dart` — *which constructs a bare `Dio()` bypassing interceptors (separate gap, see [features.md diary P1](../features.md#diary--b))*.

---

### User Story 3 - Open the swipeable media gallery from a tile (Priority: P2)

A user **taps** (short-tap, vs long-press) any grid item to launch `MediaGallery` from the diary feature — a swipeable horizontal pager over the full collection.

**Why this priority**: Differentiates "preview one" (long-press → PhotoViewer) from "browse all" (tap → MediaGallery).

> ⚠️ The tap-vs-long-press handler split is unusual UX: most users expect tap → preview, long-press → menu. The current binding may be reversed by accident — confirm with design. See [tasks.md T-fix-1](tasks.md).

**Acceptance Scenarios**:

1. **Given** the user taps a tile, **When** the gesture fires, **Then** `MediaGallery(media: gallery)` pushes ([gallery_images_screen.dart:56-64](../../lib/features/gallery_images/gallery_images_screen.dart#L56-L64)).

---

### Edge Cases

- **Empty result list**: the grid renders with `itemCount: 0`. No empty-state copy / illustration. Gap — see [tasks.md T-fix-3](tasks.md).
- **Bloc loading state after pull-to-refresh**: `fetch(reload: true)` uses `asReloading()` which keeps the existing data while a refresh runs; the build check `state.galleryState.loading` is `true` during this — meaning the grid is replaced by `LoadingOverlay` even on pull-to-refresh. Either (a) check `state.galleryState.reloading` separately, or (b) align the bloc to set `loading == false` during reload. Minor UX bug.
- **All URLs invalid**: the bloc filters them out → empty grid → no error surface.
- **Stub repo**: [GalleryRepo.getGalleryImages](../../lib/features/gallery/repo/gallery_repo.dart#L46-L67) currently returns a hardcoded `cataas.com` list with a 1-second `Future.delayed`. **The REST call is commented out.** Critical gap — see [tasks.md T-fix-2](tasks.md).
- **Save to device** and **Share** of the whole collection are not implemented. Per-image share rides on `PhotoViewer`'s share button. features.md notes both as follow-ups.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch a child's image URL list via `galleryRepo.getGalleryImages(id)` returning `Either<Failure, List<String>>`.
- **FR-002**: System MUST filter the response with `validString` to drop empty / null entries before emitting to UI.
- **FR-003**: System MUST render the filtered list as a 2-column square grid using `GridView.builder` with 2px gutter.
- **FR-004**: System MUST support pull-to-refresh by dispatching `fetch(id, reload: true)`.
- **FR-005**: System MUST navigate long-press → `PhotoViewer(url)` (pinch-zoom + share).
- **FR-006**: System MUST navigate tap → `MediaGallery(media: gallery)` (swipeable pager over the full list).
- **FR-007**: System MUST show `LoadingOverlay` while `state.galleryState.loading == true`.
- **FR-008**: System MUST receive the `ChildModel` parameter (constructor-required) to pass `child.id.toString()` to the repo.

### Localization Requirements

| Key | Use site |
|---|---|
| `gallery` | app-bar title ([gallery_images_screen.dart:27](../../lib/features/gallery_images/gallery_images_screen.dart#L27)) |
| `share` | reused by `PhotoViewer`'s share IconButton |

No new keys required.

### Backend Touchpoints

- **REST** (target shape): `GET gallery/{childId}` returning `{data: [url, ...]}`. **Currently a stub** in [gallery_repo.dart](../../lib/features/gallery/repo/gallery_repo.dart) — the REST call is commented out and a `cataas.com` fixture is returned instead. The endpoint name is not even decided.
- No FCM / Firestore / Storage usage on this surface (Storage uploads happen in the teacher-side `gallery` upload flow which is **not** in this feature).

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? **Yes** — reachable only via `MainScreen` → `Gallery` → `GalleryImagesScreen`, all behind the gate.
- Device permissions:
  - **Photos / Storage**: none today. Required for the planned "Save to device" task ([features.md gallery_images](../features.md#gallery_images--p) → `image_gallery_saver`).
  - **Share**: native share sheet via `share_plus` — no explicit permission needed.

### Key Entities

- **`GalleryImagesBloc`** ([bloc](../../lib/features/gallery_images/bloc/gallery_images_bloc.dart)) — `Cubit<GalleryImagesState>` exposing a single `fetch(id, {reload})` method.
- **`GalleryImagesState`** — wraps a `GenericListState<String>` (URLs).
- **`ChildModel`** (shared from diary feature, [child_model.dart](../../lib/features/diary/models/child_model.dart)) — id, name, avatar.
- **`MediaGallery`** ([widget](../../lib/features/diary/presentation/widgets/gallery_media/media_gallery.dart)) — swipeable pager reused from diary.
- **`PhotoViewer`** ([core component](../../lib/core/components/image/photo_viewer.dart)) — `photo_view`-backed full-screen image + share.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Grid renders within 1 second of the screen mounting on a typical 4G connection (assuming the eventual real endpoint matches this budget).
- **SC-002**: Long-press opens `PhotoViewer` within 200 ms with the correct image preselected.
- **SC-003**: Tap opens `MediaGallery` positioned at the tapped image (today the position is **not** passed — `MediaGallery(media: gallery)` is constructed without an index. See [tasks.md T-fix-4](tasks.md)).
- **SC-004**: Pull-to-refresh re-fetches and re-renders within 2 seconds.

## Assumptions

- The eventual real `getGalleryImages` endpoint will return a `List<String>` of fully-qualified URLs (no need for a base-URL join client-side).
- Image URLs are CDN-hosted and cacheable; `CommonImage` (which wraps `cached_network_image`) handles disk caching.
- The `child.id` is a numeric int rendered to string for transport; if it ever becomes a UUID, the repo signature still works.
- `MediaGallery` is robust against being passed a list of URLs without a starting index (today the pager opens at position 0).
