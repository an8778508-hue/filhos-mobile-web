import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/gallery/model/gallery_list_model.dart';

class GalleryState {
  final GenericListState<GalleryListModel> galleryState;

  const GalleryState({
    this.galleryState = const GenericListState<GalleryListModel>(),
  });

  GalleryState copyWith({
    GenericListState<GalleryListModel>? galleryState,
  }) =>
      GalleryState(
        galleryState: galleryState ?? this.galleryState,
      );

  GalleryState updateGalleryState(
          GenericListState<GalleryListModel> Function(GenericListState<GalleryListModel> s) update) =>
      copyWith(galleryState: update(galleryState));
}
