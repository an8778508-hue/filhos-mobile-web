import 'package:flutter/material.dart';

import 'image_filter_gen.dart';

class ImageFilter extends StatelessWidget {
  const ImageFilter({
    Key? key,
    required this.child,
    this.brightness = 0.0,
    this.saturation = 0.0,
    this.hue = 0.0,
  }) : super(key: key);

  final Widget child;
  final double brightness;
  final double saturation;
  final double hue;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(
        ColorFilterGenerator.brightnessAdjustMatrix(
          value: brightness,
        ),
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorFilterGenerator.saturationAdjustMatrix(
            value: saturation,
          ),
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(
            ColorFilterGenerator.hueAdjustMatrix(
              value: hue,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
