import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/dropdown_question_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/localization/localization_keys.dart';

class SelectQuestionWidget extends StatelessWidget {
  final SelectQuestion question;
  final QuestionCategory? questionCategory;
  final bool isRating;

  const SelectQuestionWidget({super.key, required this.question, required this.questionCategory, this.isRating = false});

  @override
  Widget build(BuildContext context) {
    if(isRating) {
      final int? ratingValue = getRatingValue();
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
                getSubtitle(context, ratingValue ?? 0),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w300, color: Colors.black54),
              ),
            ],
          ),
          if (ratingValue != null) ...[
            Row(
              children: List.generate(
                3,
                    (index) => Icon(
                  Icons.star_rate,
                  color: index <= (ratingValue - 1) ? Color(0xffFFBB00) : Colors.grey,
                  size: 40.w,
                ),
              ),
            ),
          ]
        ],
      ),
    );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, ),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            (question.title ?? ""),
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  questionCategory?.answer?.map((e) => e).join(",").replaceAll(RegExp(r'[\[\]"]'), '') ?? "",
                  // item.value ?? "",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w400, color: Colors.black),
                ),
              ),
              getDynamicQuestionValue(icon_value: questionCategory?.icon_value, context: context, isAnswer: false),
            ],
          ).addPadding(padding: EdgeInsets.symmetric(horizontal: 5.w)),
          SizedBox(height: 16.h),
          Container(
            color: context.colors.scaffold,
            height: 1.h,
          ),
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

  int? getRatingValue() {
    if (questionCategory?.answer == null) return null;

    for (var item in questionCategory!.answer!) {
      final match = RegExp(r'\[.+:(\d+)\]').firstMatch(item.toString());
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    return null;
  }
}
