
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

import '../bloc/add_form_state.dart';
import 'forms.dart';

class PeriodOfTimeWidget extends StatefulWidget {
  const PeriodOfTimeWidget({
    super.key,
    required this.model,
  });

  final PeriodOfTimeModel model;

  @override
  State<PeriodOfTimeWidget> createState() => _PeriodOfTimeWidgetState();
}

class _PeriodOfTimeWidgetState extends State<PeriodOfTimeWidget> {
  late final ValueNotifier<List<String>> selectedItemController;
  late final ValueNotifier<String?> doseNumberValueNotifier;

  @override
  void initState() {
    super.initState();
    selectedItemController = ValueNotifier(widget.model.initial);
    doseNumberValueNotifier = ValueNotifier(null);
    final selectedItem = selectedItemController.value;
    AddFormBloc.get(context).updateForm(widget.model, selectedItem);
    _updateDoseNumberValue();
    AddFormBloc.get(context).stream.listen((state) {
      final newDoseValue = state.formState.data?.entries
          .where((e) => e.key.id == 'dose_number_id')
          .firstOrNull?.value.value.toString();

      if (newDoseValue != null && newDoseValue != doseNumberValueNotifier.value) {
        doseNumberValueNotifier.value = newDoseValue;
        // Automatically adjust selected times if needed
        _validateTimeSelections();
      }
    });
    selectedItemController.addListener(() {
      final selectedItem = selectedItemController.value;
      print('_PeriodOfTimeWidgetState.initState 12 ${widget.model} $selectedItem ');
      AddFormBloc.get(context).updateForm(widget.model, selectedItem);
    });
  }
  void _updateDoseNumberValue() {
    final currentDoseValue = AddFormBloc.get(context)
        .state
        .formState
        .data
        ?.entries
        .where((e) => e.key.id == 'dose_number_id')
        .firstOrNull
        ?.value
        .value
        .toString();
    debugPrint('Current dose value: $currentDoseValue');
    if (currentDoseValue != null) {
      doseNumberValueNotifier.value = currentDoseValue;
    }
  }
  void _validateTimeSelections() {
    final requiredTimes = doseNumberValueNotifier.value == '3' ? 2 : 1;
    debugPrint('Validating selections against requiredTimes: $requiredTimes');

    // If we have more selected times than required, trim the excess
    if (selectedItemController.value.length > requiredTimes) {
      // Keep only the first 'requiredTimes' selections
      selectedItemController.value = selectedItemController.value.sublist(0, requiredTimes);
    }
  }
  @override
  void dispose() {
    doseNumberValueNotifier.dispose();
    selectedItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requiredTimes = AddFormBloc.get(context).requiredTimeSelections;
    debugPrint('requiredTimes from build $requiredTimes');
    return MultiBlocListener(
      listeners: [
        BlocListener<AddFormBloc, AddFormState>(
          listenWhen: updateWhen(widget.model),
          listener: (context, state) {
            final data = selectedItemController.value;
            final formData = validateList(getData(state, widget.model));
            if (validList(formData) && data != formData) {
              selectedItemController.value = List<String>.from(formData);
            }
          },
        ),
      ],
      child: Column(
        children: [
          GestureDetector(
            onTap: () => openDropDown(context),
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
                // final limit = AddFormBloc.get(context)
                //             .state
                //             .formState
                //             .data
                //             ?.entries
                //             .safeFirstWhere((e) => e.key.id == 'dose_number_id')
                //             ?.value
                //             .value
                //             .toString() ==
                //         '3'
                //     ? 2
                //     : 1;
                // final doseNumberValue = AddFormBloc.get(context)
                //     .state
                //     .formState
                //     .data
                //     ?.entries
                //     .safeFirstWhere((e) => e.key.id == 'dose_number_id')
                //     ?.value
                //     .value
                //     .toString();
                final requiredTimes = AddFormBloc.get(context).requiredTimeSelections;
                 debugPrint('requiredTimes from validator $requiredTimes');
                // final requiredTimes = doseNumberValue == '3' ? 2 : 1;
                if (!validList(selectedItemController.value)) {
                  return LocalizationKeys.this_field_cant_be_empty.tr(context);
                }
                if (selectedItemController.value.length != requiredTimes) {
                  debugPrint('selectedItemController.value.length ${selectedItemController.value.length}');
                  // debugPrint('limit $limit');
                  // return LocalizationKeys.choose_at_least.tr(context, requiredTimes.toString());
                  if(requiredTimes==1){
                    return LocalizationKeys.choose_at_least_one.tr(context);
                  }else if(requiredTimes==2){
                    return LocalizationKeys.choose_at_least_two.tr(context, requiredTimes.toString());
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

  openDropDown(BuildContext context) async {
    final items = widget.model.values;
    FocusScope.of(context).unfocus();
    _updateDoseNumberValue();
    print('_PeriodOfTimeWidgetState.openDropDown ${selectedItemController.value}');
    // final requiredTimes = doseNumberValueNotifier.value == '3' ? 2 : 1;
    final requiredTimes = AddFormBloc.get(context).requiredTimeSelections;
    // final requiredTimes = doseNumberValue == '3' ? 2 : 1;
    debugPrint('requiredTimes from open DropDown $requiredTimes');
    final res = await showModalBottomSheet<List<String>>(
      context: context,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      builder: (_) => PeriodOfTimeSheet(
        items: items,
        initial: selectedItemController.value,
        title: widget.model.hint.tr(context),
        limit: requiredTimes ,
        // limit: AddFormBloc.get(context)
        //             .state
        //             .formState
        //             .data
        //             ?.entries
        //             .safeFirstWhere((e) => e.key.id == 'dose_number_id')
        //             ?.value
        //             .value
        //     .toString() ==
        //     '3'
        //     ? 2
        //     : 1,
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

class PeriodOfTimeSheet extends StatefulWidget {
  const PeriodOfTimeSheet({
    super.key,
    required this.items,
    required this.title,
    this.initial = const [],
    this.limit,
  });

  final List<PeriodOfTimeValueModel> items;
  final List<String> initial;
  final String title;
  final int? limit;

  @override
  State<PeriodOfTimeSheet> createState() => _PeriodOfTimeSheetState();
}

class _PeriodOfTimeSheetState extends State<PeriodOfTimeSheet> {
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
  @override
  Widget build(BuildContext context) {
    debugPrint('_widget.Limit ${widget.limit}');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * .35,
                  child: SingleChildScrollView(
                    child: ValueListenableBuilder(
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
                                // onTap: () {
                                //   if (isSelected) {
                                //     selectedItemController.value = [...selectedItemController.value.where((id) => e.id != id)];
                                //   } else {
                                //     if (cantSelect) {
                                //     } else {
                                //       selectedItemController.value = [...selectedItemController.value, e.id];
                                //     }
                                //   }
                                // },
                                onTap: () {
                                  if (isSelected) {
                                    // Always allow deselection
                                    selectedItemController.value = [...selectedItemController.value.where((id) => e.id != id)];
                                  } else {
                                    // Check if adding would exceed the limit
                                    if (widget.limit != null && selectedItemController.value.length >= widget.limit!) {
                                      // If at limit, replace the first selection with the new one for better UX
                                      final newSelections = [...selectedItemController.value];
                                      newSelections.removeAt(0);
                                      newSelections.add(e.id);
                                      selectedItemController.value = newSelections;
                                    } else {
                                      // Add normally if under limit
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
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.only(
            left: 30.0.w,
            right: 30.0.w,
            bottom: 20.h,
          ),
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
    );
  }
  // Widget build(BuildContext context) {
  //   return ConstrainedBox(
  //     constraints: BoxConstraints(
  //       maxHeight: MediaQuery.of(context).size.height * .4,
  //     ),
  //     child: SingleChildScrollView(
  //       padding: EdgeInsets.symmetric(vertical: 40.csh),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 30.csw),
  //             child: Text(
  //               widget.title,
  //               style: TextStyle(
  //                 fontSize: 20.sp,
  //                 fontWeight: FontWeight.w500,
  //                 color: context.colors.textColor,
  //               ),
  //             ),
  //           ),
  //           SizedBox(height: 15.csh),
  //           Container(
  //             height: 1,
  //             margin: EdgeInsets.symmetric(
  //               horizontal: 30.csw,
  //             ),
  //             color: context.colors.disabled,
  //           ),
  //           ValueListenableBuilder(
  //             valueListenable: selectedItemController,
  //             builder: (context, value, child) => SeparatedColumn(
  //               separatorBuilder: (BuildContext context, int index) => Container(
  //                 height: 1,
  //                 margin: EdgeInsets.symmetric(horizontal: 30.csw),
  //                 color: context.colors.disabled,
  //               ),
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 ...widget.items.map(
  //                   (e) {
  //                     final isSelected = selectedItemController.value.any((id) => e.id == id);
  //                     final cantSelect = widget.limit != null && selectedItemController.value.length >= widget.limit!;
  //                     return GestureDetector(
  //                       behavior: HitTestBehavior.opaque,
  //                       onTap: () {
  //                         if (isSelected) {
  //                           selectedItemController.value = [...selectedItemController.value.where((id) => e.id != id)];
  //                         } else {
  //                           if (cantSelect) {
  //                           } else {
  //                             selectedItemController.value = [...selectedItemController.value, e.id];
  //                           }
  //                         }
  //                       },
  //                       child: Padding(
  //                         padding: EdgeInsets.symmetric(horizontal: 30.csw, vertical: 15.csh),
  //                         child: Row(
  //                           children: [
  //                             Icon(
  //                               isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
  //                               color: isSelected
  //                                   ? context.colors.primary
  //                                   : cantSelect
  //                                       ? context.colors.greyDark
  //                                       : context.colors.primary,
  //                             ),
  //                             SizedBox(width: 14.csw),
  //                             Expanded(
  //                               child: Text(
  //                                 e.title.tr(context),
  //                                 style: TextStyle(
  //                                   fontWeight: FontWeight.w400,
  //                                   fontSize: 14.sp,
  //                                   color: isSelected
  //                                       ? context.colors.textColor
  //                                       : cantSelect
  //                                           ? context.colors.greyDark
  //                                           : context.colors.textColor,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 )
  //               ],
  //             ),
  //           ),
  //           SizedBox(height: 20.h),
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 30.0.w),
  //             child: InkWell(
  //               onTap: () {
  //                 Navigator.of(context).pop(selectedItemController.value);
  //               },
  //               child: Container(
  //                 height: 60.h,
  //                 width: double.infinity,
  //                 decoration: BoxDecoration(
  //                   color: context.colors.primary,
  //                   borderRadius: BorderRadius.circular(10.r),
  //                 ),
  //                 alignment: Alignment.center,
  //                 child: Text(
  //                   LocalizationKeys.save.tr(context),
  //                   style: TextStyle(
  //                     fontSize: 14.sp,
  //                     fontWeight: FontWeight.w500,
  //                     color: context.colors.secondaryTextColor,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
