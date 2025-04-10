import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Avatar extends StatelessWidget {
  final String? avatar, defaultAvatar;
  final double? size;
  final bool isChild, ignoreGesutre;
  final Color? backgroundColor;

  const Avatar({
    super.key,
    required this.avatar,
    this.size,
    this.isChild = false,
    this.defaultAvatar,
    this.ignoreGesutre = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: ignoreGesutre,
      child: GestureDetector(
        onTap: () {
          if (validString(avatar)) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => PhotoViewer(url: avatar!, tag: avatar!)));
          }
        },
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.scaffold),
          child: ClipOval(
            child: CommonImage(
              imageUrl: stringNotNullOrEmpty(avatar) ? avatar : defaultAvatar,
              fit: BoxFit.cover,
              fallBackImagePath:
                  defaultAvatar ?? (!isChild ? Assets.icons.defaultAvatar.path : Assets.images.childProfileSvg.path),
              size: size ?? 70.w,
            ),
          ),
        ),
      ),
    );
  }
}
