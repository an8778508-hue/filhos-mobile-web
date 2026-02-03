import 'package:escola/core/components/fields/custom_form_field.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectableField<T> extends StatefulWidget {
  final String? Function(String?)? validator;
  final Widget Function(T) item;

  final bool Function(T, String) whereCondition;
  final ValueChanged<T> onSelected;
  final List<T> list;
  final bool readOnly;
  final double? strokeWidth;
  final double? elevation;
  final Color? strokeColor;
  final Color? background;
  final String? value;
  final String hintKey;
  final double marginErrorHeight;
  final double marginErrorWidthPercentage;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const SelectableField({
    Key? key,
    required this.onSelected,
    required this.whereCondition,
    required this.list,
    required this.validator,
    required this.item,
    required this.value,
    required this.hintKey,
    this.marginErrorWidthPercentage = 0.0,
    this.marginErrorHeight = 0.0,
    this.strokeWidth,
    this.padding,
    this.borderRadius = 0.0,
    this.elevation = 0.0,
    this.background,
    this.strokeColor,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<SelectableField<T>> createState() => _SelectableFieldState<T>();
}

class _SelectableFieldState<T> extends State<SelectableField<T>> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: GestureDetector(
        onTap: widget.readOnly ? null : () => _onTap(),
        child: CustomFormField(
          validator: widget.validator,
          marginWidth: widget.marginErrorWidthPercentage,
          marginHeight: widget.marginErrorHeight,
          builder: (field) => Directionality(
            textDirection: TextDirection.ltr,
            child: _FilledTextFiled(
              width: double.maxFinite,
              strokeColor: widget.strokeColor,
              elevation: widget.elevation,
              shadowColor: const Color(0xffeaeaea),
              padding: widget.padding,
              borderRadius: widget.borderRadius,
              strokeWidth: widget.strokeWidth,
              background: widget.background,
              child: Row(
                children: [
                  if (widget.value != null)
                    Expanded(
                      child: Text(
                        widget.value!,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp, color: context.colors.textColor),
                      ),
                    ),
                  if (widget.value == null)
                    Expanded(
                      child: Text(
                        (widget.hintKey).tr(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14.sp,
                          color: Color(0xffD0D0D0),
                        ),
                      ),
                    ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20.sp,
                    color: const Color(0xff707070),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _onTap() async {
    final res = await showModalBottomSheet<T?>(
      isDismissible: true,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - getHeightByNumber(100),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
      ),
      context: context,
      builder: (context) => SelectableBottomSheet(
        item: widget.item,
        list: widget.list,
        whereCondition: widget.whereCondition,
      ),
    );
    if (res != null) {
      widget.onSelected.call(res);
    }
  }
}

class SelectableBottomSheet<T> extends StatefulWidget {
  const SelectableBottomSheet({
    super.key,
    required this.whereCondition,
    required this.list,
    required this.item,
  });

  final List<T> list;
  final Widget Function(T) item;

  final bool Function(T, String) whereCondition;

  @override
  State<SelectableBottomSheet<T>> createState() => _SelectableBottomSheetState<T>();
}

class _SelectableBottomSheetState<T> extends State<SelectableBottomSheet<T>> {
  late final ValueNotifier<List<T>> myList = ValueNotifier<List<T>>([]);
  late final TextEditingController controller;

  @override
  void initState() {
    myList.value = [...widget.list];
    controller = TextEditingController();
    super.initState();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 24.h),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Align(
                alignment: AlignmentDirectional.center,
                child: Text(
                  (LocalizationKeys.search).tr(context),
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  icon: MyIcon(
                     'assets/icons/close.svg',
                    size: 15.h,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            validator: (value) {
              return null;
            },
            controller: controller,
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: getHeightByNumber(0), horizontal: getWidthByNumber(16)),
            hasBorder: true,
            marginWidth: 20,
            borderColor: context.colors.greyLight,
            mainAxisAlignment: MainAxisAlignment.center,
            textColor: context.colors.textColor,
            hintColor: Color(0xffD0D0D0),
            firstIconPath: assetsPath('search'),
            // firstIconColor: Colors.black,
            hint: (LocalizationKeys.search).tr(context),
            onChanged: (value) {
              if (validString(value)) {
                myList.value = [...widget.list.where((element) => widget.whereCondition(element, value))];
              } else {
                myList.value = [...widget.list];
              }
            },
            maxLines: 1,
            borderRadius: 20.r,
            fontSize: 14.sp,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: myList,
              builder: (context, myList, child) => ListView.separated(
                itemCount: myList.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  T item = myList[index];
                  return widget.item(item);
                },
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _FilledTextFiled extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double? strokeWidth;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final Color? strokeColor;
  final Color? background;
  final Color? shadowColor;

  const _FilledTextFiled(
      {Key? key,
      required this.child,
      this.width,
      this.strokeWidth,
      this.padding,
      this.borderRadius,
      this.elevation,
      this.shadowColor,
      this.strokeColor,
      this.background,
      this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width ?? 358.sp,
        // height: height ?? 56.sp,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
            color: background ?? context.colors.background.withOpacity(0.06),
            boxShadow: elevation == null
                ? null
                : kElevationToShadow[elevation]
                    ?.map((e) => BoxShadow(
                          blurRadius: e.blurRadius,
                          blurStyle: e.blurStyle,
                          offset: e.offset,
                          spreadRadius: e.spreadRadius,
                          color: shadowColor ?? Colors.black,
                        ))
                    .toList(),
            borderRadius: BorderRadius.circular(borderRadius ?? 10.sp),
            border: Border.all(color: strokeColor ?? context.colors.greyLight, width: strokeWidth ?? 1.sp)),
        child: Center(child: child));
  }
}
