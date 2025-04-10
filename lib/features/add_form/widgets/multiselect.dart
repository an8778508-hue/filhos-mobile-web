import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

import '../bloc/add_form_state.dart';
import '../models/multiselect_model.dart';
import 'forms.dart';

class MultiSelect extends StatefulWidget {
  const MultiSelect({
    super.key,
    required this.model,
  });

  final MultiSelectModel model;

  @override
  State<MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  late final ValueNotifier<List<String>> selectedItemController;

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
        final formData = validateList(getData(state, widget.model));
        if (validList(formData) && data != formData) {
          selectedItemController.value = List<String>.from(formData);
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
                          getSelection().join(', '),
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
                if (validList(selectedItemController.value)) {
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
    final res = await showModalBottomSheet<List<String>>(
      context: context,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      builder: (context) => MultiSelectSheet(
        items: items,
        initial: selectedItemController.value,
        title: widget.model.hint.tr(context),
        limit: widget.model.limit,
      ),
    );
    if (validList(res)) {
      selectedItemController.value = [...res!];
    }
  }

  List<String> getSelection() {
    final items = widget.model.values;
    final selectedItems = selectedItemController.value;
    if (validList(selectedItems) && validList(items)) {
      return items
          .where((item) => selectedItems.any((selectedItem) => selectedItem == item.id))
          .map((e) => e.title.tr(context))
          .toList();
    }
    return [widget.model.hint.tr(context)];
  }
}

class MultiSelectSheet extends StatefulWidget {
  const MultiSelectSheet({
    super.key,
    required this.items,
    required this.title,
    this.initial = const [],
    this.limit,
  });

  final List<MultiSelectValueModel> items;
  final List<String> initial;
  final String title;
  final int? limit;

  @override
  State<MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<MultiSelectSheet> {
  late final ValueNotifier<List<String>> selectedItemController;

  @override
  void initState() {
    super.initState();
    selectedItemController = ValueNotifier(widget.initial);
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
                      final isSelected = selectedItemController.value.any((id) => e.id == id);
                      final cantSelect = widget.limit != null && selectedItemController.value.length >= widget.limit!;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isSelected) {
                            selectedItemController.value = [...selectedItemController.value.where((id) => e.id != id)];
                          } else {
                            if (cantSelect) {
                            } else {
                              selectedItemController.value = [...selectedItemController.value, e.id];
                            }
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.csw, vertical: 15.csh),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isSelected
                                    ? context.colors.primary
                                    : cantSelect
                                        ? context.colors.greyDark
                                        : context.colors.primary,
                              ),
                              SizedBox(width: 14.csw),
                              Expanded(
                                child: Text(
                                  e.title.tr(context),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14.sp,
                                    color: isSelected
                                        ? context.colors.textColor
                                        : cantSelect
                                            ? context.colors.greyDark
                                            : context.colors.textColor,
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
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0.w),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop(selectedItemController.value);
                },
                child: Container(
                  height: 60.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    LocalizationKeys.save.tr(context),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: context.colors.secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
