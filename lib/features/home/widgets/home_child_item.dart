import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeChildItem extends StatelessWidget {
  final ChildModel child;

  const HomeChildItem({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => DiaryScreen(child: child)));
      },
      child: Container(
        margin: EdgeInsetsDirectional.only(start: 12.csw),
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(20.r),
        ),
        height: 278.csh,
        width: 192.csw,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
              start: 24.csw, end: 24.csw, top: 44.csh),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 116.csh,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 116.csh,
                      width: 116.csh,
                      child: Avatar(
                        ignoreGesutre: true,
                        avatar: child.avatar,
                        isChild: true,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: SvgPicture.asset(
                        'assets/icons/check.svg',
                        height: 33.csh,
                        width: 33.csh,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 21.csh,
              ),
              Text(
                child.name ?? '',
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textColor),
              ),
              if (child.classRoom != null) ...[
                SizedBox(height: 8.csh),
                Text(
                  child.classRoom!,
                  maxLines: 2,
                  style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: context.colors.textColor),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
