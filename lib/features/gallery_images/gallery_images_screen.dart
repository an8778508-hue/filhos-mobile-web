import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/image_viewer_dialog.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bloc/gallery_images_bloc.dart';
import 'bloc/gallery_images_state.dart';

class GalleryImagesScreen extends StatelessWidget {
  const GalleryImagesScreen({super.key, required this.child});

  final ChildModel child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di<GalleryImagesBloc>()..fetch(child.id.toString()),
      child: Scaffold(
        appBar: MyAppBar(
          title: LocalizationKeys.gallery.tr(context),
        ),
        body: BlocBuilder<GalleryImagesBloc, GalleryImagesState>(
          builder: (context, state) {
            final gallery = state.galleryState.data;
            return state.galleryState.loading
                ? const Center(
                    child: LoadingOverlay(),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      return BlocProvider.of<GalleryImagesBloc>(context).fetch(child.id.toString(), reload: true);
                    },
                    child: GridView.builder(
                      padding: EdgeInsets.all(2.w),
                      itemCount: gallery.length,
                      itemBuilder: (context, index) => ClipRRect(
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(5.r),
                        child: GestureDetector(
                          onLongPress: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PhotoViewer(
                                  url: gallery[index],
                                ),
                              ),
                            );
                          },
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MediaGallery(
                                  media: gallery,
                                ),
                              ),
                            );
                          },
                          child: CommonImage(
                            imageUrl: gallery[index],
                            fit: BoxFit.cover,
                            width: 300.h,
                            height: 300.h,
                          ),
                        ),
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 2.h,
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }
}
