import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoQuestionWidget extends StatelessWidget {
  final InfoQuestion question;
  final QuestionCategory? questionCategory;

  const InfoQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              if(questionCategory?.answer != null)
                Text(
                  questionCategory?.answer?.map((e) => e).join(",") ?? "",
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              SizedBox(width: 10.w),
            ],
          ),
        ],
      ),
    );
  }
}
