import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/media_gallery_item.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/image_viewer_dialog.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/select_all_images.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/share_button.dart';
import 'package:flutter/material.dart';

class MediaGallery extends StatefulWidget {
  final List<String> media;
  const MediaGallery({super.key, required this.media});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  List<int> selectedImagesIndex = [];

  bool emptyImages() => selectedImagesIndex.isEmpty;

  bool allSelected() => selectedImagesIndex.length == widget.media.length;

  List<String> getSelectedImages() {
    List<String> selectedImages = [];
    for (var i = 0; i < selectedImagesIndex.length; i++) {
      final image = widget.media[selectedImagesIndex[i]];
      selectedImages.add(image);
    }
    return selectedImages;
  }

  @override
  void initState() {
    // setState(() => selectedImagesIndex = List.generate(widget.media.length, (index) => index));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondaryScaffold,
      body: Column(
        children: [
          MyAppBar(
            title: LocalizationKeys.multimedia.tr(context),
            hasNotification: false,
            actionWidget: ShareWidget(
              media: getSelectedImages(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SelectAllImages(
                    allSelected: allSelected(),
                    onTap: selectAllFunction,
                  ),
                  Column(
                    children: List.generate(
                      widget.media.length,
                      (index) {
                        final media = widget.media[index];
                        final bool selected = selectedImagesIndex.contains(index);

                        return GestureDetector(
                          onTap: () {
                            final ext = media.split('.').last;
                            final fileIsImage = isImage(ext);
                            if (fileIsImage) {
                              showDialog(
                                  context: context,
                                  barrierColor: Colors.black87.withOpacity(0.7),
                                  builder: (context) => ImageViewerDialog(
                                        images: widget.media,
                                        selectedImageIndex: index,
                                      ));
                            }
                            // onImageTap(selected, index);
                          },
                          child: MediaGalleryItem(
                            media: media,
                            isSelected: selected,
                            onSelected: () {
                              onImageTap(selected, index);
                            },
                            onZoomed: () {
                              showDialog(
                                  context: context,
                                  barrierColor: Colors.black87.withOpacity(0.7),
                                  builder: (context) => ImageViewerDialog(
                                        images: widget.media,
                                        selectedImageIndex: index,
                                      ));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onImageTap(bool selected, int index) {
    if (selected) {
      selectedImagesIndex.remove(index);
    } else {
      selectedImagesIndex.add(index);
    }
    setState(() {});
  }

  void selectAllFunction() {
    if (allSelected()) {
      selectedImagesIndex.clear();
    } else {
      selectedImagesIndex = (List.generate(widget.media.length, (index) => index));
    }
    setState(() {});
  }

  // _saveImage() async {
  //   try {
  //     setState(() => isDownloading = true);

  //     for (var i = 0; i < selectedImagesIndex.length; i++) {
  //       final image = widget.images[selectedImagesIndex[i]];
  //       var response = await Dio()
  //           .get(image, options: Options(responseType: ResponseType.bytes));
  //       final result = await ImageGallerySaver.saveImage(
  //           Uint8List.fromList(response.data),
  //           quality: 60,
  //           name: "$image ${DateTime.now().millisecondsSinceEpoch}");

  //       print(result);
  //     }

  //     setState(() => isDownloading = false);
  //   } catch (e) {
  //     debugPrint("Error: $e");
  //   }
  // }
}
