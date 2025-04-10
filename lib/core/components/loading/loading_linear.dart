import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingLinear extends StatelessWidget {
  const LoadingLinear({
    Key? key,
    this.color,
    this.size,
  }) : super(key: key);

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
