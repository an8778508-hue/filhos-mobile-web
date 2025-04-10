import 'package:escola/core/attachment_selection/attachment_selection_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'attachment_src.dart';

Future<AttachmentSrc?> showAttachmentSelectionBottomSheet(BuildContext context,
    {bool imageAndVideoOption = false}) async {
  return await showModalBottomSheet(
    context: context,
    isDismissible: true,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
    ),
    builder: (context) => AttachmentSelectionBottomSheet(imageAndVideoOption: imageAndVideoOption),
  );
}
