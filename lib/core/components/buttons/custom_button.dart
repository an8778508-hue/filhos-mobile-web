import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Function()? onTap;
  final double horizontalPadding;
  final double textVerticalPadding;
  final TextAlign? textAlign;
  final bool hasMinWidth, isDisabled, isLoading;
  const CustomButton({
    required this.title,
    required this.onTap,
    this.horizontalPadding = 20,
    this.textVerticalPadding = 15,
    super.key,
    this.textAlign ,
    this.hasMinWidth = true,
    this.isDisabled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.csw),
      child: MaterialButton(
        minWidth: hasMinWidth ? double.infinity : null,
        color: isDisabled ? context.colors.greyLight : context.colors.primary,
        disabledColor: context.colors.greyLight,
        textColor: context.colors.background,
        padding: EdgeInsets.symmetric(
            vertical: textVerticalPadding.csh, horizontal: 20.csw),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.r),
        ),
        onPressed: isDisabled ? null : () {
          if (!isLoading) {
            onTap?.call();
          }
        },
        child: isLoading
            ? SizedBox(
                width: 30.w,
                height: 30.w,
                child: Loading(
                    strokeWidth: 2.w, color: Colors.white))
            : Text(
                title,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
