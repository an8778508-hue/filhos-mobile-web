import 'package:bloc/bloc.dart';
import 'package:escola/features/gallery/bloc/child_gallery_state.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';

/// Drives a single child's dedicated photo album: initial load, pull-to-refresh
/// (reload) and infinite-scroll pagination (loadMore).
class ChildGalleryBloc extends Cubit<ChildGalleryState> {
  ChildGalleryBloc(
    this.galleryRepo, {
    required this.childId,
    this.asTeacher = false,
    this.perPage = GalleryRepo.defaultPerPage,
  }) : super(const ChildGalleryState());

  final GalleryRepo galleryRepo;
  final int childId;
  final bool asTeacher;
  final int perPage;

  /// Initial load or pull-to-refresh (reload).
  Future<void> fetch({bool reload = false}) async {
    emit(state.updateGalleryState((s) => reload ? s.asReloading() : s.asLoading()));

    final result = await galleryRepo.getChildGallery(
      childId,
      page: 1,
      perPage: perPage,
      asTeacher: asTeacher,
    );

    result.fold(
      (failure) => emit(state.updateGalleryState((s) => s.asFailed(failure))),
      (list) => emit(state.updateGalleryState((s) => s.asSuccessfullyLoaded(list))),
    );
  }

  /// Fetch the next page and append. No-op while already loading or when the
  /// last page has been reached.
  Future<void> loadMore() async {
    final current = state.galleryState;
    if (current.loadingMore || current.loading || current.reloading || current.noMore) {
      return;
    }

    emit(state.updateGalleryState((s) => s.asLoadingMore()));

    final result = await galleryRepo.getChildGallery(
      childId,
      page: current.currentPage + 1,
      perPage: perPage,
      asTeacher: asTeacher,
    );

    result.fold(
      (failure) => emit(state.updateGalleryState((s) => s.asFailed(failure))),
      (list) => emit(state.updateGalleryState((s) => s.asSuccessfullyLoadedMore(list))),
    );
  }
}
