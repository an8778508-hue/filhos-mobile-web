import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool?> confirmDialog({
  required BuildContext context,
  required String titleKey,
  required String bodyKey,
  String? cancelKey,
  String? confirmKey,
}) async {
  return await showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      content: Column(
        children: [
          Text(
            titleKey.tr(context),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bodyKey.tr(context),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          textStyle: TextStyle(color: context.colors.textColor),
          child: Text(
            (cancelKey??LocalizationKeys.cancel).tr(context),
          ),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          child: Text(
            (confirmKey??LocalizationKeys.confirm).tr(context),
          ),
        ),
      ],
    ),
  );
}
