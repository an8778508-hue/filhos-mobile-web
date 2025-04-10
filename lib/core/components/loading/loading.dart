import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Loading extends StatelessWidget {
  const Loading({
    Key? key,
    this.color,
    this.size,
    this.strokeWidth = 4.0,
  }) : super(key: key);

  final Color? color;
  final double? size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 30.csh,
      height: size ?? 30.csh,
      child: CircularProgressIndicator(
        color: color ?? context.colors.primary,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class LoadingMore extends StatelessWidget {
  const LoadingMore({
    Key? key,
    this.color,
    this.size,
    this.strokeWidth,
  }) : super(key: key);

  final Color? color;
  final double? size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Loading(
            size: 15.w,
            strokeWidth: 2,
          ),
          SizedBox(width: 20.w),
          Text(
            LocalizationKeys.loading_more.tr(context),
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NoMore extends StatelessWidget {
  const NoMore({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      alignment: Alignment.center,
      child: Text(
        LocalizationKeys.no_more_data.tr(context),
        style: TextStyle(
          fontSize: 14.sp,
          color: context.colors.textColor,
        ),
      ),
    );
  }
}
