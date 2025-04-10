import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/rich_text_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import 'package:escola/core/localization/localization_keys.dart';

import 'package:escola/features/add_form/bloc/add_form_state.dart';

class RichTextFieldWidget extends StatefulWidget {
  const RichTextFieldWidget({Key? key, required this.model}) : super(key: key);

  final RichTextModel model;

  @override
  State<RichTextFieldWidget> createState() => _RichTextFieldWidgetState();
}

class _RichTextFieldWidgetState extends State<RichTextFieldWidget> {
  late final QuillEditorController textController;
  String rawText = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    textController = QuillEditorController();
    if (validString(initial)) {
      AddFormBloc.get(context).updateForm(widget.model, initial);
    }
    textController.onTextChanged((raw) async {
      final text = await textController.getText();
      rawText = text;
      if (mounted) {
        AddFormBloc.get(context).updateForm(widget.model, text);
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) async {
        final data = await textController.getText();
        final formData = validateString(getData(state, widget.model));
        if (validString(formData) && data != formData) {
          await textController.replaceText(formData);
        }
      },
      child: Column(
        children: [
          FormCard(
            child: Column(
              children: [
                ToolBar(
                  toolBarColor: context.colors.background,
                  activeIconColor: context.colors.primary,
                  padding: EdgeInsets.all(8.w),
                  controller: textController,
                  iconSize: 20.sp,
                ),
                QuillHtmlEditor(
                  text: widget.model.initial,
                  hintText: widget.model.hint?.tr(context),
                  controller: textController,
                  ensureVisible: true,
                  isEnabled: true,
                  minHeight: 200.h,
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textColor,
                  ),
                  hintTextStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.greyLight,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  hintTextPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  hintTextAlign: TextAlign.start,
                  loadingBuilder: (context) => const Center(child: Loading()),
                ),
              ],
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (validString(rawText)) {
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
