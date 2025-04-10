import 'package:escola/core/utils/debouncer.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RowFormatters extends StatelessWidget {
  final String label;
  final TextInputFormatter formatter;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

   RowFormatters({super.key, required this.label, required this.formatter, required this.controller, this.onSubmitted});

  final Debouncer _debouncer = Debouncer();



  @override
  Widget build(BuildContext context) {
    return Container(
      // height: height ?? 56.sp,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(25.r),
          ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.numberWithOptions(signed: false,decimal: false),
        textInputAction:TextInputAction.done ,
        onChanged: (value) {
          _debouncer.runLazy(() {
          onSubmitted?.call(value.replaceAll('.', '').replaceAll('-', ''));
          }, 600);
        },
        decoration: InputDecoration(
          label: Text(
            label,
            style: TextStyle(
              color: context.colors.greyLight,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 15.w,
          ).add(EdgeInsets.only(bottom: 20.h)),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          formatter,
        ],
      ),
    );
  }
}
