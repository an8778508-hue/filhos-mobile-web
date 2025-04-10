import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingMenuItem extends StatelessWidget {
  final int index;
  final QuestionTemplate question;

  const RatingMenuItem(
      {super.key, required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          getRatingText(context, index),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        RatingBar.builder(
          initialRating: getRatingCount(index),
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemSize: 50.w,
          itemCount: 3,
          unratedColor: const Color(0xffdedede),
          itemPadding: EdgeInsets.symmetric(horizontal: 1.w),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          ignoreGestures: true,
          onRatingUpdate: (rating) {},
        ),
      ],
    );
  }

  static double getRatingCount(int index) {
    switch (index) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  String getRatingText(context, int index) {
    switch (index) {
      case 0:
        return LocalizationKeys.very_bad.tr(context);
      case 1:
        return LocalizationKeys.bad.tr(context);
      case 2:
        return LocalizationKeys.normal.tr(context);
      case 3:
        return LocalizationKeys.good.tr(context);
      case 4:
        return LocalizationKeys.very_good.tr(context);
      default:
        return "";
    }
  }
}
