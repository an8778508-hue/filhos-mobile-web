import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventSmallImages extends StatelessWidget {
  final List<String> imagesUrls;
  final int numberOfPaidUsers;

  const EventSmallImages({
    super.key,
    required this.imagesUrls,
    required this.numberOfPaidUsers,
  });

  @override
  Widget build(BuildContext context) {
    print('numberOfPaidUsers 2 $numberOfPaidUsers');
    return SizedBox(
      height: 30.h,
      child: Stack(
        children: [
          if (imagesUrls.length > 5)
            Positioned(
              left: 125.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[5],
              ),
            ),
          if (imagesUrls.length > 4)
            Positioned(
              left: 100.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[4],
              ),
            ),
          if (imagesUrls.length > 3)
            Positioned(
              left: 75.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[3],
              ),
            ),
          if (imagesUrls.length > 2)
            Positioned(
              left: 50.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[2],
              ),
            ),
          if (imagesUrls.length > 1)
            Positioned(
              left: 25.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[1],
              ),
            ),
          if (imagesUrls.isNotEmpty)
            Positioned(
              left: 0.w,
              child: SmallProfileImage(
                imageUrl: imagesUrls[0],
              ),
            ),
          if (numberOfPaidUsers > 6)
            Positioned(
              left: (160.w),
              bottom: 5.w,
              top: 5.w,
              child: Text(
                '${numberOfPaidUsers - 6}+',
                style: TextStyle(
                  color: context.colors.primaryLight,
                  fontSize: 14.sp,
                ),
              ),
            )
        ],
      ),
    );
  }
}

class SmallProfileImage extends StatelessWidget {
  final String imageUrl;
  const SmallProfileImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: context.colors.background,
      radius: 15.w,
      child: CircleAvatar(
        backgroundColor: context.colors.background,
        radius: 13.w,
        backgroundImage: NetworkImage(imageUrl),
      ),
    );
  }
}
