import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:flutter/material.dart';

import 'common_image.dart';

class AppLogoIcon extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;

  const AppLogoIcon({
    super.key,
    required this.height,
    required this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.csw,
      height: width.csh,
      child: CommonImage(
        imageUrl: assetsPath('filhos_logo'),
        width: width.csw,
        height: width.csh,
        fit: BoxFit.fitHeight,
        color: color,
      ),
    );
  }
}
