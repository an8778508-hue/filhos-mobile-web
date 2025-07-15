import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/components/icons/common_image.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  // final VoidCallback onFacebookLogin;
  final VoidCallback onAppleLogin;
  final String googleButtonImage;
  final String facebookButtonImage;
  final String appleButtonImage;
  const SocialLoginButtons({
    super.key,
    required this.onGoogleLogin,
    // required this.onFacebookLogin,
    required this.onAppleLogin,
    required this.googleButtonImage,
    required this.facebookButtonImage,
    required this.appleButtonImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "or login with",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onGoogleLogin,
              child: CommonImage(
                imageUrl: googleButtonImage,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.contain,
              ),
            ),
            // SizedBox(width: 30.w),
            // InkWell(
            //   onTap: onFacebookLogin,
            //   child: CommonImage(
            //     imageUrl: facebookButtonImage,
            //     width: 40.w,
            //     height: 40.h,
            //     fit: BoxFit.contain,
            //   ),
            // ),
            if(Platform.isIOS)
            SizedBox(width: 30.w),
            if(Platform.isIOS)
            InkWell(
              onTap: onAppleLogin,
              child: CommonImage(
                imageUrl: appleButtonImage,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ],
    );
  }
}