import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerDialog extends StatefulWidget {
  final List<String> images;
  final int selectedImageIndex;
  const ImageViewerDialog({super.key, required this.images, required this.selectedImageIndex});

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late int currentIndex;
  @override
  void initState() {
    currentIndex = widget.selectedImageIndex;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
          child: PhotoView(
            tightMode: true,
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            heroAttributes: PhotoViewHeroAttributes(tag: widget.images[currentIndex]),
            maxScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            imageProvider: CachedNetworkImageProvider(widget.images[currentIndex]),
          ),
        ),
        ArrowWidget(
          isLeft: false,
          isEnabled: currentIndex < widget.images.length - 1,
          onTap: () {
            if (currentIndex < widget.images.length - 1) {
              setState(() => currentIndex++);
            }
          },
        ),
        ArrowWidget(
          isLeft: true,
          isEnabled: currentIndex > 0,
          onTap: () {
            if (currentIndex > 0) {
              setState(() => currentIndex--);
            }
          },
        ),
      ],
    );
  }
}

class ArrowWidget extends StatelessWidget {
  final bool isLeft, isEnabled;
  final Function onTap;

  const ArrowWidget({super.key, required this.isLeft, required this.onTap, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => onTap(),
        child: Align(
          alignment: isLeft ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 30.w),
            width: 44.w,
            height: 44.w,
            decoration:
                BoxDecoration(color: isEnabled ? Colors.black : Colors.grey.withOpacity(0.8), shape: BoxShape.circle),
            child: Center(
              child: Icon(
                isLeft ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
                size: 30.w,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
