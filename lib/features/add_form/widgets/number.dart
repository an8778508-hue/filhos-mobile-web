import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/number_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/localization/localization_keys.dart';

import '../bloc/add_form_state.dart';

class NumberFormFieldWidget extends StatefulWidget {
  const NumberFormFieldWidget({super.key, required this.model});

  final NumberModel model;

  @override
  State<NumberFormFieldWidget> createState() => _NumberFormFieldWidgetState();
}

class _NumberFormFieldWidgetState extends State<NumberFormFieldWidget> {
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    textController = TextEditingController(text: initial);
    if (validString(initial)) {
      AddFormBloc.get(context).updateForm(widget.model, initial);
    }
    textController.addListener(() {
      final text = textController.text;
      AddFormBloc.get(context).updateForm(widget.model, text);
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
      listener: (context, state) {
        final data = textController.text;
        final formData = validateString(getData(state, widget.model));
        if (validString(formData) && data != formData) {
          textController.text = formData;
        }
      },
      child: Column(
        children: [
          FormCard(
            child: TextFormField(
              controller: textController,
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: context.colors.textColor,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.model.hint?.tr(context),
                hintStyle: TextStyle(
                  color: context.colors.greyDarker,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 22.w,
                  vertical: 18.h,
                ),
              ),
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (validString(textController.text)) {
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
