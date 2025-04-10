import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:escola/core/attachment_selection/attachment_selection.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/models/upload_image_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_row/separated_row.dart';

class UploadImageWidget extends StatefulWidget {
  const UploadImageWidget({Key? key, required this.model}) : super(key: key);

  final UploadImageModel model;

  @override
  State<UploadImageWidget> createState() => _UploadImageWidgetState();
}

class _UploadImageWidgetState extends State<UploadImageWidget> {
  late final ValueNotifier<List<UploadFileParam>> filesController;

  @override
  void initState() {
    super.initState();
    filesController = ValueNotifier((widget.model.initial ?? []));
    AddFormBloc.get(context).updateForm(widget.model, filesController.value.map((file) => file).toList());
    filesController.addListener(() {
      AddFormBloc.get(context).updateForm(widget.model, filesController.value.map((file) => file).toList());
    });
  }

  @override
  void dispose() {
    filesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = filesController.value;
        final formData = validateList(getData(state, widget.model));
        if (validList(formData) && data != formData) {
          filesController.value = List<UploadFileParam>.from(formData);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: filesController.value.isNotEmpty ? null : () => pickFile(),
            behavior: HitTestBehavior.opaque,
            child: DottedBorder(
              color: context.colors.disabled,
              strokeWidth: 1,
              dashPattern: const [10, 10],
              radius: Radius.circular(5.r),
              borderType: BorderType.RRect,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.csw,
                  vertical: 18.csh,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        validateString(
                            widget.model.label?.tr(context), LocalizationKeys.attach_copy_recipe.tr(context)),
                        style: TextStyle(
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
          ),
          if (validString(widget.model.hint))
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                widget.model.hint!.tr(context),
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                  color: context.colors.primaryLight,
                ),
              ),
            ),
          ValueListenableBuilder(
            valueListenable: filesController,
            builder: (context, value, child) => !validList(filesController.value)
                ? const SizedBox()
                : Padding(
                    padding: EdgeInsets.only(top: 15.csh),
                    child: SizedBox(
                      height: 75.csh,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SeparatedRow(
                          separatorBuilder: (context, index) => SizedBox(width: 15.csw),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: filesController.value.length,
                              separatorBuilder: (context, index) => SizedBox(width: 15.csw),
                              itemBuilder: (context, index) => GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => removeFile(index),
                                child: FileItem(param: filesController.value[index]),
                              ),
                            ),
                            if (widget.model.limit == null
                                ? true
                                : (filesController.value.length < widget.model.limit!))
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => pickFile(),
                                child: const NewFileItem(),
                              ),
                          ],
                        ),
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
      ),
    );
  }

  pickFile() async {
    final limit = widget.model.limit;
    if (limit != null && filesController.value.length >= limit) {
      Snack.show(context, LocalizationKeys.cant_upload_more_files.tr(context), false);
      return;
    }
    final files = await pickAttachments(context);
    if (validList(files)) {
      filesController.value = [
        ...filesController.value,
        ...files.map((path) => UploadFileParam(url: path)).toList(),
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

class FileItem extends StatelessWidget {
  final double? removeIconSize;
  final Function? onRemove;

  const FileItem({
    super.key,
    required this.param,
    this.removeIconSize,
    this.onRemove,
  });

  final UploadFileParam param;

  @override
  Widget build(BuildContext context) {
    final url = param.url;
    final ext = url.split('.').last;
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
                    child: url.startsWith('http')
                        ? Image.network(
                            url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(url),
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
                GestureDetector(
                  onTap: () {
                    onRemove?.call();
                  },
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Transform.translate(
                      offset: Offset((Directionality.of(context) == TextDirection.rtl ? -1 : 1) * 8.sp, -8.sp),
                      child: GestureDetector(
                        child: Icon(
                          Icons.remove_circle_sharp,
                          color: context.colors.error,
                          size: removeIconSize ?? 24.sp,
                        ),
                      ),
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
