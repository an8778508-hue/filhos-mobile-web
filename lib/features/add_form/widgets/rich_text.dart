import 'dart:convert';

import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/rich_text_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RichTextFieldWidget extends StatefulWidget {
  const RichTextFieldWidget({super.key, required this.model});

  final RichTextModel model;

  @override
  State<RichTextFieldWidget> createState() => _RichTextFieldWidgetState();
}

class _RichTextFieldWidgetState extends State<RichTextFieldWidget> {
  late QuillController _controller;
  String rawText = '';
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();

    final initial = widget.model.initial;
    if (validString(initial)) {
      try {
        // Try to load initial content as Delta JSON
        _controller = QuillController(
          document: Document.fromJson(jsonDecode(initial!)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        // If not valid JSON, set as plain text
        final doc = Document();
        doc.insert(0, initial);
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      AddFormBloc.get(context).updateForm(widget.model, initial);
    }

    _controller.addListener(() {
      final plainText = _controller.document.toPlainText();
      final json = jsonEncode(_controller.document.toDelta().toJson());
      rawText = plainText;
      if (mounted) {
        AddFormBloc.get(context).updateForm(widget.model, json);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final formData = validateString(getData(state, widget.model));
        if (validString(formData)) {
          try {
            final newDoc = Document.fromJson(jsonDecode(formData));
            final currentJson = jsonEncode(_controller.document.toDelta().toJson());
            final newJson = jsonEncode(newDoc.toDelta().toJson());

            if (mounted && currentJson != newJson) {
              _controller.document = newDoc;
            }
          } catch (e) {
            // Handle invalid JSON
          }
        }
      },
      child: Column(
        children: [
          FormCard(
            child: Column(
              children: [
                // QuillToolbar.basic(
                //   controller: _controller,
                //   showAlignmentButtons: true,
                //   multiRowsDisplay: false,
                // ),
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: context.colors.background,
                    border: Border.all(color: context.colors.greyLight.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: QuillEditor.basic(
                    controller: _controller,
                    // readOnly: false,
                    // placeholder: widget.model.hint?.tr(context) ?? '',
                    // autoFocus: false,
                    // expands: false,
                    // padding: EdgeInsets.all(8),
                    // scrollable: true,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                  ),
                ),
              ],
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (validString(rawText.trim())) {
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