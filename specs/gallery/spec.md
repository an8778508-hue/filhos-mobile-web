---
status: migrated
feature: gallery
flavor_scope: parents
migrated_from: specs/features.md#gallery--p
migrated_date: 2026-05-14
---

# Feature Specification: Gallery

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/gallery/](../../lib/features/gallery/) and the existing [features.md `## gallery · P`](../features.md#gallery--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: parents (per features.md `· P`).
- **Flavor-conditional behavior**: None inside the feature. The entry-point gates on `if (context.isParents)` in settings ([settings_screen.dart:144-157](../../lib/features/settings/settings_screen.dart#L144-L157)).
- **🚨 The entry point is currently disabled**: `if(false) if (context.isParents) SettingsItem(...)` — line 144 wraps the whole settings tile in `if(false)`. **The gallery screen is unreachable from production navigation today.** Either dead UI or intentionally hidden until backend support is ready.
- **Server role implication**: None — when re-enabled, the endpoint is a parent-side `gallery` (path stubbed; see Edge Cases).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Parent browses per-child photo collections (Priority: P1) 🎯 MVP

A parent opens "Gallery" from settings; the screen shows one section per enrolled child with a horizontal photo strip and a "See more" button that opens [gallery_images](../../lib/features/gallery_images/) full-screen for that child.

**Why this priority**: This is the only purpose of the screen.

**Independent Test**:
1. Re-enable the entry point in `settings_screen.dart` (today gated behind `if(false)`).
2. Tap "Gallery" in settings on the parents flavor.
3. Verify `GalleryBloc.fetch()` is called ([gallery_screen.dart:23](../../lib/features/gallery/gallery_screen.dart#L23)).
4. Verify the response is filtered to entries with `childModel != null && validList(images)` ([gallery_bloc.dart:17](../../lib/features/gallery/bloc/gallery_bloc.dart#L17)).
5. Each surviving entry renders a header (avatar + name + age + "See more") and a horizontal strip of thumbnails.
6. Tapping a thumbnail opens `PhotoViewer(url, tag)`.
7. Tapping "See more" pushes `GalleryImagesScreen(child: item.childModel!)`.

**Acceptance Scenarios**:

1. **Given** the user opens the screen, **When** `GalleryBloc.fetch()` runs, **Then** `galleryState.loading == true` → `LoadingOverlay` is centered.
2. **Given** the response succeeds with N children, **When** the state lands, **Then** N sections render in a `ListView.separated` with 40h spacing.
3. **Given** the response succeeds, **When** any entry has `childModel == null` or `images` is empty, **Then** that entry is filtered out before render.
4. **Given** the user pulls down, **When** `RefreshIndicator.onRefresh` fires, **Then** `GalleryBloc.fetch(reload: true)` is dispatched — `s.asReloading()` (preserves data while refreshing).
5. **Given** the user taps a thumbnail, **When** `Navigator.push(PhotoViewer(url, tag))` runs, **Then** `tag` matches the URL (Hero-style transition keyed on the image URL).
6. **Given** the response fails, **When** `s.asFailed(failure)` is emitted, **Then** the screen **currently does nothing** — there is no error branch in the builder. **Gap.**

---

### User Story 2 - "See more" → full-screen images (Priority: P2)

Tap "See more" on a child header opens `GalleryImagesScreen(child: ChildModel)`.

**Why this priority**: The full-screen viewer is its own feature (`gallery_images`). This spec covers only the navigation handoff.

**Acceptance Scenarios**:

1. **Given** any child section is shown, **When** "See more" is tapped, **Then** `Navigator.of(context).push(MaterialPageRoute(builder: (_) => GalleryImagesScreen(child: item.childModel!)))` ([gallery_screen.dart:92-95](../../lib/features/gallery/gallery_screen.dart#L92-L95)).

---

### Edge Cases

- **Backend not wired**: the repo currently returns **stubbed data** (`https://cataas.com/cat/says/...` cat-meme URLs) after a 1-second artificial delay ([gallery_repo.dart:13-31](../../lib/features/gallery/repo/gallery_repo.dart#L13-L31)). The real `handleRequest` block is commented out. **The entire feature is on placeholder data.**
- **Stubbed endpoint path**: in the commented-out block the URL is `'gallery'` ([gallery_repo.dart:35](../../lib/features/gallery/repo/gallery_repo.dart#L35)) — relative to the `criarte.filhos.app/api/v1/` base. Verify this is the agreed path before re-enabling.
- **No error UI**: `GalleryState` carries an error via `GenericListState`, but the builder only branches on `loading`. A failed fetch shows a blank list.
- **No empty-state UI**: if the filtered list is empty, the screen renders nothing but the `ListView` shell.
- **Stub thumbnail height ≠ cell width**: `SizedBox(height: 150.h)` for the row, `CommonImage(width: 150.h, height: 150.h)` for tiles. Mixing `.h` for width is a `flutter_screenutil` smell — should be `.w` or a unified responsive metric.
- **`getGalleryImages(String id)`** in the repo ([gallery_repo.dart:46-67](../../lib/features/gallery/repo/gallery_repo.dart#L46-L67)) is also stubbed and is consumed by the sibling `gallery_images` feature.
- **`cached_network_image`**: features.md asks "Confirm thumbnails use cached_network_image with a placeholder." Today the renderer is `CommonImage` from [core/components/icons/common_image.dart](../../lib/core/components/icons/common_image.dart). Confirm that wrapper uses `cached_network_image` under the hood.
- **No date grouping**: features.md asks for it; not implemented. The current model has no date field.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the gallery list via `GalleryRepo.getGallery()` and store it in `GenericListState<GalleryListModel>`.
- **FR-002**: System MUST filter out entries with `childModel == null` or `validList(images) == false` ([gallery_bloc.dart:17](../../lib/features/gallery/bloc/gallery_bloc.dart#L17)).
- **FR-003**: System MUST render one section per remaining entry with avatar + name + age header, a "See more" CTA, and a horizontally-scrolling thumbnail strip.
- **FR-004**: System MUST open `PhotoViewer(url, tag)` on thumbnail tap and `GalleryImagesScreen(child)` on "See more" tap.
- **FR-005**: System MUST support pull-to-refresh, preserving existing data (`asReloading`) instead of clearing to a blank loading state.
- **FR-006** (gap from features.md): System MUST confirm thumbnails use `cached_network_image` with a placeholder. Inspect [core/components/icons/common_image.dart](../../lib/core/components/icons/common_image.dart) — update or replace.
- **FR-007** (gap from features.md): System SHOULD group entries by date so the same child's images are not collapsed into one strip. Requires a `date` field on `GalleryListModel`.
- **FR-008** (gap): System MUST surface failures to the user (today silent).
- **FR-009** (gap): System MUST wire the real REST call — currently stubbed to `cataas.com` cat memes.
- **FR-010** (gap): The settings entry point must be re-enabled (`if(false)` wrapper removed) once FR-009 is done.

### Localization Requirements

| Key | Use site |
|---|---|
| `gallery` | App bar title |
| `see_more` | Per-section CTA |

No new keys required.

### Backend Touchpoints

- **REST endpoint** (stubbed today, base `https://criarte.filhos.app/api/v1/`):
  - `GET gallery` — list per-child photo collections. Real path TBD; the commented-out block uses the literal string `'gallery'`. **Confirm before wiring.**
- **Headers**: standard via `NetworkInterceptor`.
- **Firebase / Firestore**: not used.

### Permissions & Approval Gate

- Reachable from settings post-login on the parents flavor; approval gate enforced upstream.
- No device permissions for viewing (saving images to device is a `gallery_images` concern — out of scope here, but features.md tasks it under that feature).

### Key Entities

- **`GalleryListModel`** ([gallery_list_model.dart](../../lib/features/gallery/model/gallery_list_model.dart)) — `{childModel: ChildModel?, images: List<String>}`. `fromJson` reads `json['child']` and `json['images']`.
- **`ChildModel`** (shared from [features/diary/models/child_model.dart](../../lib/features/diary/models/child_model.dart)) — sub-model on each gallery entry.
- **`GalleryState`** — single-slot wrapper around `GenericListState<GalleryListModel>` ([gallery_state.dart](../../lib/features/gallery/bloc/gallery_state.dart)).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent with N enrolled children sees N (or fewer, after filtering) sections within 2 s of opening the screen on a warm network.
- **SC-002**: Tapping a thumbnail opens `PhotoViewer` with a Hero animation keyed on the URL.
- **SC-003**: Pull-to-refresh updates the list without flashing a blank loading state.
- **SC-004**: With FR-009 implemented, the repo hits the real backend, not `cataas.com`.

## Assumptions

- The agreed backend path for the gallery list is `GET gallery` (or another path TBD).
- `ChildModel` from the gallery response is a structural subset of the diary's `ChildModel` so that the same parsing logic works.
- `gallery_images` (sibling feature) is the right destination for "See more" and exposes `GalleryImagesScreen(child:)`.
- `CommonImage` already uses `cached_network_image` under the hood; otherwise FR-006 expands to a wrapper rewrite.
- The product team is comfortable shipping this feature behind the current `if(false)` gate until FR-009 is done.
