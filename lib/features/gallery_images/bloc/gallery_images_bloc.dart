import 'package:bloc/bloc.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';

import 'gallery_images_state.dart';

class GalleryImagesBloc extends Cubit<GalleryImagesState> {
  GalleryImagesBloc(this.galleryRepo) : super(const GalleryImagesState());

  final GalleryRepo galleryRepo;

  fetch(String id, {bool reload = false}) async {
    emit(state.updateGalleryImagesState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await galleryRepo.getGalleryImages(id);
    f.fold(
      (l) => emit(state.updateGalleryImagesState((s) => s.asFailed(l))),
      (r) =>
          emit(state.updateGalleryImagesState((s) => s.asSuccessfullyLoaded(r.where((g) => validString(g)).toList()))),
    );
  }
}
