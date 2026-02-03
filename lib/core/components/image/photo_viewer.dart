import 'dart:ui';

import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/share_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';

class PhotoViewer extends StatelessWidget {
  final String url;
  final String? tag;
  final bool share;

  const PhotoViewer({
    super.key,
    required this.url,
    this.tag,
    this.share = true,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ),
              child: Container(
                constraints: const BoxConstraints.expand(),
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                if (share)
                  Container(
                    margin: EdgeInsetsDirectional.only(end: 10.w),
                    child: ShareWidget(
                      media: [url],
                      titleKey: LocalizationKeys.share,
                    ),
                  ),
              ],
              leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            ),
            backgroundColor: Colors.transparent,
            body: PhotoView(
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              heroAttributes: PhotoViewHeroAttributes(tag: tag ?? url),
              maxScale: PhotoViewComputedScale.covered,
              minScale: PhotoViewComputedScale.contained,
              imageProvider: NetworkImage(url),
            ),
          ),
        ],
      ),
    );
  }
}
