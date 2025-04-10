import 'package:dotted_border/dotted_border.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/theme/custom_theme.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/comments_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentsWidget extends StatefulWidget {
  const CommentsWidget({Key? key, required this.model}) : super(key: key);

  final CommentsModel model;

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  late final TextEditingController commentController;
  late final ValueNotifier<bool> addCommentController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    addCommentController = ValueNotifier(false);

    commentController.addListener(() {
      final text = commentController.text;
      final enabled = addCommentController.value;
      if (enabled) {
        AddFormBloc.get(context).updateForm(widget.model, text);
      }
    });

    addCommentController.addListener(() {
      final text = commentController.text;
      final enabled = addCommentController.value;
      if (enabled) {
        AddFormBloc.get(context).updateForm(widget.model, text);
      } else {
        commentController.clear();
        AddFormBloc.get(context).updateForm(widget.model, null);
      }
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    addCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = commentController.text;
        final formData = validateString(getData(state, widget.model));
        if (validString(formData) && data != formData) {
          commentController.text = formData;
          if (!addCommentController.value) {
            addCommentController.value = true;
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  validateString(widget.model.label?.tr(context), LocalizationKeys.comments.tr(context)),
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: MyTheme.of(context).colors.textColor,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  addCommentController.value = !addCommentController.value;
                },
                child: ValueListenableBuilder(
                  valueListenable: addCommentController,
                  builder: (context, enabled, child) => Container(
                    decoration: BoxDecoration(
                      color: enabled ? null : context.colors.primary,
                      borderRadius: BorderRadius.circular(5.r),
                      border: enabled ? Border.all(color: context.colors.disabled) : null,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.csw,
                      vertical: 8.csh,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20.csw,
                          height: 20.csw,
                          decoration: BoxDecoration(
                            color: enabled ? context.colors.error : context.colors.secondary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            enabled ? Icons.remove : Icons.add,
                            color: MyTheme.of(context).colors.secondaryTextColor,
                            size: 12.sp,
                          ),
                        ),
                        SizedBox(width: 8.csw),
                        Text(
                          enabled ? LocalizationKeys.remove_note.tr(context) : LocalizationKeys.add_note.tr(context),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: enabled ? context.colors.textColor : context.colors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: addCommentController,
            builder: (context, value, child) => value
                ? Padding(
                    padding: EdgeInsets.only(top: 10.csh),
                    child: DottedBorder(
                      color: context.colors.disabled,
                      strokeWidth: 1,
                      dashPattern: const [10, 10],
                      radius: Radius.circular(5.r),
                      borderType: BorderType.RRect,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.csw),
                        child: TextFormField(
                          controller: commentController,
                          maxLines: 5,
                          onTapOutside: (event) => FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: LocalizationKeys.write_comment.tr(context),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (validString(commentController.text)) {
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
}
