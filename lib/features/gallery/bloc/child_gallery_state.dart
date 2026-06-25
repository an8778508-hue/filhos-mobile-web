import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/gallery/model/gallery_image_model.dart';

class ChildGalleryState {
  final GenericListState<GalleryImageModel> galleryState;

  const ChildGalleryState({
    this.galleryState = const GenericListState<GalleryImageModel>(),
  });

  List<GalleryImageModel> get data => galleryState.data;

  ChildGalleryState copyWith({
    GenericListState<GalleryImageModel>? galleryState,
  }) =>
      ChildGalleryState(
        galleryState: galleryState ?? this.galleryState,
      );

  ChildGalleryState updateGalleryState(
    GenericListState<GalleryImageModel> Function(GenericListState<GalleryImageModel> s) update,
  ) =>
      copyWith(galleryState: update(galleryState));
}
