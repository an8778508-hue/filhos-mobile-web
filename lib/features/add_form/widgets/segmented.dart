import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:separated_row/separated_row.dart';

class SegmentedControlWidget extends StatefulWidget {
  const SegmentedControlWidget({
    super.key,
    required this.model,
  });

  final SegmentedControlModel model;

  @override
  State<SegmentedControlWidget> createState() => _SegmentedControlWidgetState();
}

class _SegmentedControlWidgetState extends State<SegmentedControlWidget> {
  late final ValueNotifier<String?> selectedItemController;

  @override
  void initState() {
    super.initState();
    final initial = widget.model.initial;
    selectedItemController = ValueNotifier(initial);
    if (validString(initial)) {
      AddFormBloc.get(context).updateForm(widget.model, initial);
    }
    selectedItemController.addListener(() {
      final selectedItem = selectedItemController.value;
      AddFormBloc.get(context).updateForm(widget.model, selectedItem);
    });
  }

  @override
  void dispose() {
    selectedItemController.dispose();
    super.dispose();
  }

  AddFormType get type => Provider.of(context, listen: false);

  bool get isNested => context.findAncestorWidgetOfExactType<CollectionWidget>() != null;

  @override
  Widget build(BuildContext context) {
    final items = widget.model.values;
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final data = selectedItemController.value;
        final formData = validateString(getData(state, widget.model).toString());
        if (validString(formData) && data != formData) {
          selectedItemController.value = formData;
        }
      },
      child: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: selectedItemController,
            builder: (context, value, child) => SeparatedRow(
              separatorBuilder: (context, index) => SizedBox(width: 10.csw),
              children: [
                ...items.map(
                  (item) {
                    final selectedId = selectedItemController.value;
                    final isSelected = selectedId == item.id;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onSelected(item.id),
                        child: AnimatedContainer(
                          height: isNested ? 40.csh : 60.h,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.primary
                                : isNested
                                    ? null
                                    : context.colors.background,
                            borderRadius: BorderRadius.circular(5.r),
                            border: isNested
                                ? Border.all(
                                    color: isSelected ? context.colors.primary : context.colors.disabled,
                                    width: 1,
                                  )
                                : null,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 5.csh),
                          alignment: Alignment.center,
                          child: Text(
                            item.title.tr(context),
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13.sp,
                              color: isSelected ? context.colors.secondaryTextColor : context.colors.textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.model.required)
            FormField(
              validator: (value) {
                if (validString(selectedItemController.value)) {
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

  onSelected(String id) {
    selectedItemController.value = id;
  }
}
