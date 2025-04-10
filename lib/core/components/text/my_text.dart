import 'package:flutter/material.dart';

class CustomSelectableText extends StatelessWidget {
  const CustomSelectableText(
    this.src, {
    Key? key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
  }) : super(key: key);

  final String src;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      src,
      scrollPhysics: NeverScrollableScrollPhysics(),
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      // overflow: overflow,
    );
  }
}
