import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

import 'forms.dart';

class DropDownWidget extends StatefulWidget {
  const DropDownWidget({
    super.key,
    required this.model,
  });

  final DropDownModel model;

  @override
  State<DropDownWidget> createState() => _DropDownWidgetState();
}

class _DropDownWidgetState extends State<DropDownWidget> {
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

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            onTap: () => openDropDown(),
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
                        valueListenable: selectedItemController,
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

  openDropDown() async {
    final items = widget.model.values;
    FocusScope.of(context).unfocus();
    final res = await showModalBottomSheet<DropDownValueModel>(
      context: context,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      builder: (context) => DropDownSheet(
        items: items,
        initial: selectedItemController.value,
        title: widget.model.hint.tr(context),
      ),
    );
    if (res != null) {
      selectedItemController.value = res.id;
    }
  }

  String getSelection() {
    final items = widget.model.values;
    final selectedId = selectedItemController.value;
    bool find(DropDownValueModel e) => e.id == selectedId;
    if (items.any(find)) {
      final selectedItem = items.firstWhere(find);
      return selectedItem.title.tr(context);
    }
    return widget.model.hint.tr(context);
  }
}

class DropDownSheet extends StatefulWidget {
  const DropDownSheet({
    super.key,
    required this.items,
    required this.title,
    this.initial,
  });

  final List<DropDownValueModel> items;
  final String? initial;
  final String title;

  @override
  State<DropDownSheet> createState() => _DropDownSheetState();
}

class _DropDownSheetState extends State<DropDownSheet> {
  late final ValueNotifier<String?> selectedItemController;

  @override
  void initState() {
    super.initState();
    selectedItemController = ValueNotifier(widget.initial);
    selectedItemController.addListener(() {
      final selectedId = selectedItemController.value;
      bool find(DropDownValueModel e) => e.id == selectedId;
      final items = widget.items;
      if (items.any(find)) {
        final selectedItem = items.firstWhere(find);
        Navigator.of(context).pop(selectedItem);
      }
    });
  }

  @override
  void dispose() {
    selectedItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .4,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 40.csh),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.csw),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textColor,
                ),
              ),
            ),
            SizedBox(height: 15.csh),
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(
                horizontal: 30.csw,
              ),
              color: context.colors.disabled,
            ),
            ValueListenableBuilder(
              valueListenable: selectedItemController,
              builder: (context, value, child) => SeparatedColumn(
                separatorBuilder: (BuildContext context, int index) => Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(horizontal: 30.csw),
                  color: context.colors.disabled,
                ),
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...widget.items.map(
                    (e) {
                      final isSelected = e.id == selectedItemController.value;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => selectedItemController.value = e.id,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.csw, vertical: 15.csh),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: context.colors.primary,
                              ),
                              SizedBox(width: 14.csw),
                              Expanded(
                                child: Text(
                                  e.title.tr(context),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.sp,
                                    color: context.colors.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
