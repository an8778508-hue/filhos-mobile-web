import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';

class LoadingLinear extends StatelessWidget {
  const LoadingLinear({
    super.key,
    this.color,
    this.size,
  });

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation(context.colors.primary),
        backgroundColor: context.colors.primary.withOpacity(0.4),
      ),
    );
  }
}
