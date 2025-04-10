import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/gallery/bloc/gallery_bloc.dart';
import 'package:escola/features/gallery_images/gallery_images_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bloc/gallery_state.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di<GalleryBloc>()..fetch(),
      child: Scaffold(
        appBar: MyAppBar(
          title: LocalizationKeys.gallery.tr(context),
        ),
        body: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            final gallery = state.galleryState.data;
            return state.galleryState.loading
                ? const Center(
                    child: LoadingOverlay(),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      return BlocProvider.of<GalleryBloc>(context).fetch(reload: true);
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      itemCount: gallery.length,
                      separatorBuilder: (context, index) => SizedBox(height: 40.h),
                      itemBuilder: (context, index) {
                        final item = gallery[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.childModel != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 20.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(width: 10.w),
                                          Avatar(
                                            avatar: item.childModel?.avatar ?? '',
                                            size: 60.r,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.childModel?.name ?? '',
                                                  style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: context.colors.textColor,
                                                  ),
                                                ),
                                                Text(
                                                  item.childModel?.age ?? '',
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w300,
                                                    color: context.colors.textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(width: 10.w),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                            builder: (context) => GalleryImagesScreen(child: item.childModel!)));
                                      },
                                      child: Text(
                                        LocalizationKeys.see_more.tr(context),
                                        style: TextStyle(
                                          color: context.colors.primary,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              height: 150.h,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                scrollDirection: Axis.horizontal,
                                itemCount: item.images.length,
                                separatorBuilder: (context, index) => SizedBox(width: 10.w),
                                itemBuilder: (context, index) => ClipRRect(
                                  clipBehavior: Clip.antiAlias,
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) =>
                                              PhotoViewer(url: item.images[index], tag: item.images[index])));
                                    },
                                    child: CommonImage(
                                      imageUrl: item.images[index],
                                      fit: BoxFit.cover,
                                      width: 150.h,
                                      height: 150.h,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
          },
        ),
      ),
    );
  }
}
