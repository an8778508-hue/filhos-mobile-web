import 'package:escola/core/models/generic_state.dart';

class GalleryImagesState {
  final GenericListState<String> galleryState;

  const GalleryImagesState({
    this.galleryState = const GenericListState<String>(),
  });

  GalleryImagesState copyWith({
    GenericListState<String>? galleryState,
  }) =>
      GalleryImagesState(
        galleryState: galleryState ?? this.galleryState,
      );

  GalleryImagesState updateGalleryImagesState(GenericListState<String> Function(GenericListState<String> s) update) =>
      copyWith(galleryState: update(galleryState));
}
