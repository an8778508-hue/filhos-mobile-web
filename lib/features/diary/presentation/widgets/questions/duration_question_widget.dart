import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/duration_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DurationQuestionWidget extends StatelessWidget {
  final DurationQuestion question;
  final QuestionCategory? questionCategory;
  const DurationQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    if (question.duration == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      decoration: BoxDecoration(color: context.colors.lightBackground),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            question.title ?? "",
            style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
          if (questionCategory?.answer != null) ...[
            // format duratoin as 00:00
            Text(
              questionCategory!.answer?.map((e) => e).join(",") ?? "",
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
          ]
        ],
      ),
    );
  }
}
