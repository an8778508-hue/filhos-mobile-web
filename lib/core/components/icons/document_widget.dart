import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DocumentWidget extends StatelessWidget {
  final String url;
  const DocumentWidget({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final fileExtension = url.split('.').last;
    if (url.length > 30) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
        color: Colors.grey[300],
        child: Center(
          child: Text(
            "${url.substring(0, 20)}...$fileExtension",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      color: Colors.grey[300],
      child: Center(
        child: Text(
          url,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp),
        ),
      ),
    );
  }
}
