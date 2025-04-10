import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Snack extends SnackBar {
  static show(BuildContext context, String content, bool succeed) {
    return ScaffoldMessenger.of(context).showSnackBar(
      Snack(
        context: context,
        content: content,
        succeed: succeed,
      ),
    );
  }

  Snack({
    Key? key,
    required BuildContext context,
    required String content,
    required bool succeed,
  }) : super(
          key: key,
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.horizontal,
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(16),
          backgroundColor: succeed ? context.colors.success : context.colors.error,
          content: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  succeed ? Icons.done : Icons.close,
                  color: context.colors.secondaryTextColor.withOpacity(0.75),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: context.colors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
}
