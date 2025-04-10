import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FileExtension extends StatelessWidget {
  final String ext;
  const FileExtension({super.key, required this.ext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.file_copy_outlined,
          color: context.colors.primary,
          size: 24.sp,
        ),
        Text(
          ext,
          style: TextStyle(
            color: context.colors.primaryLight,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
