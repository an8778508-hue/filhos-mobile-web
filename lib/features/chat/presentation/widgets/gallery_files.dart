import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/widgets/file_extension.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/images_message_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:escola/features/chat/presentation/widgets/camera_icon.dart';
import 'package:escola/features/chat/presentation/widgets/gallery_icon.dart';
import 'package:escola/features/chat/presentation/widgets/send_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GalleryFiles extends StatelessWidget {
  const GalleryFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final images = context.watch<ImagesMessageBloc>().imagesInTheField;

    if (images.isNotEmpty) {
      return Container(
        width: double.infinity,
        color: ChatColors.backgroundTextField,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    images.length,
                    (index) {
                      final ext = images[index].path.split('.').last;
                      final fileIsImage = isImage(ext);
                      return Stack(
                        children: [
                          if (fileIsImage) ...[
                            Container(
                              width: 100.w,
                              margin: EdgeInsets.all(10.w),
                              child: CommonImage(
                                fit: BoxFit.cover,
                                isFile: true,
                                imageUrl: images[index].path,
                              ),
                            )
                          ] else ...[
                            Container(
                                margin: EdgeInsets.all(10.w),
                                color: Colors.white,
                                width: 100.w,
                                child: Center(child: FileExtension(ext: ext)))
                          ],
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<ImagesMessageBloc>().add(DeleteImage(index: index));
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20.w,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [GalleryIcon(), SizedBox(width: 5), CameraIcon()],
                  ),
                  SendButton(
                    onPressed: () => context.read<ImagesMessageBloc>().add(SendImagesMessage()),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
