import 'package:escola/core/components/fader.dart';
import 'package:escola/core/components/measure_size.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadMoreBySize extends StatefulWidget {
  const ReadMoreBySize({
    super.key,
    required this.builder,
    this.customReadMoreBuilder,
  });

  final Widget Function(bool more) builder;
  final Widget Function(bool more)? customReadMoreBuilder;

  @override
  State<ReadMoreBySize> createState() => _ReadMoreBySizeState();
}

class _ReadMoreBySizeState extends State<ReadMoreBySize> {
  late final ValueNotifier<bool> readMoreController;
  late final ValueNotifier<bool> showReadMoreController;

  @override
  void initState() {
    super.initState();
    readMoreController = ValueNotifier(false);
    showReadMoreController = ValueNotifier(false);
  }

  @override
  void dispose() {
    readMoreController.dispose();
    showReadMoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: showReadMoreController,
      builder: (context, showReadMore, child) => ValueListenableBuilder(
        valueListenable: readMoreController,
        builder: (context, more, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MeasureSize(
              onChange: (size) => showReadMoreController.value = size.height >= 100,
              child: more
                  ? widget.builder(more)
                  : Fader(
                      height: 200,
                      child: widget.builder(more),
                    ),
            ),
            if (showReadMore)
              GestureDetector(
                onTap: () => readMoreController.value = !readMoreController.value,
                child: widget.customReadMoreBuilder?.call(more) ?? defaultReadMore(more, context),
              ),
          ],
        ),
      ),
    );
  }

  Widget defaultReadMore(bool value, BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0.csh),
        child: Text(
          value ? LocalizationKeys.read_less.tr(context) : LocalizationKeys.read_more.tr(context),
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w300,
            decoration: TextDecoration.underline,
            color: context.colors.secondary,
            decorationColor: context.colors.secondary,
          ),
        ),
      );
}
