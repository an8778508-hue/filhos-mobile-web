import 'package:escola/core/components/text/text.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomFormField extends StatefulWidget {
  final FormFieldBuilder builder;
  final String? Function(String?)? validator;

  final String? initial;
  final double marginHeight;
  final double marginWidth;
  final TextAlign errorAlign;

  const CustomFormField({
    super.key,
    required this.validator,
    this.errorAlign = TextAlign.center,
    this.marginHeight = 0.0,
    this.marginWidth = 0.0,
    this.initial,
    required this.builder,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField>
    with SingleTickerProviderStateMixin {
  // late AnimationController animationController ;
  //  @override
  // void initState() {
  //    animationController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(seconds: 1),
  //     upperBound: pi * 2,
  //     lowerBound: 0,
  //   );
  //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //     animationController.repeat();
  //   });
  //   super.initState();
  // }
  //
  // @override
  // void dispose() {
  //   animationController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.initial,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: double.maxFinite, child: widget.builder(field)),
          if (field.hasError) SizedBox(height: 15.csh),
          if (field.hasError)
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 15.csw, vertical: 5.csh),
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: context.colors.error,
                // border: Border.all(color: Colors.red.shade900,width: 1),
                borderRadius: BorderRadius.circular(5.r),
                // boxShadow: kElevationToShadow[8],
              ),
              child: CommonBoldText(
                marginHeight: widget.marginHeight,
                marginWidth: widget.marginWidth,
                value: field.errorText!,
                size: 14.sp,
                textColor: context.colors.background,
                align: widget.errorAlign,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
