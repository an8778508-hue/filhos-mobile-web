import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/counter_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/add_form_state.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({
    Key? key,
    required this.model,
  }) : super(key: key);

  final CounterModel model;

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late final ValueNotifier<double> counterController;

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    counterController = ValueNotifier(initial);
    if (validDouble(initial)) {
      AddFormBloc.get(context).updateForm(widget.model, initial);
    }
    counterController.addListener(() {
      final count = counterController.value;
      AddFormBloc.get(context).updateForm(widget.model, count);
    });
  }

  @override
  void dispose() {
    counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = counterController.value;
        final formData = double.tryParse(getData(state, widget.model).toString());
        if (formData != null && data != formData) {
          counterController.value = formData;
        }
      },
      child: Column(
        children: [
          FormCard(
            child: Row(
              children: [
                InkResponse(
                  onTap: () => sub(),
                  child: Container(
                    width: 50.csw,
                    height: 50.csw,
                    margin: EdgeInsets.symmetric(
                      horizontal: 25.csw,
                      vertical: 25.csh,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.scaffold,
                    ),
                    child: Icon(
                      Icons.remove,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ValueListenableBuilder(
                      valueListenable: counterController,
                      builder: (context, value, child) => Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                InkResponse(
                  onTap: () => add(),
                  child: Container(
                    width: 50.csw,
                    height: 50.csw,
                    margin: EdgeInsets.symmetric(
                      horizontal: 25.csw,
                      vertical: 25.csh,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.scaffold,
                    ),
                    child: Icon(
                      Icons.add,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (counterController.value > 0.0) {
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

  calculate(double Function(double a, double b) function) {
    final max = widget.model.max;
    final min = widget.model.min;
    final step = widget.model.step;
    final count = counterController.value;
    final newValue = function(count, step).clamp(min, max);
    //fixes fractions like 2.0000000000003
    counterController.value = double.parse(newValue.toStringAsFixed(2));
  }

  add() => calculate((a, b) => a + b);

  sub() => calculate((a, b) => a - b);
}
