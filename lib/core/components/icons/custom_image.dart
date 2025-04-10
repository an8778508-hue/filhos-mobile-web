import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';

import 'common_image.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double height;
  final double width;
  final Color? color;

  const CustomImage({
    Key? key,
    required this.image,
    required this.height,
    required this.width,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.csw,
      height: width.csh,
      child: CommonImage(
        imageUrl: image,
        width: width.csw,
        height: width.csh,
        color: color,
      ),
    );
  }
}
