import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendButton extends StatelessWidget {
  final Function() onPressed;
  const SendButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => onPressed(),
        child: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.primary,
          ),
          child: Center(
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: 25.w,
            ),
          ),
        ));
  }
}
