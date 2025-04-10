import 'package:bloc/bloc.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/gallery/bloc/gallery_state.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';

class GalleryBloc extends Cubit<GalleryState> {
  GalleryBloc(this.galleryRepo) : super(const GalleryState());

  final GalleryRepo galleryRepo;

  fetch({bool reload = false}) async {
    emit(state.updateGalleryState((s) => reload ? s.asReloading() : s.asLoading()));
    final f = await galleryRepo.getGallery();
    f.fold(
      (l) => emit(state.updateGalleryState((s) => s.asFailed(l))),
      (r) => emit(state.updateGalleryState(
          (s) => s.asSuccessfullyLoaded(r.where((g) => g.childModel != null && validList(g.images)).toList()))),
    );
  }
}
