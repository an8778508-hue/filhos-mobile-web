import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/components/icons/common_image.dart';
import '../../../../shared/assets/assets.gen.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final VoidCallback onFacebookLogin;
  final VoidCallback onAppleLogin;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleLogin,
    required this.onFacebookLogin,
    required this.onAppleLogin,
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
                imageUrl: Assets.icons.google.path,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 30.w),
            InkWell(
              onTap: onFacebookLogin,
              child: CommonImage(
                imageUrl: Assets.icons.facebook.path,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 30.w),
            InkWell(
              onTap: onAppleLogin,
              child: CommonImage(
                imageUrl: Assets.images.apple.path,
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