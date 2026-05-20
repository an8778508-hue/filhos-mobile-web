import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'custom_form_field.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.focusNode,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.hintColor,
    this.onTap,
    this.borderColor,
    this.isPassword = false,
    this.readOnly = false,
    this.fontSize,
    this.hintFontSize,
    this.maxLines,
    this.minLines,
    this.initial,
    this.validator,
    this.contentPaddingHorizontal,
    this.firstIconPath,
    this.padding,
    this.radius,
    this.onChanged,
    this.hasBorder = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.textDirection,
    this.marginErrorWidth = 0.0,
    this.marginErrorHeight = 0.0,
    this.marginHeight = 0,
    this.marginWidth = 0,
    this.borderRadius,
    this.fontWeight,
    this.keyboardType,
    this.textInputAction,
    this.obscurePasswordController,
    this.onSubmit,
    this.trailing,
    this.contentPaddingVertical,
  });

  final String? hint;
  final Color textColor;
  final Color? hintColor;
  final bool isPassword;
  final bool readOnly;
  final GestureTapCallback? onTap;
  final Color backgroundColor;
  final double? fontSize;
  final double? hintFontSize;
  final double? borderRadius;
  final Color? borderColor;
  final MainAxisAlignment mainAxisAlignment;
  final FontWeight? fontWeight;
  final TextDirection? textDirection;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  final EdgeInsetsGeometry? padding;
  final double? radius;
  final double? contentPaddingHorizontal, contentPaddingVertical;
  final double marginHeight;
  final double marginWidth;
  final double marginErrorHeight;
  final double marginErrorWidth;
  final bool hasBorder;
  final int? maxLines;
  final int? minLines;

  final String? initial;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueNotifier<bool>? obscurePasswordController;
  final ValueChanged<String>? onSubmit;
  final Widget? trailing;
  final FocusNode? focusNode;
  final String? firstIconPath;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final ValueNotifier<bool> obscureText;

  @override
  void initState() {
    super.initState();
    obscureText = widget.obscurePasswordController ?? ValueNotifier(widget.isPassword);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: obscureText,
      builder: (context, value, child) => CustomFormField(
        initial: widget.initial,
        validator: widget.validator,
        marginWidth: widget.marginErrorWidth,
        marginHeight: widget.marginErrorHeight,
        builder: (field) => Container(
          padding: widget.padding ?? EdgeInsets.all(0.h),
          margin: EdgeInsets.symmetric(
            horizontal: widget.marginWidth.csw,
            vertical: widget.marginHeight.csh,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: widget.hasBorder
                ? Border.all(color: (widget.borderColor ?? context.colors.primary), width: 1.5.csw)
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 11.5.r),
          ),
          child: Row(
            children: [
              if (widget.firstIconPath != null)
                MyIcon(
                  widget.firstIconPath ?? '',
                  size: 20.w,
                  color: context.colors.greyLight,
                ),
              Expanded(
                child: TextField(
                  readOnly: widget.readOnly,
                  onTapOutside: (e) => FocusScope.of(context).unfocus(),
                  onTap: widget.onTap,
                  focusNode: widget.focusNode,
                  controller: widget.controller,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  onChanged: (value) {
                    field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                  onSubmitted: (value) {
                    widget.onSubmit?.call(value);
                  },
                  style: TextStyle(
                      fontSize: widget.fontSize ?? 18.sp,
                      color: widget.textColor,
                      fontWeight: widget.fontWeight ?? FontWeight.w500),
                  obscureText: obscureText.value,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                        fontSize: widget.hintFontSize ?? 18.sp,
                        color: widget.hintColor ?? widget.textColor.withOpacity(0.7),
                        fontWeight: widget.fontWeight ?? FontWeight.w300),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal:
                            widget.contentPaddingHorizontal != null ? (widget.contentPaddingHorizontal ?? 0).w : 10.w,
                        vertical: widget.contentPaddingVertical ?? 2.h),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
              if (widget.isPassword)
                IconButton(
                  onPressed: () {
                    obscureText.value = !obscureText.value;
                  },
                  icon: Icon(
                    obscureText.value ? Icons.remove_red_eye : Icons.remove_red_eye_outlined,
                    color: context.colors.divider,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
