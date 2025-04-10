import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/multi_select_model.dart';
import 'package:escola/core/models/multi_select_model.dart';
import 'package:escola/core/models/multi_select_model.dart';
import 'package:escola/core/models/multi_select_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

class MultiSelectWidget extends StatefulWidget {
  const MultiSelectWidget({
    super.key,
    required this.hint,
    required this.title,
    required this.models,
    required this.initial,
    required this.onSelect,
  });

  final String hint;
  final String title;
  final List<MultiSelectModel> models;
  final List<MultiSelectModel> initial;
  final  Function(List<MultiSelectModel>) onSelect;

  @override
  State<MultiSelectWidget> createState() => _MultiSelectWidgetState();
}

class _MultiSelectWidgetState extends State<MultiSelectWidget> {
  late final ValueNotifier<List<MultiSelectModel>> selectedItemController;

  @override
  void initState() {
    selectedItemController = ValueNotifier(widget.initial);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final child = Padding(
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
    );
    return GestureDetector(
      onTap: () => openMultiSelect(),
      child: FormCard(child: child,radius: 30.r),
    );
  }

  openMultiSelect() async {
    final items = widget.models;
    FocusScope.of(context).unfocus();
    final res = await showModalBottomSheet<List<MultiSelectModel>>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      builder: (context) => MultiSelectSheet(
        items: items,
        title: widget.hint,
        initial: selectedItemController.value,
      ),
    );
    if (res != null) {
      selectedItemController.value = res;
      widget.onSelect.call(res);
    }
  }

  String getSelection() {
    final items = widget.models;
    final selectedId = selectedItemController.value;
    bool find(MultiSelectModel e) => selectedId.any((element) => element.id == e.id);
    if (items.any(find)) {
      final selectedItem = items.firstWhere(find);
      return selectedItem.title;
    }
    return widget.hint;
  }
}

class MultiSelectSheet extends StatefulWidget {
  const MultiSelectSheet({
    super.key,
    required this.items,
    required this.title,
    required this.initial,
  });

  final List<MultiSelectModel> items;
  final List<MultiSelectModel> initial;
  final String title;

  @override
  State<MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<MultiSelectSheet> {
  late final ValueNotifier<List<MultiSelectModel>> selectedItemController;

  @override
  void initState() {
    super.initState();
    selectedItemController = ValueNotifier(widget.initial);
    selectedItemController.addListener(() {
      final selectedId = selectedItemController.value;
      bool find(MultiSelectModel e) => selectedId.any((element) => element.id == e.id);
      final items = widget.items;
      if (items.any(find)) {
        final selectedItem = items.firstWhere(find);
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
    return SingleChildScrollView(
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
                    final isSelected = selectedItemController.value.any(
                      (element) => element.id == e.id,
                    );
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isSelected) {
                          selectedItemController.value.removeWhere(
                            (element) => e.id == element.id,
                          );
                        } else {
                          selectedItemController.value.add(e);
                        }
                        selectedItemController.value = [...selectedItemController.value];
                      },
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
                                e.title,
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
          SizedBox(height: 10.csh),
          ButtonWithIcon(
            marginWidth: 30.0,
            marginHeight: 0.0,
            isLoading: false,
            mainAxisAlignment: MainAxisAlignment.center,
            onPressed: () {
              Navigator.of(context).pop(selectedItemController.value);
            },
            buttonBackgroundColor: context.colors.primary,
            textColor: context.colors.secondaryTextColor,
            text: LocalizationKeys.save.tr(context),
            borderRadius: 30.r,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
          )
        ],
      ),
    );
  }
}
