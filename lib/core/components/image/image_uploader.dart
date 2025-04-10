import 'package:escola/core/attachment_selection/attachment_selection.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/widgets/upload_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImagesField extends StatefulWidget {
  final String title;
  final Function(List<String>) onChange;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  const ImagesField({super.key, required this.title, required this.onChange, this.backgroundColor, this.titleStyle});

  @override
  State<ImagesField> createState() => _ImagesFieldState();
}

class _ImagesFieldState extends State<ImagesField> {
  final ValueNotifier<List<String>> filesController = ValueNotifier([]);
  @override
  initState() {
    super.initState();
    filesController.addListener(() {
      widget.onChange(filesController.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: filesController.value.isNotEmpty ? null : () => pickFile(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(0.r),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 18.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: widget.titleStyle ??
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: context.colors.primaryLight,
                        ),
                  ),
                ),
                Icon(
                  Icons.image_sharp,
                  color: context.colors.primary,
                  size: 30.sp,
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: filesController,
          builder: (context, value, child) => !validList(filesController.value)
              ? const SizedBox()
              : Padding(
                  padding: EdgeInsets.only(top: 15.h, bottom: 15.h),
                  child: SizedBox(
                    child: Wrap(
                      children: [
                        ...List.generate(
                          filesController.value.length,
                          (index) => GestureDetector(
                            onTap: () => removeFile(index),
                            child: Container(
                                margin: EdgeInsetsDirectional.only(end: 10.w, bottom: 10.h),
                                height: 70.h,
                                child: FileItem(
                                    onRemove: () => removeFile(index),
                                    removeIconSize: 30.w,
                                    param: UploadFileParam(url: filesController.value[index]))),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            pickFile();
                          },
                          child: SizedBox(height: 70.h, child: const NewFileItem()),
                        )
                      ],
                    ),
                  ),
                ),
        ),
        SizedBox(height: 1.h),
      ],
    );
  }

  pickFile() async {
    final files = await pickImagesAndVideos(context);
    if (validList(files)) {
      filesController.value = [
        ...filesController.value,
        ...files,
      ];
    }
  }

  removeFile(int index) async {
    final files = [...filesController.value];
    if (files.length > index) {
      files.removeAt(index);
      filesController.value = files;
    }
  }
}
