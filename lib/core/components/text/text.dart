import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonBoldText extends StatelessWidget {
  final String value;
  final double? size;
  final double marginHeight;
  final double marginWidth;
  final TextAlign align;
  final FontWeight fontWeight;
  final Color textColor;
  final bool hasUnderline, hasDash;
  final int? maxLines;
  final TextOverflow? overflow;

  const CommonBoldText({
    Key? key,
    required this.value,
    this.size,
    this.maxLines,
    this.overflow,
    this.hasUnderline=false,
    this.hasDash = false,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.black,
    this.marginHeight = 0.0,
    this.marginWidth = 0.0,
    this.align = TextAlign.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: marginWidth.csw,
        vertical: marginHeight.csh,
      ),
      child: Text(
        value,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontWeight: fontWeight,
          fontSize: size ?? 15.sp,
          color: textColor,
          decoration: hasUnderline ? TextDecoration.underline:null,
          decorationStyle: hasDash ?TextDecorationStyle.dashed: null,
        ),
      ),
    );
  }
}

