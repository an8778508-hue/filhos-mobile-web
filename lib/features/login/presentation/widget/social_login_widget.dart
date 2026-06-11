import 'dart:io';

import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/components/icons/common_image.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogleLogin;
  final VoidCallback onFacebookLogin;
  final VoidCallback onAppleLogin;
  final VoidCallback onToggleLoginMethod;
  final String googleButtonImage;
  final String facebookButtonImage;
  final String appleButtonImage;
  final String loginWithEmailImage;
  final String phoneButtonImage;
  final bool isEmail; // Add flag to track current mode
  final bool showToggle; // Whether to show the phone/email login-method toggle

  const SocialLoginButtons({
    super.key,
    required this.onGoogleLogin,
    required this.onFacebookLogin,
    required this.onAppleLogin,
    required this.googleButtonImage,
    required this.facebookButtonImage,
    required this.appleButtonImage,
    required this.onToggleLoginMethod,
    required this.loginWithEmailImage,
    required this.phoneButtonImage,
    required this.isEmail, // Default to false for social login
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ConfigSelector(
      selector: (config) => config.socialLogin,
      builder: (context, state) {
        if (!state.appleEnabled && !state.facebookEnabled && !state.googleEnabled) {
          return SizedBox.shrink();
        }
        return Column(
          children: [
            Text(
              LocalizationKeys.or_login_with.tr(context),
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
                if (state.googleEnabled)
                  InkWell(
                    onTap: onGoogleLogin,
                    child: CommonImage(
                      imageUrl: googleButtonImage,
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (state.googleEnabled && state.facebookEnabled) SizedBox(width: 30.w),
                if (state.facebookEnabled)
                  InkWell(
                    onTap: onFacebookLogin,
                    child: CommonImage(
                      imageUrl: facebookButtonImage,
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (!kIsWeb && Platform.isIOS && state.appleEnabled) SizedBox(width: 30.w),
                if (!kIsWeb && Platform.isIOS && state.appleEnabled)
                  InkWell(
                    onTap: onAppleLogin,
                    child: CommonImage(
                      imageUrl: appleButtonImage,
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                SizedBox(width: 30.w),
                InkWell(
                  onTap: onToggleLoginMethod,
                  child: CommonImage(
                    imageUrl: isEmail ? loginWithEmailImage : phoneButtonImage,
                    width: 40.w,
                    height: 40.h,
                    color: context.colors.primary,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
