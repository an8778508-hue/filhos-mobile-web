import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/date_formats.dart';
import 'package:escola/core/utils/date_time_utils.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/date_picker_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/add_form_state.dart';
import 'forms.dart';

class DatePickerWidget extends StatefulWidget {
  const DatePickerWidget({
    super.key,
    required this.model,
  });

  final DatePickerModel model;

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late final ValueNotifier<DateTime?> dateController;

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    dateController = ValueNotifier(initial);
    print('_DatePickerWidgetState.initState $initial');
    if (initial != null) {
      AddFormBloc.get(context).updateForm(widget.model, formatDateTime(initial, dateOnly: true));
    }
    dateController.addListener(() {
      final value = dateController.value;
      AddFormBloc.get(context).updateForm(widget.model, formatDateTime(value, dateOnly: true));
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = dateController.value;
        final formData = parseDateTime(validateString(getData(state, widget.model).toString()));
        if (validString(formData) && data != formData) {
          dateController.value = formData;
        }
      },
      child: Column(
        children: [
          GestureDetector(
            onTap: () => openDatePickerWidget(context),
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
                        valueListenable: dateController,
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
                if (dateController.value == null) {
                  return LocalizationKeys.this_field_cant_be_empty.tr(context);
                }

                final startingDate = AddFormBloc.get(context)
                    .state
                    .formState
                    .data
                    ?.entries
                    .safeFirstWhere((e) => e.key.id == 'starting_date')
                    ?.value
                    .value;

                DateTime? startingDateTime;

                if (validString(startingDate) && widget.model.id == 'ending_date') {
                  startingDateTime = parseDateTime(startingDate.toString());
                  if (startingDateTime != null) {
                    if (dateController.value?.isBefore(startingDateTime) == true) {
                      return LocalizationKeys.this_date_cant_be_after
                          .tr(context, CustomDateFormats.formatDayMonthYear2(startingDateTime));
                    }
                  }
                }

                return null;
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

  openDatePickerWidget(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final startingDate = AddFormBloc.get(context)
        .state
        .formState
        .data
        ?.entries
        .safeFirstWhere((e) => e.key.id == 'starting_date')
        ?.value
        .value;

    DateTime? startingDateTime;

    if (validString(startingDate) && widget.model.id == 'ending_date') {
      startingDateTime = parseDateTime(startingDate.toString());
    }

    DateTime min = widget.model.min ?? startingDateTime ?? DateTime.now();
    final DateTime current = dateController.value ?? min;
    DateTime max = widget.model.max ?? DateTime.now().add(const Duration(days: 365));
    if (current.isBefore(min)) {
      min = current;
    }
    if (current.isAfter(max)) {
      max = current;
    }
    final res = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: min,
      lastDate: max,
    );
    if (res != null) {
      dateController.value = res;
    }
  }

  String getSelection() {
    final value = dateController.value;
    if (value == null) {
      return widget.model.hint?.tr(context) ?? '';
    }
    return CustomDateFormats.formatDayMonthYear2(value);
  }
}
