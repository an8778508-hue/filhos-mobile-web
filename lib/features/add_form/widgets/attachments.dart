import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:escola/core/attachment_selection/attachment_selection.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/attachments_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_row/separated_row.dart';

class AttachmentsWidget extends StatefulWidget {
  const AttachmentsWidget({Key? key, required this.model}) : super(key: key);

  final AttachmentsModel model;

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  late final ValueNotifier<List<File>> filesController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    filesController = ValueNotifier([]);
    filesController.addListener(() {
      AddFormBloc.get(context)
          .updateForm(widget.model, filesController.value.map((file) => UploadFileParam(url: file.path)).toList());
    });
  }

  @override
  void dispose() {
    filesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: filesController.value.isNotEmpty ? null : () => pickFile(),
          child: DottedBorder(
            color: context.colors.disabled,
            strokeWidth: 1,
            dashPattern: const [10, 10],
            radius: Radius.circular(0.r),
            borderType: BorderType.RRect,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0.r),
                color: context.colors.background,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.csw,
                vertical: 18.csh,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.icons.clipboard.svg(
                          color: context.colors.primary,
                          width: 16.sp,
                          height: 16.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          validateString(widget.model.label?.tr(context), LocalizationKeys.attachments.tr(context)),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                            color: context.colors.greyDark,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: filesController,
          builder: (context, value, child) => !validList(filesController.value)
              ? const SizedBox()
              : Padding(
                  padding: EdgeInsets.only(top: 25.h),
                  child: SizedBox(
                    child: Wrap(
                      children: [
                        ...List.generate(
                          filesController.value.length,
                          (index) => GestureDetector(
                            onTap: () => removeFile(index),
                            child: Container(
                                margin: EdgeInsetsDirectional.only(end: 10.csw, bottom: 10.csh),
                                height: 70.h,
                                child: FileItem(file: filesController.value[index])),
                          ),
                        ),
                        if (widget.model.limit == null
                            ? true
                            : (filesController.value.length < widget.model.limit!)) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              pickFile();
                            },
                            child: SizedBox(height: 70.h, child: const NewFileItem()),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
        ),
        if (widget.model.required)
          FormField(
            validator: (value) {
              if (validList(filesController.value)) {
                return null;
              }
              return LocalizationKeys.this_field_cant_be_empty.tr(context);
            },
            builder: (field) => field.hasError && validString(field.errorText)
                ? Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: ErrorField(
                      text: field.errorText!,
                    ),
                  )
                : const SizedBox(),
          ),
      ],
    );
  }

  pickFile() async {
    setState(() => isLoading = true);
    try {
      final files = await pickImagesAndVideos(context);
      setState(() => isLoading = false);

      if (validList(files)) {
        filesController.value = [
          ...filesController.value,
          ...files.map((e) => File(e)).toList(),
        ];
      }
    } catch (e) {
      setState(() => isLoading = false);
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

class FileItem extends StatelessWidget {
  const FileItem({
    super.key,
    required this.file,
  });

  final File file;

  @override
  Widget build(BuildContext context) {
    final ext = file.path.split('.').last;
    final image = isImage(ext);
    return Padding(
      padding: EdgeInsets.only(top: 5.0.h),
      child: AspectRatio(
        aspectRatio: 1,
        child: DottedBorder(
          color: context.colors.disabled,
          borderType: BorderType.RRect,
          radius: Radius.circular(10.r),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      file,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_copy_outlined,
                        color: context.colors.primary,
                        size: 24.sp,
                      ),
                      Text(
                        ext,
                        style: TextStyle(
                          color: context.colors.primaryLight,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Transform.translate(
                    offset: Offset((Directionality.of(context) == TextDirection.rtl ? -1 : 1) * 12.sp, -12.sp),
                    child: Icon(
                      Icons.remove_circle_sharp,
                      color: context.colors.error,
                      size: 24.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewFileItem extends StatelessWidget {
  const NewFileItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5.0.h),
      child: AspectRatio(
        aspectRatio: 1,
        child: DottedBorder(
          color: context.colors.disabled,
          borderType: BorderType.RRect,
          radius: Radius.circular(10.r),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Icon(
                Icons.add,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
