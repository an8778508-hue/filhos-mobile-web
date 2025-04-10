import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/rating_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingQuestionWidget extends StatelessWidget {
  final RatingQuestion question;
  final QuestionCategory? questionCategory;
  const RatingQuestionWidget({
    super.key,
    required this.question,
   required this.questionCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      decoration: BoxDecoration(color: context.colors.lightBackground),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.title ?? "",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              Text(
                getSubtitle(context, question.rating ?? 0),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w300, color: Colors.black54),
              ),
            ],
          ),
          if (question.rating != null) ...[
            Row(
              children: List.generate(
                3,
                (index) => Icon(
                  Icons.star_rate,
                  color: index <= (question.rating! - 1) ? Color(0xffFFBB00) : Colors.grey,
                  size: 40.w,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  String getSubtitle(BuildContext context, int rating) {
    switch (rating) {
      case 0:
        return LocalizationKeys.bad.tr(context);
      case 1:
        return LocalizationKeys.good.tr(context);
      case 2:
        return LocalizationKeys.very_good.tr(context);
      case 3:
        return LocalizationKeys.very_good.tr(context);
      default:
        return "";
    }
  }
}
