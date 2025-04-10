import 'package:flutter/material.dart';

class Fader extends StatelessWidget {
  const Fader({
    Key? key,
    required this.child,
    required this.height,
    this.cut = false,
  }) : super(key: key);

  final Widget child;
  final double height;
  final bool cut;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => LinearGradient(
        colors: <Color>[
          Colors.white,
          if (!cut) Colors.white30,
          Colors.transparent,
        ],
        stops: cut
            ? [
                0.9999999999999999999999999999999999999999999,
                1.0,
              ]
            : null,
        tileMode: TileMode.mirror,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: height,
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: child,
        ),
      ),
    );
  }
}
