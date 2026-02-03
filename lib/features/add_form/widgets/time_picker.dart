import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/utils/date_formats.dart';
import 'package:escola/core/utils/date_time_utils.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/time_picker_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/add_form_state.dart';
import 'forms.dart';

class TimePickerWidget extends StatefulWidget {
  const TimePickerWidget({
    super.key,
    required this.model,
  });

  final TimePickerModel model;

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late final ValueNotifier<TimeOfDay?> timeController;

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    timeController = ValueNotifier(initial);
    if (validString(initial)) {
      AddFormBloc.get(context).updateForm(widget.model, formatTime(initial));
    }
    timeController.addListener(() {
      final value = timeController.value;
      AddFormBloc.get(context).updateForm(widget.model, formatTime(value));
    });
  }

  @override
  void dispose() {
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = timeController.value;
        final formData = parseTime(validateString(getData(state, widget.model).toString()));
        if (validString(formData) && data != formData) {
          timeController.value = formData;
        }
      },
      child: Column(
        children: [
          GestureDetector(
            onTap: () => openTimePickerWidget(context),
            child: FormCard(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20.csh,
                  horizontal: 20.csw,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: timeController,
                        builder: (context, value, child) => Text(
                          getSelection(),
                          style: TextStyle(
                            color: context.colors.textColor,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_sharp,
                      color: context.colors.divider,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (timeController.value != null) {
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

  openTimePickerWidget(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final res = await showTimePicker(
      context: context,
      initialTime: timeController.value ?? TimeOfDay.now(),
    );
    if (res != null) {
      timeController.value = res;
    }
  }

  String getSelection() {
    final value = timeController.value;
    if (value == null) {
      return widget.model.hint?.tr(context) ?? '';
    }
    return CustomDateFormats.formatHourMin(context, value);
  }
}
